"""Merge declared Karabiner settings on stdin, never touching a destination."""

import argparse
from collections.abc import Sequence
import copy
import json
from pathlib import Path
import sys


def merge(current: dict, declaration: dict) -> dict:
    result = copy.deepcopy(current)
    global_settings = result.setdefault("global", {})
    if not isinstance(global_settings, dict):
        raise ValueError("global must be an object")
    global_settings.update(declaration["global"])
    profiles = result.setdefault("profiles", [])
    if not isinstance(profiles, list) or not all(isinstance(p, dict) for p in profiles):
        raise ValueError("profiles must be an array of objects")
    desired = declaration["profiles"][0]
    matches = [p for p in profiles if p.get("name") == desired["name"]]
    if len(matches) > 1:
        raise ValueError("managed profile name is ambiguous")
    if matches:
        profile = matches[0]
    else:
        profile = {"name": desired["name"]}
        profiles.append(profile)
    profile["selected"] = desired["selected"]
    if desired["selected"]:
        for other in profiles:
            if other is not profile:
                other["selected"] = False
    keyboard = profile.setdefault("virtual_hid_keyboard", {})
    complex_settings = profile.setdefault("complex_modifications", {})
    if not isinstance(keyboard, dict) or not isinstance(complex_settings, dict):
        raise ValueError("managed profile settings must be objects")
    keyboard.update(desired["virtual_hid_keyboard"])
    rules = complex_settings.setdefault("rules", [])
    if not isinstance(rules, list) or not all(isinstance(r, dict) for r in rules):
        raise ValueError("rules must be an array of objects")
    managed = desired["complex_modifications"]["rules"]
    descriptions = {r["description"] for r in managed}
    complex_settings["rules"] = [
        r for r in rules if r.get("description") not in descriptions
    ] + copy.deepcopy(managed)
    return result


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--declaration", required=True, type=Path)
    args = parser.parse_args(argv)
    try:
        declaration = json.loads(args.declaration.read_text(encoding="utf-8"))
        original = sys.stdin.read()
        current = json.loads(original) if original.strip() else {}
        if not isinstance(current, dict):
            raise ValueError("configuration must be an object")
        result = merge(current, declaration)
        sys.stdout.write(
            original if result == current else json.dumps(result, indent=2) + "\n"
        )
    except (OSError, ValueError, KeyError, TypeError, IndexError) as exc:
        print(f"karabiner-configuration: {exc}", file=sys.stderr)
        return 1
    return 0


def entry_point() -> None:
    sys.exit(main())
