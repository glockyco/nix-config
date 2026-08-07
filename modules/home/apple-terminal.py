"""Set active Terminal.app profiles to a Nerd Font.
Terminal.app stores fonts as NSKeyedArchiver blobs; preserve profile sizes."""

import plistlib
import subprocess
import sys

DOMAIN = "com.apple.Terminal"
FONT = sys.argv[1]


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


def font_name(blob):
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


# Home Manager activation does not include `/usr/bin` in PATH.
DEFAULTS = "/usr/bin/defaults"

prefs = plistlib.loads(
    subprocess.run(
        [DEFAULTS, "export", DOMAIN, "-"], capture_output=True, check=True
    ).stdout
)
profiles = prefs.get("Window Settings", {})

# Update only profiles Terminal opens with; leave other profile fonts unchanged.
wanted = {
    prefs.get(key)
    for key in ("Default Window Settings", "Startup Window Settings")
    if prefs.get(key) in profiles
}

changed = [name for name in wanted if font_name(profiles[name].get("Font")) != FONT]
if not changed:
    sys.exit(0)

for name in changed:
    profile = profiles[name]
    profile["Font"] = archived_font(FONT, font_size(profile.get("Font")))

# `defaults write` cannot safely pass binary Font blobs; import the full domain
# through stdin instead.
prefs["Window Settings"] = profiles
subprocess.run(
    [DEFAULTS, "import", DOMAIN, "-"],
    input=plistlib.dumps(prefs, fmt=plistlib.FMT_XML),
    check=True,
)

print(f"Terminal.app: set {', '.join(sorted(changed))} to {FONT}", file=sys.stderr)

if subprocess.run(["/usr/bin/pgrep", "-qx", "Terminal"]).returncode == 0:
    print(
        "Terminal.app: running, and it rewrites its preferences on quit -- "
        "quit and reopen it for this to stick.",
        file=sys.stderr,
    )
