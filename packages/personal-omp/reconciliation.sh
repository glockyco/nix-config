#!/usr/bin/env bash
set -euo pipefail

sed "1s|^#!/usr/bin/env bash$|#!$OMP_BASH_BIN|" "$HERDR_STUB" > "$TMPDIR/herdr-stub.sh"
chmod +x "$TMPDIR/herdr-stub.sh"
HERDR_STUB="$TMPDIR/herdr-stub.sh"

export HERDR_BIN="$HERDR_STUB"
export OMP_AGENT_DIR="$TMPDIR/missing/agent"
export CALLS="$TMPDIR/missing.calls"
"$HERDR_RECONCILE"
test "$(cat "$CALLS")" = "integration install omp"
test -f "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"

export OMP_AGENT_DIR="$TMPDIR/current/agent"
mkdir -p "$OMP_AGENT_DIR/extensions"
touch "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"
export CALLS="$TMPDIR/current.calls"
STATUS= "$HERDR_RECONCILE"
test "$(cat "$CALLS")" = "integration status --outdated-only"

export OMP_AGENT_DIR="$TMPDIR/stale/agent"
mkdir -p "$OMP_AGENT_DIR/extensions"
touch "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"
export CALLS="$TMPDIR/stale.calls"
STATUS='omp: outdated (v7)' "$HERDR_RECONCILE"
test "$(cat "$CALLS")" = "integration status --outdated-only
integration install omp"

touch "$out"
