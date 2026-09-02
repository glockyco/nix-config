"""Minimal Fastmail JMAP client for scripted and agent use.

Reads a Fastmail API token from a file and speaks JMAP (RFC 8620/8621)
directly. Output is JSON on stdout so callers can pipe it into `jq`.

The token this is built around is scoped read-only to Email, so no mutating
operation is implemented here; adding one would silently fail against such a
token anyway.
"""

import argparse
import datetime
import gzip
import io
import json
import os
import socket
import sys
import urllib.error
import urllib.parse
import urllib.request
import zipfile
import xml.etree.ElementTree as ET
import zlib

SESSION_URL = "https://api.fastmail.com/jmap/session"
CORE = "urn:ietf:params:jmap:core"
MAIL = "urn:ietf:params:jmap:mail"


class JmapError(Exception):
    pass


def read_token(path: str) -> str:
    try:
        with open(path, encoding="utf-8") as fh:
            token = fh.read().strip()
    except OSError as exc:
        raise JmapError(f"cannot read token from {path}: {exc}") from exc
    if not token:
        raise JmapError(f"token file {path} is empty")
    return token


def request(
    url: str, token: str, payload: object | None = None, *, raw: bool = False
) -> dict | bytes:
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data)
    req.add_header("Authorization", f"Bearer {token}")
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            if raw:
                return resp.read()
            return json.load(resp)
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")[:400]
        raise JmapError(f"HTTP {exc.code} from {url}: {detail}") from exc
    except urllib.error.URLError as exc:
        raise JmapError(f"cannot reach {url}: {exc.reason}") from exc


class Session:
    def __init__(self, token: str):
        self.token = token
        s = request(SESSION_URL, token)
        try:
            self.api_url = s["apiUrl"]
            self.account = s["primaryAccounts"][MAIL]
        except KeyError as exc:
            raise JmapError(
                "session lacks mail access; the token needs the Email scope"
            ) from exc
        self.download_url = s.get("downloadUrl")

    def call(self, calls: list) -> list:
        body = {"using": [CORE, MAIL], "methodCalls": calls}
        resp = request(self.api_url, self.token, body)
        responses = resp.get("methodResponses", [])
        for name, args, _ in responses:
            if name == "error":
                raise JmapError(f"JMAP error: {args.get('type', args)}")
        return responses


def cmd_mailboxes(session: Session, _args) -> object:
    ((_, res, _),) = session.call(
        [
            [
                "Mailbox/get",
                {
                    "accountId": session.account,
                    "ids": None,
                    "properties": ["name", "role", "totalEmails", "unreadEmails"],
                },
                "m",
            ]
        ]
    )
    return sorted(res["list"], key=lambda m: m["name"])


def _envelopes(session: Session, filt: dict, limit: int) -> object:
    responses = session.call(
        [
            [
                "Email/query",
                {
                    "accountId": session.account,
                    "filter": filt,
                    "sort": [{"property": "receivedAt", "isAscending": False}],
                    "limit": limit,
                },
                "q",
            ],
            [
                "Email/get",
                {
                    "accountId": session.account,
                    "#ids": {"resultOf": "q", "name": "Email/query", "path": "/ids"},
                    "properties": [
                        "id",
                        "receivedAt",
                        "from",
                        "to",
                        "subject",
                        "preview",
                        "keywords",
                    ],
                },
                "g",
            ],
        ]
    )
    return responses[1][1]["list"]


def cmd_search(session: Session, args) -> object:
    filt: dict = {}
    if args.query:
        filt["text"] = " ".join(args.query)
    if args.mailbox:
        ((_, res, _),) = session.call(
            [
                [
                    "Mailbox/get",
                    {
                        "accountId": session.account,
                        "ids": None,
                        "properties": ["name", "role"],
                    },
                    "m",
                ]
            ]
        )
        wanted = args.mailbox.lower()
        match = [
            m
            for m in res["list"]
            if m["name"].lower() == wanted or (m.get("role") or "") == wanted
        ]
        if not match:
            raise JmapError(f"no mailbox named or roled {args.mailbox!r}")
        filt["inMailbox"] = match[0]["id"]
    if args.unread:
        filt["notKeyword"] = "$seen"
    return _envelopes(session, filt, args.limit)


def cmd_read(session: Session, args) -> object:
    ((_, res, _),) = session.call(
        [
            [
                "Email/get",
                {
                    "accountId": session.account,
                    "ids": [args.id],
                    "properties": [
                        "id",
                        "receivedAt",
                        "from",
                        "to",
                        "cc",
                        "subject",
                        "bodyValues",
                        "textBody",
                    ],
                    "fetchTextBodyValues": True,
                },
                "g",
            ]
        ]
    )
    if not res["list"]:
        raise JmapError(f"no message with id {args.id!r}")
    msg = res["list"][0]
    body = "\n".join(
        msg.get("bodyValues", {}).get(part["partId"], {}).get("value", "")
        for part in msg.get("textBody", [])
        if part.get("partId")
    )
    return {
        "id": msg["id"],
        "receivedAt": msg.get("receivedAt"),
        "from": msg.get("from"),
        "to": msg.get("to"),
        "cc": msg.get("cc"),
        "subject": msg.get("subject"),
        "body": body,
    }


