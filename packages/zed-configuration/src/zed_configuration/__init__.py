"""Merge declared Zed settings into JSONC on stdin without destination writes."""

import argparse
from collections.abc import Sequence
import copy
import json
from pathlib import Path
import sys


def parse_jsonc(text: str) -> dict:
    # Preserve offsets while stripping comments, honoring escapes in strings.
    chars = list(text)
    index = 0
    quoted = False
    while index < len(chars):
        char = chars[index]
        if quoted:
            if char == "\\":
                index += 2
                continue
            if char == '"':
                quoted = False
        elif char == '"':
            quoted = True
        elif char == "/" and index + 1 < len(chars):
            following = chars[index + 1]
            if following == "/":
                end = text.find("\n", index + 2)
                end = len(chars) if end < 0 else end
                chars[index:end] = " " * (end - index)
                index = end
                continue
            if following == "*":
                end = text.find("*/", index + 2)
                if end < 0:
                    raise ValueError("unterminated JSONC comment")
                end += 2
                chars[index:end] = [
                    "\n" if c == "\n" else " " for c in chars[index:end]
                ]
                index = end
                continue
        index += 1
    # JSONC permits trailing commas; remove only commas outside strings.
    index = 0
    quoted = False
    while index < len(chars):
        char = chars[index]
        if quoted:
            if char == "\\":
                index += 2
                continue
            if char == '"':
                quoted = False
        elif char == '"':
            quoted = True
        elif char == ",":
            end = index + 1
            while end < len(chars) and chars[end].isspace():
                end += 1
            if end < len(chars) and chars[end] in "}]":
                chars[index] = " "
        index += 1
    value = json.loads("".join(chars))
    if not isinstance(value, dict):
        raise ValueError("settings must be an object")
    return value


def merge(current: dict, declaration: dict) -> dict:
    result = copy.deepcopy(current)
    for key, value in declaration.items():
        if isinstance(value, dict) and isinstance(result.get(key), dict):
            result[key] = merge(result[key], value)
        else:
            result[key] = copy.deepcopy(value)
    return result


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--declaration", required=True, type=Path)
    args = parser.parse_args(argv)
    try:
        declaration = parse_jsonc(args.declaration.read_text(encoding="utf-8"))
        original = sys.stdin.read()
        current = parse_jsonc(original) if original.strip() else {}
        result = merge(current, declaration)
        sys.stdout.write(
            original if result == current else json.dumps(result, indent=2) + "\n"
        )
    except (OSError, ValueError) as exc:
        print(f"zed-configuration: {exc}", file=sys.stderr)
        return 1
    return 0


def entry_point() -> None:
    sys.exit(main())
