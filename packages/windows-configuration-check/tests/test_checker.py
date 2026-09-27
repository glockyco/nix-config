import contextlib
import copy
import io
import json
import os
import pathlib
import tempfile
import unittest
from unittest.mock import patch

import yaml

from windows_configuration_check import main


ROLES = [
    ("browser", "Zen-Team.Zen-Browser", "exact", "machine", "winget"),
    ("editor", "ZedIndustries.Zed", "self-updating", "user", "winget"),
    ("browser-relay", "Brave.Brave", "self-updating", "user", "winget"),
    ("communication-client", "Ferdium.Ferdium", "self-updating", "user", "winget"),
    ("git-client", "Example.Git", "exact", "user", "winget"),
    ("launcher", "Example.Launcher", "exact", "user", "winget"),
    ("keyboard-layout", "Example.Keyboard", "exact", "user", "winget"),
    ("terminal", "Example.Terminal", "exact", "user", "winget"),
    ("terminal-font", "Example.Font", "exact", "user", "release"),
    ("window-tool", "Example.Window", "exact", "user", "release"),
]


def fixture():
    applications = []
    resources = []
    for role, identifier, policy, scope, source in ROLES:
        name = "package " + role.replace("-", " ")
        application = {
            "name": role,
            "role": role,
            "id": identifier,
            "versionPolicy": policy,
            "source": source,
            "scope": scope,
        }
        metadata = {
            "id": identifier,
            "roles": [role],
            "versionPolicy": policy,
            "source": source,
            "scope": scope,
        }
        if policy == "exact":
            application["version"] = "1.0"
            metadata["version"] = "1.0"
        if source == "winget":
            properties = {
                "id": identifier,
                "source": source,
                "useLatest": policy == "self-updating",
            }
            if policy == "exact":
                properties["version"] = "1.0"
            resource_type = "Microsoft.WinGet/Package"
        else:
            properties = {
                "testScript": "return $true",
                "setScript": "Write-Output 'installed'",
            }
            resource_type = "Microsoft.DSC.Transitional/WindowsPowerShellScript"
        resource = {
            "name": name,
            "type": resource_type,
            "properties": properties,
            "metadata": {"application": metadata},
        }
        if role == "browser":
            resource["metadata"]["winget"] = {"securityContext": "elevated"}
        applications.append(application)
        resources.append(resource)
    declaration = {
        "roles": [role for role, *_ in ROLES],
        "applications": applications,
        "managedApplications": ["Managed.Package"],
        "reviewFiles": [
            "start-reneo-elevated.ps1",
            *[f"review-{index:02}.json" for index in range(15)],
        ],
    }
    document = {
        "$schema": "https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2023/08/config/document.json",
        "metadata": {"winget": {"processor": {"identifier": "dscv3"}}},
        "resources": resources,
    }
    return declaration, document


class Arguments(unittest.TestCase):
    def test_invalid_arguments_are_one_finding(self):
        output = io.StringIO()
        with contextlib.redirect_stderr(output):
            status = main(["--schemas", "/not/a/schema"])
        self.assertEqual(status, 1)
        self.assertEqual(len(output.getvalue().splitlines()), 1)
        self.assertIn("arguments:", output.getvalue())
        self.assertNotIn("Traceback", output.getvalue())

    def test_none_reads_process_arguments(self):
        output = io.StringIO()
        with (
            patch("sys.argv", ["windows-configuration-check"]),
            contextlib.redirect_stderr(output),
        ):
            self.assertEqual(main(), 1)
        self.assertIn("arguments:", output.getvalue())

    def test_unexpected_programming_error_is_not_hidden(self):
        with patch(
            "windows_configuration_check.check",
            side_effect=RuntimeError("programming failure"),
        ):
            with self.assertRaisesRegex(RuntimeError, "programming failure"):
                main(["--schemas", "x", "--declaration", "y", "z"])


