#!/usr/bin/env bash
set -euo pipefail

test -d "$OMP_AGENT_DIR"
printf '%s\n' "$*" >> "$CALLS"
if [ "$1 $2" = "integration status" ]; then
  printf '%s\n' "${STATUS:-}"
elif [ "$1 $2 $3" = "integration install omp" ]; then
  if [ ! -f "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts" ]; then
    test ! -e "$OMP_AGENT_DIR/extensions"
  fi
  mkdir -p "$OMP_AGENT_DIR/extensions"
  touch "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"
fi
