import contextlib
import gzip
import io
import json
import tempfile
import unittest
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

import fastmail


REPORT = b"""\
<feedback xmlns="urn:ietf:params:xml:ns:feedback-1.0">
  <report_metadata>
    <org_name>Example Reporter</org_name>
    <report_id>report-42</report_id>
    <date_range><begin>0</begin><end>86400</end></date_range>
  </report_metadata>
  <policy_published>
    <domain>example.org</domain><adkim>r</adkim><aspf>s</aspf><p>reject</p>
  </policy_published>
  <record>
    <row>
      <source_ip>192.0.2.1</source_ip><count>4</count>
      <policy_evaluated>
        <disposition>none</disposition><dkim>pass</dkim><spf>fail</spf>
      </policy_evaluated>
    </row>
    <auth_results><dkim><domain>example.org</domain><result>pass</result></dkim></auth_results>
  </record>
  <record>
    <row>
      <source_ip>192.0.2.2</source_ip><count>3</count>
      <policy_evaluated>
        <disposition>reject</disposition><dkim>fail</dkim><spf>fail</spf>
      </policy_evaluated>
    </row>
    <auth_results><spf><domain>example.org</domain><result>fail</result></spf></auth_results>
  </record>
</feedback>
"""


class SessionDouble:
    account = "account"
    token = "secret"
    download_url = "https://download.test/{accountId}/{blobId}/{name}/{type}"

    def __init__(self):
        self.calls = []

    def call(self, calls):
        self.calls.append(calls)
        return [
            ["Email/query", {"ids": ["message"]}, "q"],
            [
                "Email/get",
                {
                    "list": [
                        {
                            "id": "message",
                            "attachments": [
                                {
                                    "blobId": "blob",
                                    "name": "report.xml",
                                    "type": "application/xml",
                                    "size": 123,
                                }
                            ],
                        }
                    ]
                },
                "g",
            ],
        ]


