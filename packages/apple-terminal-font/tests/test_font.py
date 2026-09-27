import importlib
import plistlib
import subprocess
import sys
import unittest
from unittest.mock import patch

from apple_terminal_font import archived_font, font_name, font_size, main


class FontTest(unittest.TestCase):
    def test_import_has_no_command_or_argument_effect(self):
        with (
            patch.object(sys, "argv", ["apple-terminal-font"]),
            patch("subprocess.run", side_effect=AssertionError("command on import")),
        ):
            importlib.reload(sys.modules["apple_terminal_font"])

    def test_archive_round_trip_and_non_bytes(self):
        blob = archived_font("Example Nerd Font", 15.5)
        archive = plistlib.loads(blob)
        self.assertEqual(archive["$archiver"], "NSKeyedArchiver")
        self.assertEqual(font_name(blob), "Example Nerd Font")
        self.assertEqual(font_size(blob), 15.5)
        self.assertIsNone(font_name("plain font"))
        self.assertEqual(font_size("plain font"), 12.0)

    def test_current_profiles_do_not_import(self):
        prefs = {
            "Default Window Settings": "Main",
            "Startup Window Settings": "Main",
            "Window Settings": {"Main": {"Font": archived_font("New", 14)}},
        }
        with patch(
            "subprocess.run",
            return_value=subprocess.CompletedProcess([], 0, plistlib.dumps(prefs)),
        ) as run:
            self.assertEqual(main(["New"]), 0)
        run.assert_called_once()

    def test_changed_profile_retains_size_and_unrelated_data(self):
        prefs = {
            "Default Window Settings": "Main",
            "Startup Window Settings": "Main",
            "Window Settings": {
                "Main": {"Font": archived_font("Old", 17.5), "Other": "keep"},
                "Unused": {"Font": archived_font("Old", 11)},
            },
            "Other Domain Entry": [1, 2],
        }
        calls = []

        def command(args, **kwargs):
            calls.append((args, kwargs))
            if args[1] == "export":
                return subprocess.CompletedProcess(args, 0, plistlib.dumps(prefs))
            return subprocess.CompletedProcess(args, 1)

        with patch("subprocess.run", side_effect=command):
            self.assertEqual(main(["New"]), 0)
        self.assertEqual([call[0][1] for call in calls[:2]], ["export", "import"])
        written = plistlib.loads(calls[1][1]["input"])
        self.assertEqual(font_name(written["Window Settings"]["Main"]["Font"]), "New")
        self.assertEqual(font_size(written["Window Settings"]["Main"]["Font"]), 17.5)
        self.assertEqual(written["Window Settings"]["Main"]["Other"], "keep")
        self.assertEqual(
            written["Window Settings"]["Unused"], prefs["Window Settings"]["Unused"]
        )
        self.assertEqual(written["Other Domain Entry"], [1, 2])

    def test_unexpected_process_probe_failure_is_fatal(self):
        prefs = {
            "Default Window Settings": "Main",
            "Window Settings": {"Main": {"Font": archived_font("Old", 17)}},
        }
        calls = []

        def command(args, **kwargs):
            calls.append(args)
            if args[1] == "export":
                return subprocess.CompletedProcess(args, 0, plistlib.dumps(prefs))
            if args[1] == "import":
                return subprocess.CompletedProcess(args, 0)
            return subprocess.CompletedProcess(args, 2)

        with patch("subprocess.run", side_effect=command):
            self.assertEqual(main(["New"]), 1)
        self.assertEqual([args[1] for args in calls[:2]], ["export", "import"])
        self.assertEqual(calls[2], ["/usr/bin/pgrep", "-qx", "Terminal"])

    def test_missing_startup_profiles_do_not_create_them(self):
        prefs = {"Default Window Settings": "Missing", "Window Settings": {"Other": {}}}
        with patch(
            "subprocess.run",
            return_value=subprocess.CompletedProcess([], 0, plistlib.dumps(prefs)),
        ) as run:
            self.assertEqual(main(["New"]), 0)
        run.assert_called_once()

    def test_export_failure_does_not_import(self):
        with patch(
            "subprocess.run", side_effect=subprocess.CalledProcessError(4, "defaults")
        ) as run:
            self.assertEqual(main(["New"]), 1)
        run.assert_called_once()
