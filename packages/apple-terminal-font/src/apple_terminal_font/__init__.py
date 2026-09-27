"""Set the Terminal startup and default profile fonts without changing their sizes."""

import argparse
import os
import plistlib
import subprocess
import sys
from collections.abc import Sequence

DOMAIN = "com.apple.Terminal"


def archived_font(name: str, size: float) -> bytes:
    return plistlib.dumps(
        {
            "$version": 100000,
            "$archiver": "NSKeyedArchiver",
            "$top": {"root": plistlib.UID(1)},
            "$objects": [
                "$null",
                {
                    "$class": plistlib.UID(3),
                    "NSName": plistlib.UID(2),
                    "NSSize": size,
                    "NSfFlags": 16,
                },
                name,
                {"$classname": "NSFont", "$classes": ["NSFont", "NSObject"]},
            ],
        },
        fmt=plistlib.FMT_BINARY,
    )


def font_name(blob: object) -> str | None:
    if not isinstance(blob, bytes):
        return None
    objects = plistlib.loads(blob).get("$objects", [])
    font = objects[1] if len(objects) > 1 else None
    if not isinstance(font, dict):
        return None
    index = font.get("NSName")
    return objects[index.data] if isinstance(index, plistlib.UID) else None


def font_size(blob: object) -> float:
    if not isinstance(blob, bytes):
        return 12.0
    objects = plistlib.loads(blob).get("$objects", [])
    font = objects[1] if len(objects) > 1 else None
    return float(font.get("NSSize", 12.0)) if isinstance(font, dict) else 12.0


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("font", metavar="FONT")
    args = parser.parse_args(sys.argv[1:] if argv is None else argv)
    defaults = os.environ.get("APPLE_TERMINAL_FONT_DEFAULTS", "/usr/bin/defaults")

    try:
        exported = subprocess.run(
            [defaults, "export", DOMAIN, "-"], capture_output=True, check=True
        ).stdout
        prefs = plistlib.loads(exported)
        profiles = prefs.get("Window Settings", {})
        changed = sorted(
            {
                name
                for key in ("Default Window Settings", "Startup Window Settings")
                if (name := prefs.get(key)) in profiles
                and font_name(profiles[name].get("Font")) != args.font
            }
        )
        if not changed:
            print("Terminal.app: current", file=sys.stderr)
            return 0

        for name in changed:
            profile = profiles[name]
            profile["Font"] = archived_font(args.font, font_size(profile.get("Font")))

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
        IndexError,
    ) as error:
        detail = (
            error.stderr.decode(errors="replace").strip()
            if isinstance(error, subprocess.CalledProcessError) and error.stderr
            else str(error)
        )
        print(f"Terminal.app: {detail}", file=sys.stderr)
        return 1

    print(f"Terminal.app: set {', '.join(changed)} to {args.font}", file=sys.stderr)
    try:
        process_status = subprocess.run(
            ["/usr/bin/pgrep", "-qx", "Terminal"]
        ).returncode
    except OSError as error:
        print(f"Terminal.app: cannot check running process: {error}", file=sys.stderr)
        return 1
    if process_status not in (0, 1):
        print(
            f"Terminal.app: process check failed: exit {process_status}",
            file=sys.stderr,
        )
        return 1
    if process_status == 0:
        print(
            "Terminal.app: running, and it rewrites its preferences on quit -- "
            "quit and reopen it for this to stick.",
            file=sys.stderr,
        )
    return 0


def entry_point() -> int:
    return main()