class FastmailReportTests(unittest.TestCase):
    def reports(self, content, *, failures_only=False, resolve=False):
        session = SessionDouble()
        args = SimpleNamespace(
            limit=7, no_resolve=not resolve, failures_only=failures_only
        )
        with mock.patch.object(fastmail, "request", return_value=content) as fetch:
            reports = fastmail.cmd_dmarc(session, args)
        self.assertEqual(len(session.calls), 1)
        query, get = session.calls[0]
        self.assertEqual(query[0], "Email/query")
        self.assertEqual(query[1]["limit"], 7)
        self.assertEqual(get[0], "Email/get")
        self.assertEqual(get[1]["#ids"]["resultOf"], "q")
        fetch.assert_called_once_with(
            "https://download.test/account/blob/report.xml/application%2Fxml",
            "secret",
            raw=True,
        )
        return reports

    def test_xml_content_and_failure_filter(self):
        with mock.patch.object(
            fastmail, "_resolve_host", return_value="sender.example"
        ) as resolve:
            reports = self.reports(REPORT, resolve=True)
        self.assertEqual(
            resolve.call_args_list, [mock.call("192.0.2.1"), mock.call("192.0.2.2")]
        )
        self.assertEqual(len(reports), 1)
        report = reports[0]
        self.assertEqual(
            (report["org_name"], report["report_id"], report["begin"], report["end"]),
            (
                "Example Reporter",
                "report-42",
                "1970-01-01T00:00:00Z",
                "1970-01-02T00:00:00Z",
            ),
        )
        self.assertEqual(
            report["policy_published"],
            {"domain": "example.org", "adkim": "r", "aspf": "s", "p": "reject"},
        )
        self.assertEqual(
            report["records"],
            [
                {
                    "source_ip": "192.0.2.1",
                    "count": 4,
                    "disposition": "none",
                    "policy_evaluated": {"dkim": "pass", "spf": "fail"},
                    "auth_results": {
                        "dkim": [{"domain": "example.org", "result": "pass"}]
                    },
                    "passes": True,
                    "source_host": "sender.example",
                },
                {
                    "source_ip": "192.0.2.2",
                    "count": 3,
                    "disposition": "reject",
                    "policy_evaluated": {"dkim": "fail", "spf": "fail"},
                    "auth_results": {
                        "spf": [{"domain": "example.org", "result": "fail"}]
                    },
                    "passes": False,
                    "source_host": "sender.example",
                },
            ],
        )
        failures = self.reports(REPORT, failures_only=True)
        self.assertEqual(
            failures[0]["records"],
            [
                {
                    key: value
                    for key, value in report["records"][1].items()
                    if key != "source_host"
                }
            ],
        )
        root = ET.fromstring(REPORT)
        root.remove(root.findall("{*}record")[1])
        self.assertEqual(self.reports(ET.tostring(root), failures_only=True), [])

    def test_gzip_report_and_non_xml_payload(self):
        self.assertEqual(
            self.reports(gzip.compress(REPORT))[0]["report_id"], "report-42"
        )
        self.assertEqual(self.reports(gzip.compress(b"not xml")), [])

    def test_zip_reports_skip_non_xml_and_non_feedback_members(self):
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, "w") as archive:
            archive.writestr("report.xml", REPORT)
            archive.writestr("not-report.xml", b"<message>not a report</message>")
            archive.writestr("note.txt", b"not XML")
        self.assertEqual(
            [r["report_id"] for r in self.reports(stream.getvalue())], ["report-42"]
        )

    def test_plain_non_feedback_and_non_xml_are_ignored(self):
        self.assertEqual(self.reports(b"<message>not a report</message>"), [])
        self.assertEqual(self.reports(b"not an XML document"), [])

    def test_malformed_xml_and_missing_fields_fail(self):
        with self.assertRaisesRegex(
            fastmail.JmapError, "cannot parse DMARC XML attachment report.xml"
        ):
            self.reports(b"<feedback><report_metadata>")
        with self.assertRaisesRegex(
            fastmail.JmapError, "malformed DMARC report: missing report_metadata"
        ):
            self.reports(b"<feedback/>")

    def test_command_output_and_failures_only(self):
        with tempfile.TemporaryDirectory() as directory:
            token_file = Path(directory, "token")
            token_file.write_text(" secret\n", encoding="utf-8")
            for extra, expected_counts in [((), [4, 3]), (("--failures-only",), [3])]:
                session = SessionDouble()
                stdout, stderr = io.StringIO(), io.StringIO()
                with (
                    mock.patch.object(
                        fastmail, "Session", return_value=session
                    ) as create_session,
                    mock.patch.object(fastmail, "request", return_value=REPORT),
                    mock.patch.object(
                        fastmail,
                        "_resolve_host",
                        side_effect=AssertionError("unexpected lookup"),
                    ),
                    contextlib.redirect_stdout(stdout),
                    contextlib.redirect_stderr(stderr),
                ):
                    status = fastmail.main(
                        [
                            "--token-file",
                            str(token_file),
                            "dmarc",
                            "--no-resolve",
                            *extra,
                        ]
                    )
                self.assertEqual(status, 0)
                self.assertEqual(stderr.getvalue(), "")
                create_session.assert_called_once_with("secret")
                self.assertEqual(
                    [
                        record["count"]
                        for report in json.loads(stdout.getvalue())
                        for record in report["records"]
                    ],
                    expected_counts,
                )


class CredentialTests(unittest.TestCase):
    def test_default_private_credential_path_and_missing_error(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory, ".config/credentials/fastmail-token")
            stderr = io.StringIO()
            with (
                mock.patch.dict(fastmail.os.environ, {"HOME": directory}, clear=True),
                mock.patch.object(fastmail, "Session") as session,
                contextlib.redirect_stderr(stderr),
            ):
                self.assertEqual(fastmail.main(["mailboxes"]), 1)
            session.assert_not_called()
            self.assertIn(f"cannot read token from {path}:", stderr.getvalue())

    def test_default_and_override_read_locally_without_logging_token(self):
        with tempfile.TemporaryDirectory() as directory:
            default = Path(directory, ".config/credentials/fastmail-token")
            default.parent.mkdir(parents=True)
            default.write_text("fixture-credential\n")
            override = Path(directory, "override")
            override.write_text("fixture-override\n")
            for extra, expected in (
                ({}, "fixture-credential"),
                ({"FASTMAIL_TOKEN_FILE": str(override)}, "fixture-override"),
            ):
                stdout, stderr = io.StringIO(), io.StringIO()
                with (
                    mock.patch.dict(
                        fastmail.os.environ, {"HOME": directory, **extra}, clear=True
                    ),
                    mock.patch.object(fastmail, "Session") as session,
                    mock.patch.object(fastmail, "cmd_mailboxes", return_value=[]),
                    contextlib.redirect_stdout(stdout),
                    contextlib.redirect_stderr(stderr),
                ):
                    self.assertEqual(fastmail.main(["mailboxes"]), 0)
                session.assert_called_once_with(expected)
                self.assertEqual(json.loads(stdout.getvalue()), [])
                self.assertEqual(stderr.getvalue(), "")
                self.assertNotIn(expected, stdout.getvalue())
