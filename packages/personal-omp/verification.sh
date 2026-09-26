#!/usr/bin/env bash
set -euo pipefail

export HOME="$TMPDIR/home with spaces"
mkdir -p "$HOME"
sed "1s|^#!/usr/bin/env python3$|#!$OMP_PYTHON|" "$VERSION_PROBE" > "$TMPDIR/version-probe.py"
sed "1s|^#!/usr/bin/env python3$|#!$OMP_PYTHON|" "$HERDR_PROBE" > "$TMPDIR/herdr-verification-probe.py"
chmod +x "$TMPDIR/version-probe.py" "$TMPDIR/herdr-verification-probe.py"
export VERSION_PROBE="$TMPDIR/version-probe.py"
export HERDR_PROBE="$TMPDIR/herdr-verification-probe.py"
python3 "$VERIFICATION_DRIVER"
touch "$out"
