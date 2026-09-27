import importlib
import plistlib
import subprocess
import sys
import unittest
from unittest.mock import patch

from symbolic_hotkeys import disable, main


class HotkeysTest(unittest.TestCase):
    def test_import_has_no_command_or_argument_effect(self):
        with (
            patch.object(sys, "argv", ["symbolic-hotkeys"]),
            patch("subprocess.run", side_effect=AssertionError("command on import")),
        ):
            importlib.reload(sys.modules["symbolic_hotkeys"])

    def test_disable_only_selected_keys(self):
        prefs = {
            "Other": {"retained": True},
            "AppleSymbolicHotKeys": {
                "15": {"enabled": True, "value": {"parameters": [1, 2, 3]}},
                "16": {"enabled": True, "other": "keep"},
                "17": {"enabled": False, "value": "unchanged"},
            },
        }
        self.assertEqual(disable(prefs, ["15", "17", "99", "99"]), ["15", "99"])
        self.assertEqual(prefs["Other"], {"retained": True})
        self.assertEqual(
            prefs["AppleSymbolicHotKeys"]["15"],
            {"enabled": False, "value": {"parameters": [1, 2, 3]}},
        )
        self.assertEqual(
            prefs["AppleSymbolicHotKeys"]["16"], {"enabled": True, "other": "keep"}
        )
        self.assertEqual(
            prefs["AppleSymbolicHotKeys"]["17"],
            {"enabled": False, "value": "unchanged"},
        )
        self.assertEqual(prefs["AppleSymbolicHotKeys"]["99"], {"enabled": False})

    def test_current_domain_skips_import(self):
        prefs = {"AppleSymbolicHotKeys": {"15": {"enabled": False}}}
        with patch(
            "subprocess.run",
            return_value=subprocess.CompletedProcess([], 0, plistlib.dumps(prefs)),
        ) as run:
            self.assertEqual(main(["15"]), 0)
        run.assert_called_once()

    def test_absent_table_is_added_and_imported_once(self):
        prefs = {"Other": ["keep"]}
        calls = []

        def command(args, **kwargs):
            calls.append((args, kwargs))
            return subprocess.CompletedProcess(args, 0, plistlib.dumps(prefs))

        with patch("subprocess.run", side_effect=command):
            self.assertEqual(main(["15", "16"]), 0)
        self.assertEqual([call[0][1] for call in calls], ["export", "import"])
        self.assertEqual(
            plistlib.loads(calls[1][1]["input"]),
            {
                "Other": ["keep"],
                "AppleSymbolicHotKeys": {
                    "15": {"enabled": False},
                    "16": {"enabled": False},
                },
            },
        )

    def test_export_failure_does_not_import(self):
        with patch(
            "subprocess.run", side_effect=subprocess.CalledProcessError(4, "defaults")
        ) as run:
            self.assertEqual(main(["15"]), 1)
        run.assert_called_once()

    def test_malformed_selected_entry_does_not_import(self):
        prefs = {"AppleSymbolicHotKeys": {"15": "unexpected"}}
        with patch(
            "subprocess.run",
            return_value=subprocess.CompletedProcess([], 0, plistlib.dumps(prefs)),
        ) as run:
            self.assertEqual(main(["15"]), 1)
        run.assert_called_once()
