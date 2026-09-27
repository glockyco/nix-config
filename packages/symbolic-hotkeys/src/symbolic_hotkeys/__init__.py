"""Disable selected symbolic hotkeys while retaining the rest of the domain."""

import argparse
import os
import plistlib
import subprocess
import sys
from collections.abc import Sequence

DOMAIN = "com.apple.symbolichotkeys"


def disable(prefs: dict, identifiers: Sequence[str]) -> list[str]:
    hotkeys = prefs.setdefault("AppleSymbolicHotKeys", {})
    if not isinstance(hotkeys, dict):
        raise ValueError("AppleSymbolicHotKeys is not a dictionary")

    changed = []
    for identifier in dict.fromkeys(identifiers):
        shortcut = hotkeys.get(identifier)
        if shortcut is None:
            hotkeys[identifier] = {"enabled": False}
            changed.append(identifier)
        elif not isinstance(shortcut, dict):
            raise ValueError(f"shortcut {identifier} is not a dictionary")
        elif shortcut.get("enabled") is not False:
            shortcut["enabled"] = False
            changed.append(identifier)
    return changed


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("identifiers", metavar="ID", nargs="+")
    args = parser.parse_args(sys.argv[1:] if argv is None else argv)
    defaults = os.environ.get("SYMBOLIC_HOTKEYS_DEFAULTS", "/usr/bin/defaults")

    try:
        exported = subprocess.run(
            [defaults, "export", DOMAIN, "-"], capture_output=True, check=True
        ).stdout
        prefs = plistlib.loads(exported)
        changed = disable(prefs, args.identifiers)
        if not changed:
            print("symbolic hotkeys: current", file=sys.stderr)
            return 0
        subprocess.run(
            [defaults, "import", DOMAIN, "-"],
            input=plistlib.dumps(prefs, fmt=plistlib.FMT_XML),
            capture_output=True,
            check=True,
        )
    except (
        OSError,
        subprocess.CalledProcessError,
        ValueError,
        TypeError,
        KeyError,
    ) as error:
        detail = (
            error.stderr.decode(errors="replace").strip()
            if isinstance(error, subprocess.CalledProcessError) and error.stderr
            else str(error)
        )
        print(f"symbolic hotkeys: {detail}", file=sys.stderr)
        return 1

    print(f"symbolic hotkeys: disabled {', '.join(changed)}", file=sys.stderr)
    return 0


def entry_point() -> int:
    return main()