def _local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def _required_child(element: ET.Element, name: str, context: str) -> ET.Element:
    for child in element:
        if _local_name(child.tag) == name:
            return child
    raise JmapError(f"malformed DMARC report: missing {context}")


def _required_text(element: ET.Element, name: str, context: str) -> str:
    child = _required_child(element, name, context)
    value = (child.text or "").strip()
    if not value:
        raise JmapError(f"malformed DMARC report: empty {context}")
    return value


def _utc_timestamp(value: str, context: str) -> str:
    try:
        stamp = datetime.datetime.fromtimestamp(int(value), tz=datetime.timezone.utc)
    except (OSError, OverflowError, ValueError) as exc:
        raise JmapError(f"malformed DMARC report: invalid {context} {value!r}") from exc
    return stamp.isoformat(timespec="seconds").replace("+00:00", "Z")


def _looks_like_xml(data: bytes) -> bool:
    return data.lstrip(b"\xef\xbb\xbf \t\r\n").startswith(b"<")


def _report_documents(data: bytes, label: str) -> list[tuple[str, bytes]]:
    if data.startswith((b"PK\x03\x04", b"PK\x05\x06", b"PK\x07\x08")):
        try:
            with zipfile.ZipFile(io.BytesIO(data)) as archive:
                documents = []
                for member in archive.infolist():
                    if member.is_dir():
                        continue
                    content = archive.read(member)
                    if _looks_like_xml(content):
                        documents.append((f"{label} ({member.filename})", content))
                return documents
        except (OSError, zipfile.BadZipFile, RuntimeError, zlib.error) as exc:
            raise JmapError(f"cannot read DMARC ZIP attachment {label}: {exc}") from exc
    if data.startswith(b"\x1f\x8b"):
        try:
            document = gzip.decompress(data)
        except (OSError, EOFError, zlib.error) as exc:
            raise JmapError(
                f"cannot decompress DMARC gzip attachment {label}: {exc}"
            ) from exc
        return [(label, document)] if _looks_like_xml(document) else []
    if _looks_like_xml(data):
        return [(label, data)]
    return []


def _resolve_host(source_ip: str) -> str | None:
    previous = socket.getdefaulttimeout()
    try:
        socket.setdefaulttimeout(2.0)
        return socket.gethostbyaddr(source_ip)[0]
    except (OSError, ValueError):
        return None
    finally:
        socket.setdefaulttimeout(previous)


def _auth_results(element: ET.Element) -> dict[str, list[dict[str, str]]]:
    result: dict[str, list[dict[str, str]]] = {}
    for method in element:
        detail: dict[str, str] = {}
        for field in method:
            detail[_local_name(field.tag)] = (field.text or "").strip()
        result.setdefault(_local_name(method.tag), []).append(detail)
    return result


def _parse_report(
    data: bytes, label: str, resolve: bool, failures_only: bool
) -> dict | None:
    try:
        root = ET.fromstring(data)
    except ET.ParseError as exc:
        raise JmapError(f"cannot parse DMARC XML attachment {label}: {exc}") from exc
    if _local_name(root.tag) != "feedback":
        return None

    metadata = _required_child(root, "report_metadata", "report_metadata")
    date_range = _required_child(metadata, "date_range", "report date range")
    policy = _required_child(root, "policy_published", "policy_published")
    records = []
    for record_element in root:
        if _local_name(record_element.tag) != "record":
            continue
        row = _required_child(record_element, "row", "record row")
        policy_evaluated = _required_child(
            row, "policy_evaluated", "record policy_evaluated"
        )
        auth = _required_child(record_element, "auth_results", "record auth_results")
        source_ip = _required_text(row, "source_ip", "record source_ip")
        count_text = _required_text(row, "count", "record count")
        try:
            count = int(count_text)
        except ValueError as exc:
            raise JmapError(
                f"malformed DMARC report: invalid record count {count_text!r}"
            ) from exc
        dkim = _required_text(
            policy_evaluated, "dkim", "record policy_evaluated dkim"
        ).lower()
        spf = _required_text(
            policy_evaluated, "spf", "record policy_evaluated spf"
        ).lower()
        record = {
            "source_ip": source_ip,
            "count": count,
            "disposition": _required_text(
                policy_evaluated, "disposition", "record disposition"
            ).lower(),
            "policy_evaluated": {"dkim": dkim, "spf": spf},
            "auth_results": _auth_results(auth),
            "passes": dkim == "pass" or spf == "pass",
        }
        if resolve:
            record["source_host"] = _resolve_host(source_ip)
        if not failures_only or not record["passes"]:
            records.append(record)

    # With --failures-only the command answers exactly one question: is anything
    # still unexplained before the policy ladder advances? A report whose records
    # all passed is not part of that answer, so drop the whole report rather than
    # return an empty shell. That makes `[]` mean "nothing to look at".
    if failures_only and not records:
        return None

    policy_published = {
        _local_name(tag.tag): (tag.text or "").strip() for tag in policy
    }
    return {
        "org_name": _required_text(metadata, "org_name", "report org_name"),
        "report_id": _required_text(metadata, "report_id", "report report_id"),
        "begin": _utc_timestamp(
            _required_text(date_range, "begin", "report begin"), "report begin"
        ),
        "end": _utc_timestamp(
            _required_text(date_range, "end", "report end"), "report end"
        ),
        "policy_published": policy_published,
        "records": records,
    }


