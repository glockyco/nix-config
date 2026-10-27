#!/usr/bin/env bash
set -euo pipefail

if [ "$macVersion" != "$windowsVersion" ]; then
  echo "bun-bin is $macVersion, but windows/workstation.json pins Oven-sh.Bun $windowsVersion" >&2
  exit 1
fi
test "$(bun --version)" = "$macVersion"
touch "$out"
