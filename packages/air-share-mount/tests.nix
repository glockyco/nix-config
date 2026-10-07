{ air-share-mount, runCommand }:
runCommand "check-air-share-mount" { } ''
  set -eu
  command=${air-share-mount}/bin/air-share-mount
  cat > tailscale-double <<'SH'
  #!/bin/sh
  printf '%s\n' tailscale >> "$CALLS"
  test "$*" = 'status --json'
  test "''${TAILSCALE_FAIL:-0}" = 0 || exit 9
  cat "$STATUS"
  SH
  cat > osascript-double <<'SH'
  #!/bin/sh
  printf '%s\n' "$*" >> "$CALLS"
  exit "''${MOUNT_FAIL:-0}"
  SH
  chmod +x tailscale-double osascript-double
  export AIR_SHARE_TAILSCALE="$PWD/tailscale-double"
  export AIR_SHARE_OSASCRIPT="$PWD/osascript-double"
  export CALLS="$PWD/calls" STATUS="$PWD/status.json"
  url='smb://fixture-user@fixture-air/Fixture%20HD'
  mkdir mounted
  "$command" "$PWD/mounted" "$url" fixture-air
  test ! -e calls
  printf '%s\n' '{"Peer":{"one":{"HostName":"fixture-air","Online":false}}}' > "$STATUS"
  "$command" "$PWD/absent" "$url" fixture-air
  test "$(cat calls)" = tailscale
  : > calls
  printf '%s\n' '{"Peer":{"one":{"HostName":"other","Online":true}}}' > "$STATUS"
  "$command" "$PWD/absent" "$url" fixture-air
  test "$(cat calls)" = tailscale
  : > calls
  TAILSCALE_FAIL=1 "$command" "$PWD/absent" "$url" fixture-air
  test "$(cat calls)" = tailscale
  : > calls
  printf '%s\n' '{"Peer":{"one":{"HostName":"fixture-air","Online":true}}}' > "$STATUS"
  "$command" "$PWD/absent" "$url" fixture-air
  test "$(wc -l < calls)" -eq 2
  grep -Fx -- "-e mount volume \"$url\"" calls
  if MOUNT_FAIL=7 "$command" "$PWD/absent" "$url" fixture-air; then exit 1; else test "$?" -eq 7; fi
  if "$command"; then exit 1; else test "$?" -eq 64; fi
  touch "$out"
''
