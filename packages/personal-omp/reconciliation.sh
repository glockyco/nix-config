#!/usr/bin/env bash
set -euo pipefail

# Reconcile against the pinned Herdr itself. A stub only repeats the output
# format it was written for, so it cannot notice when a Herdr update changes
# how integration status is reported.

extension() {
  printf '%s\n' "$HOME/.omp/agent/extensions/herdr-omp-agent-state.ts"
}

expect_omp() {
  local report line
  report="$("$HERDR" integration status)"
  line="$(grep '^omp:' <<<"$report" || true)"
  if [[ $line != "omp: $1 "* ]]; then
    printf 'expected the OMP integration to be %s, Herdr reported: %s\n' "$1" "$line" >&2
    exit 1
  fi
}

# A user who has never launched OMP has no agent root yet.
export HOME="$TMPDIR/missing"
mkdir -p "$HOME"
expect_omp "not installed"
"$HERDR_RECONCILE"
expect_omp current

# An extension generated for an older integration version.
export HOME="$TMPDIR/stale"
mkdir -p "$HOME/.omp/agent"
"$HERDR" integration install omp
sed -i 's|^// HERDR_INTEGRATION_VERSION=[0-9]*$|// HERDR_INTEGRATION_VERSION=1|' "$(extension)"
expect_omp outdated
"$HERDR_RECONCILE"
expect_omp current

# A current extension stays exactly as Herdr generated it.
export HOME="$TMPDIR/current"
mkdir -p "$HOME/.omp/agent"
"$HERDR" integration install omp
touch -d @1 "$(extension)"
generated="$(sha256sum <"$(extension)")"
"$HERDR_RECONCILE"
test "$(sha256sum <"$(extension)")" = "$generated"
test "$(stat -c %Y "$(extension)")" = 1

touch "$out"
