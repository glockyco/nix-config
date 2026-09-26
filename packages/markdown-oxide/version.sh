#!/usr/bin/env bash
set -euo pipefail

test "$(markdown-oxide --version)" = "$expectedVersion"
touch "$out"