def _download_attachment(session: Session, attachment: dict) -> tuple[str, bytes]:
    if not session.download_url:
        raise JmapError("session lacks downloadUrl needed for DMARC attachments")
    missing = [
        field for field in ("blobId", "name", "type", "size") if field not in attachment
    ]
    if missing:
        raise JmapError(
            "DMARC attachment lacks required field(s): " + ", ".join(missing)
        )
    values = {
        field: urllib.parse.quote(str(attachment[field]), safe="")
        for field in ("blobId", "type", "name")
    }
    values["accountId"] = urllib.parse.quote(session.account, safe="")
    url = session.download_url
    for field, value in values.items():
        url = url.replace("{" + field + "}", value)
    content = request(url, session.token, raw=True)
    if not isinstance(content, bytes):
        raise JmapError(
            f"download of DMARC attachment {attachment['name']!r} was not binary"
        )
    return str(attachment["name"]), content


def cmd_dmarc(session: Session, args) -> object:
    responses = session.call(
        [
            [
                "Email/query",
                {
                    "accountId": session.account,
                    "filter": {
                        "operator": "AND",
                        "conditions": [
                            {"hasAttachment": True},
                            {"subject": "Report domain"},
                        ],
                    },
                    "sort": [{"property": "receivedAt", "isAscending": False}],
                    "limit": args.limit,
                },
                "q",
            ],
            [
                "Email/get",
                {
                    "accountId": session.account,
                    "#ids": {
                        "resultOf": "q",
                        "name": "Email/query",
                        "path": "/ids",
                    },
                    "properties": ["id", "attachments"],
                },
                "g",
            ],
        ]
    )
    messages = responses[1][1].get("list", [])
    reports = []
    for message in messages:
        for attachment in message.get("attachments") or []:
            name, content = _download_attachment(session, attachment)
            for label, document in _report_documents(content, name):
                report = _parse_report(
                    document, label, not args.no_resolve, args.failures_only
                )
                if report is not None:
                    reports.append(report)
    return reports


def main() -> int:
    default_token = os.environ.get("FASTMAIL_TOKEN_FILE", "")
    parser = argparse.ArgumentParser(
        prog="fastmail", description="Query Fastmail over JMAP. Output is JSON."
    )
    parser.add_argument(
        "--token-file",
        default=default_token,
        help="file holding the API token (default: $FASTMAIL_TOKEN_FILE)",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("mailboxes", help="list mailboxes with message counts")

    p_search = sub.add_parser("search", help="search messages, newest first")
    p_search.add_argument("query", nargs="*", help="free text to match")
    p_search.add_argument("--mailbox", help="restrict to a mailbox name or role")
    p_search.add_argument(
        "--unread", action="store_true", help="only messages without the $seen keyword"
    )
    p_search.add_argument("--limit", type=int, default=20)

    p_read = sub.add_parser("read", help="fetch one message including its text body")
    p_read.add_argument("id", help="message id, as returned by search")

    p_dmarc = sub.add_parser("dmarc", help="decode DMARC aggregate reports")
    p_dmarc.add_argument("--limit", type=int, default=20)
    p_dmarc.add_argument(
        "--no-resolve", action="store_true", help="do not perform reverse DNS lookups"
    )
    p_dmarc.add_argument(
        "--failures-only", action="store_true", help="only include failing records"
    )

    args = parser.parse_args()
    handlers = {
        "mailboxes": cmd_mailboxes,
        "search": cmd_search,
        "read": cmd_read,
        "dmarc": cmd_dmarc,
    }

    try:
        if not args.token_file:
            raise JmapError(
                "no token file; pass --token-file or set FASTMAIL_TOKEN_FILE"
            )
        session = Session(read_token(args.token_file))
        json.dump(handlers[args.command](session, args), sys.stdout, indent=2)
        sys.stdout.write("\n")
    except JmapError as exc:
        print(f"fastmail: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        return 130
    return 0


if __name__ == "__main__":
    sys.exit(main())
