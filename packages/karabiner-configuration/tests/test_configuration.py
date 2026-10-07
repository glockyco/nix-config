import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import karabiner_configuration as configuration

DECLARATION = {
    "global": {"show_in_menu_bar": True},
    "profiles": [
        {
            "name": "Neo2",
            "selected": True,
            "virtual_hid_keyboard": {"keyboard_type_v2": "iso"},
            "complex_modifications": {
                "rules": [{"description": "managed", "manipulators": [1]}]
            },
        }
    ],
}


class ConfigurationTests(unittest.TestCase):
    def test_merge_preserves_profiles_settings_and_rules(self):
        other = {"name": "Other", "selected": False, "ui": [1]}
        current = {
            "global": {"other": 2},
            "extra": True,
            "profiles": [
                other,
                {
                    "name": "Neo2",
                    "ui": "keep",
                    "virtual_hid_keyboard": {"country_code": 1},
                    "complex_modifications": {
                        "parameters": {"delay": 42},
                        "rules": [
                            {"description": "managed", "manipulators": [0]},
                            {"description": "unmanaged", "manipulators": [2]},
                            {"description": "managed", "manipulators": [0]},
                        ],
                    },
                },
            ],
        }
        result = configuration.merge(current, DECLARATION)
        self.assertEqual(result["profiles"][0], other)
        self.assertEqual(result["global"], {"other": 2, "show_in_menu_bar": True})
        profile = result["profiles"][1]
        self.assertEqual(profile["ui"], "keep")
        self.assertEqual(
            profile["virtual_hid_keyboard"],
            {"country_code": 1, "keyboard_type_v2": "iso"},
        )
        self.assertEqual(profile["complex_modifications"]["parameters"], {"delay": 42})
        self.assertEqual(
            [r["description"] for r in profile["complex_modifications"]["rules"]],
            ["unmanaged", "managed"],
        )
        self.assertEqual(configuration.merge(result, DECLARATION), result)
        self.assertNotEqual(current, result)

    def test_absent_profile_initializes(self):
        self.assertEqual(configuration.merge({}, DECLARATION), DECLARATION)

    def test_malformed_schema_and_ambiguous_profile_fail(self):
        for current in (
            {"profiles": "bad"},
            {"global": []},
            {"profiles": [{"name": "Neo2", "complex_modifications": {"rules": [1]}}]},
            {"profiles": [{"name": "Neo2"}, {"name": "Neo2"}]},
        ):
            with self.subTest(current=current), self.assertRaises(ValueError):
                configuration.merge(current, DECLARATION)

    def test_main_preserves_current_bytes_and_emits_nothing_on_failure(self):
        with tempfile.TemporaryDirectory() as directory:
            declaration = Path(directory, "managed.json")
            declaration.write_text(json.dumps(DECLARATION))
            original = json.dumps(DECLARATION, separators=(",", ":"))
            output = io.StringIO()
            with (
                mock.patch("sys.stdin", io.StringIO(original)),
                contextlib.redirect_stdout(output),
            ):
                self.assertEqual(
                    configuration.main(["--declaration", str(declaration)]), 0
                )
            self.assertEqual(output.getvalue(), original)
            output = io.StringIO()
            with (
                mock.patch("sys.stdin", io.StringIO("{malformed")),
                contextlib.redirect_stdout(output),
                contextlib.redirect_stderr(io.StringIO()),
            ):
                self.assertEqual(
                    configuration.main(["--declaration", str(declaration)]), 1
                )
            self.assertEqual(output.getvalue(), "")
