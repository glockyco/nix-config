"""Minimal Fastmail JMAP client for scripted and agent use.

Reads a Fastmail API token from a file and speaks JMAP (RFC 8620/8621)
directly. Output is JSON on stdout so callers can pipe it into `jq`.

The token this is built around is scoped read-only to Email, so no mutating
operation is implemented here; adding one would silently fail against such a
token anyway.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request

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


def request(url: str, token: str, payload: object | None = None) -> dict:
    data = None if payload is None else json.dumps(payload).encode()
    req = urllib.request.Request(url, data=data)
    req.add_header("Authorization", f"Bearer {token}")
    if data is not None:
        req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
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

    args = parser.parse_args()
    handlers = {"mailboxes": cmd_mailboxes, "search": cmd_search, "read": cmd_read}

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
