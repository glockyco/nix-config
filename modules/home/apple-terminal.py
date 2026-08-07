"""Point Terminal.app's active profiles at a Nerd Font.

Terminal.app stores each profile's font as an NSKeyedArchiver blob, which is why
this cannot be a plain `defaults write` or a nix-darwin `system.defaults` entry.
Only the face is replaced; the size already chosen in each profile is kept.
"""

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


# Absolute paths: Home Manager activation runs with a minimal PATH that has no
# /usr/bin on it.
DEFAULTS = "/usr/bin/defaults"

prefs = plistlib.loads(
    subprocess.run(
        [DEFAULTS, "export", DOMAIN, "-"], capture_output=True, check=True
    ).stdout
)
profiles = prefs.get("Window Settings", {})

# Only the profiles Terminal actually opens with. Leaving the rest alone keeps
# the stock themes (Novel's Courier, Homebrew's Andale Mono) as they were.
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

# Round-tripping the whole domain through `defaults import` rather than writing
# one key: `defaults write` has no stdin form and would need the plist as an
# argv string, which its old-style parser mangles on the binary Font blobs.
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
