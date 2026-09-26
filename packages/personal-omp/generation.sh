#!/usr/bin/env bash
set -euo pipefail

export HOME="$TMPDIR/home with spaces"
mkdir -p "$HOME"
sed "1s|^#!/usr/bin/env python3$|#!$OMP_PYTHON|" "$GENERATION_PROBE" > "$TMPDIR/generation-probe.py"
chmod +x "$TMPDIR/generation-probe.py"
export GENERATION_PROBE="$TMPDIR/generation-probe.py"
python3 "$GENERATION_DRIVER"
touch "$out"
