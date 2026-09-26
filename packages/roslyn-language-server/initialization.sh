#!/usr/bin/env bash
set -euo pipefail

export HOME="$TMPDIR/home"
mkdir -p "$HOME"
python3 "$ROSLYN_DRIVER" Microsoft.CodeAnalysis.LanguageServer
touch "$out"
