#!/usr/bin/env bash
set -euo pipefail

"$check" "$modules"
"$check" "$flakeModules"
touch "$out"
