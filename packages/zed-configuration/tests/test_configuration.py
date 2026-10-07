import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest import mock

import zed_configuration as configuration


class ConfigurationTests(unittest.TestCase):
    def test_jsonc_strings_comments_and_trailing_commas(self):
        self.assertEqual(
            configuration.parse_jsonc(
                '// comment\n{"url": "https://fixture/*literal*/", "quote": "\\"//", "nested": [1, /* comment */ 2,],}\n'
            ),
            {"url": "https://fixture/*literal*/", "quote": '"//', "nested": [1, 2]},
        )

    def test_recursive_merge_preserves_undeclared_keys(self):
        current = {"terminal": {"font_size": 17, "font_family": "old"}, "ui_state": [1]}
        declared = {"terminal": {"font_family": "managed"}, "vim_mode": True}
        result = configuration.merge(current, declared)
        self.assertEqual(
            result,
            {
                "terminal": {"font_size": 17, "font_family": "managed"},
                "ui_state": [1],
                "vim_mode": True,
            },
        )
        self.assertEqual(current["terminal"]["font_family"], "old")
        self.assertEqual(configuration.merge(result, declared), result)

    def test_malformed_content_is_rejected(self):
        for content in ('{"x":', "{/* unfinished", "[]", '{"x": "unterminated}'):
            with self.subTest(content=content), self.assertRaises(ValueError):
                configuration.parse_jsonc(content)

    def test_main_initializes_and_preserves_current_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            declaration = Path(directory, "managed.json")
            declaration.write_text('{"vim_mode": true}')
            for original in (
                "",
                '// preserve comment\n{"vim_mode": true, "other": 2,}\n',
            ):
                output = io.StringIO()
                with (
                    mock.patch("sys.stdin", io.StringIO(original)),
                    contextlib.redirect_stdout(output),
                ):
                    self.assertEqual(
                        configuration.main(["--declaration", str(declaration)]), 0
                    )
                if original:
                    self.assertEqual(output.getvalue(), original)
                else:
                    self.assertEqual(json.loads(output.getvalue()), {"vim_mode": True})