@unittest.skipUnless(
    os.environ.get("WINDOWS_CHECK_TEST_SCHEMAS"), "pinned DSC schemas not supplied"
)
class Checker(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        root = pathlib.Path(self.temporary.name)
        self.output = root / "rendered"
        self.output.mkdir()
        self.declaration_path = root / "declaration.json"
        self.declaration, self.document = fixture()
        self.schemas = os.environ["WINDOWS_CHECK_TEST_SCHEMAS"]
        for name in self.declaration["reviewFiles"]:
            (self.output / name).write_text("{}", encoding="utf-8")
        for name in (
            "apply-kbdneo.ps1",
            "apply-zen-policies.ps1",
            "start-reneo-elevated.ps1",
        ):
            (self.output / name).write_text("Write-Output 'valid'\n", encoding="utf-8")

    def run_checker(self):
        self.declaration_path.write_text(json.dumps(self.declaration), encoding="utf-8")
        (self.output / "configuration.winget").write_text(
            yaml.safe_dump(self.document), encoding="utf-8"
        )
        stderr = io.StringIO()
        with contextlib.redirect_stderr(stderr):
            status = main(
                [
                    "--schemas",
                    self.schemas,
                    "--declaration",
                    str(self.declaration_path),
                    str(self.output),
                ]
            )
        return status, stderr.getvalue()

    def reject(self, expected):
        status, message = self.run_checker()
        self.assertEqual(status, 1, message)
        self.assertEqual(len(message.splitlines()), 1, message)
        self.assertIn(expected, message)
        self.assertNotIn("Traceback", message)
        self.assertNotIn("StopIteration", message)

    def application(self, role):
        return next(
            item for item in self.declaration["applications"] if item["role"] == role
        )

    def resource(self, role):
        return next(
            item
            for item in self.document["resources"]
            if item["name"] == "package " + role.replace("-", " ")
        )

    def test_accepted_exact_and_self_updating(self):
        self.resource("git-client")["dependsOn"] = ["package editor"]
        self.assertEqual(self.run_checker(), (0, ""))
        self.application("git-client")["version"] = "2.0"
        self.resource("git-client")["metadata"]["application"]["version"] = "2.0"
        self.resource("git-client")["properties"]["version"] = "2.0"
        self.assertEqual(self.run_checker(), (0, ""))

    def test_policy_roles_and_managed_identifiers(self):
        cases = [
            (
                "missing policy",
                lambda: self.application("git-client").pop("versionPolicy"),
                "git-client",
            ),
            (
                "invalid policy",
                lambda: self.application("git-client").update(versionPolicy="unknown"),
                "git-client",
            ),
            (
                "forbidden self update",
                lambda: self.application("git-client").update(
                    versionPolicy="self-updating"
                ),
                "git-client",
            ),
            (
                "missing version",
                lambda: self.application("git-client").pop("version"),
                "git-client",
            ),
            (
                "self update version",
                lambda: self.application("editor").update(version="2.0"),
                "editor",
            ),
            (
                "managed identifier",
                lambda: self.application("launcher").update(id="Managed.Package"),
                "launcher",
            ),
            (
                "missing role",
                lambda: self.declaration["applications"].pop(),
                "window-tool",
            ),
            (
                "duplicate role",
                lambda: self.declaration["applications"].append(
                    copy.deepcopy(self.application("launcher"))
                ),
                "launcher",
            ),
            (
                "outside roles",
                lambda: self.application("launcher").update(role="unlisted"),
                "unlisted",
            ),
            (
                "machine scope",
                lambda: self.application("launcher").update(scope="machine"),
                "launcher",
            ),
        ]
        for label, mutate, expected in cases:
            with self.subTest(label):
                self.declaration, self.document = fixture()
                mutate()
                self.reject(expected)

    def test_resource_selectors_and_metadata(self):
        cases = [
            (
                "exact version",
                lambda: self.resource("launcher")["properties"].update(version="2.0"),
                "package launcher",
            ),
            (
                "exact latest",
                lambda: self.resource("launcher")["properties"].update(useLatest=True),
                "package launcher",
            ),
            (
                "self version",
                lambda: self.resource("editor")["properties"].update(version="1.0"),
                "package editor",
            ),
            (
                "self latest",
                lambda: self.resource("editor")["properties"].update(useLatest=False),
                "package editor",
            ),
            (
                "missing selector",
                lambda: self.resource("launcher")["properties"].pop("version"),
                "package launcher",
            ),
            (
                "id mismatch",
                lambda: self.resource("launcher")["properties"].update(
                    id="Other.Launcher"
                ),
                "package launcher",
            ),
            (
                "metadata scope",
                lambda: self.resource("launcher")["metadata"]["application"].update(
                    scope="machine"
                ),
                "package launcher",
            ),
            (
                "resource absent",
                lambda: self.document["resources"].remove(self.resource("launcher")),
                "launcher",
            ),
            (
                "duplicate application",
                lambda: self.document["resources"].append(
                    {**copy.deepcopy(self.resource("editor")), "name": "other editor"}
                ),
                "editor",
            ),
        ]
        for label, mutate, expected in cases:
            with self.subTest(label):
                self.declaration, self.document = fixture()
                mutate()
                self.reject(expected)

    def test_fixed_identities_and_ownership(self):
        for role in ("browser", "editor", "browser-relay", "communication-client"):
            with self.subTest(role):
                self.declaration, self.document = fixture()
                self.application(role)["id"] = "Replaced.Package"
                self.reject(role)
        for role in ("browser-relay", "communication-client"):
            with self.subTest(f"{role} startup"):
                self.declaration, self.document = fixture()
                self.document["resources"].append(
                    {
                        "name": role.replace("-", " ") + " startup",
                        "type": "Microsoft.Windows/Registry",
                        "properties": {
                            "keyPath": "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
                            "valueData": {"String": self.application(role)["id"]},
                        },
                    }
                )
                self.reject(role)
            with self.subTest(f"{role} profile"):
                self.declaration, self.document = fixture()
                self.document["resources"].append(
                    {
                        "name": role.replace("-", " ") + " profile",
                        "type": "Microsoft.Windows/Registry",
                        "properties": {
                            "keyPath": "HKCU\\Software\\Example",
                            "valueData": {"String": "other.exe"},
                        },
                    }
                )
                self.reject(role)

    def test_document_schema_and_dependencies(self):
        cases = [
            (
                "duplicate names",
                lambda: self.document["resources"].append(
                    copy.deepcopy(self.resource("editor"))
                ),
                "package editor",
            ),
            (
                "missing dependency",
                lambda: self.resource("launcher").update(dependsOn=["absent resource"]),
                "absent resource",
            ),
            (
                "resourceId dependency",
                lambda: self.resource("launcher").update(
                    dependsOn=[
                        "[resourceId('Microsoft.WinGet/Package', 'package editor')]"
                    ]
                ),
                "package launcher",
            ),
            (
                "revision URL",
                lambda: self.document.update(
                    {
                        "$schema": "https://raw.githubusercontent.com/PowerShell/DSC/45b10078ba49d9f9ec13b72c1040368eac9838e9/schemas/2023/08/config/document.json"
                    }
                ),
                "configuration.winget",
            ),
            (
                "no metadata",
                lambda: self.document.pop("metadata"),
                "configuration.winget",
            ),
            (
                "machine feature",
                lambda: self.document["resources"].append(
                    {
                        "name": "forbidden feature",
                        "type": "Microsoft.Windows/OptionalFeatureList",
                        "properties": {},
                    }
                ),
                "forbidden feature",
            ),
            (
                "extra elevation",
                lambda: self.resource("launcher")["metadata"].update(
                    winget={"securityContext": "elevated"}
                ),
                "package launcher",
            ),
            (
                "missing elevation",
                lambda: self.resource("browser")["metadata"].pop("winget"),
                "package browser",
            ),
            (
                "machine key",
                lambda: self.document["resources"].append(
                    {
                        "name": "machine setting",
                        "type": "Microsoft.Windows/Registry",
                        "properties": {"keyPath": "HKLM\\Software\\Example"},
                    }
                ),
                "machine setting",
            ),
            (
                "CloudStore key",
                lambda: self.document["resources"].append(
                    {
                        "name": "night light",
                        "type": "Microsoft.Windows/Registry",
                        "properties": {"keyPath": "HKCU\\CloudStore"},
                    }
                ),
                "CloudStore",
            ),
        ]
        for label, mutate, expected in cases:
            with self.subTest(label):
                self.declaration, self.document = fixture()
                mutate()
                self.reject(expected)

    def test_file_set_and_input_errors(self):
        self.declaration["reviewFiles"].remove("review-00.json")
        self.reject("reviewFiles")
        self.declaration, self.document = fixture()
        (self.output / "review-00.json").unlink()
        self.reject("review-00.json")
        (self.output / "review-00.json").write_text("{}", encoding="utf-8")
        (self.output / "extra.json").write_text("{}", encoding="utf-8")
        self.reject("extra.json")
        (self.output / "extra.json").unlink()
        (self.output / "configuration.winget").unlink()
        self.declaration_path.write_text(json.dumps(self.declaration), encoding="utf-8")
        output = io.StringIO()
        with contextlib.redirect_stderr(output):
            status = main(
                [
                    "--schemas",
                    self.schemas,
                    "--declaration",
                    str(self.declaration_path),
                    str(self.output),
                ]
            )
        self.assertEqual(status, 1)
        self.assertIn("configuration.winget", output.getvalue())
        self.assertEqual(len(output.getvalue().splitlines()), 1)

    def test_parser_and_administrator_boundaries(self):
        cases = [
            (
                "script syntax",
                lambda: self.resource("window-tool")["properties"].update(
                    setScript="if ($true) {"
                ),
                "package window tool setScript",
            ),
            (
                "admin variable",
                lambda: (self.output / "apply-kbdneo.ps1").write_text(
                    "$env:APPDATA\n", encoding="utf-8"
                ),
                "env:APPDATA",
            ),
            (
                "admin string",
                lambda: (self.output / "apply-zen-policies.ps1").write_text(
                    "'HKCU:\\Software\\Example'\n", encoding="utf-8"
                ),
                "HKCU",
            ),
            (
                "admin machine path",
                lambda: (self.output / "apply-zen-policies.ps1").write_text(
                    "'HKLM:\\Software\\Other'\n", encoding="utf-8"
                ),
                "HKLM",
            ),
            (
                "script CloudStore",
                lambda: self.resource("window-tool")["properties"].update(
                    setScript="'CloudStore'"
                ),
                "CloudStore",
            ),
            (
                "launcher syntax",
                lambda: (self.output / "start-reneo-elevated.ps1").write_text(
                    "if ($true) {", encoding="utf-8"
                ),
                "start-reneo-elevated.ps1",
            ),
        ]
        for label, mutate, expected in cases:
            with self.subTest(label):
                self.declaration, self.document = fixture()
                for name in (
                    "apply-kbdneo.ps1",
                    "apply-zen-policies.ps1",
                    "start-reneo-elevated.ps1",
                ):
                    (self.output / name).write_text(
                        "Write-Output 'valid'\n", encoding="utf-8"
                    )
                mutate()
                self.reject(expected)

    def test_script_refactor_does_not_change_policy(self):
        self.resource("window-tool")["properties"]["setScript"] = (
            "function Update-Setting { param($value) Write-Output $value }; Update-Setting 'valid'"
        )
        (self.output / "apply-kbdneo.ps1").write_text(
            "$env:SystemRoot\n", encoding="utf-8"
        )
        (self.output / "apply-zen-policies.ps1").write_text(
            "$env:ProgramFiles\n", encoding="utf-8"
        )
        self.assertEqual(self.run_checker(), (0, ""))


if __name__ == "__main__":
    unittest.main()
