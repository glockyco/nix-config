{
  darwin-switch,
  lib,
  runCommand,
}:
runCommand "check-darwin-switch-command" { } ''
  set -eu
  command=${darwin-switch}/bin/darwin-switch
  export EXPECTED_CHECKOUT=${
    lib.escapeShellArg (
      if darwin-switch.configurationCheckout == null then
        "/fixture/checkout"
      else
        darwin-switch.configurationCheckout
    )
  }
  mkdir doubles
  cat > doubles/rebuild <<'SH'
  #!/bin/sh
  printf 'switch %s\n' "$*" >> "$CALLS"
  test "$*" = "switch --flake $EXPECTED_CHECKOUT --show-trace"
  test "''${SWITCH_FAIL:-0}" = 0 || exit 7
  printf '%s\n' /new-system > "$GENERATION"
  SH
  cat > doubles/sudo <<'SH'
  #!/bin/sh
  printf '%s\n' sudo >> "$CALLS"
  exec "$@"
  SH
  cat > doubles/readlink <<'SH'
  #!/bin/sh
  test "$*" = '-f /run/current-system'
  cat "$GENERATION"
  SH
  cat > doubles/chezmoi <<'SH'
  #!/bin/sh
  if [ "$*" = source-path ]; then
    printf '%s/home\n' "$EXPECTED_CHECKOUT"
    exit 0
  fi
  test "$(id -u)" -ne 0
  test "$*" = apply
  printf '%s\n' apply >> "$CALLS"
  test "$(cat "$GENERATION")" = /new-system
  case "$PATH" in /etc/profiles/per-user/*/bin:/run/current-system/sw/bin:*) ;; *) exit 99 ;; esac
  exit "''${APPLY_FAIL:-0}"
  SH
  cat > doubles/nvd <<'SH'
  #!/bin/sh
  test "$*" = 'diff /old-system /new-system'
  printf '%s\n' diff >> "$CALLS"
  SH
  chmod +x doubles/*
  export PATH="$PWD/doubles:$PATH"
  export CALLS="$PWD/calls" GENERATION="$PWD/generation"
  export DARWIN_SWITCH_REBUILD="$PWD/doubles/rebuild"
  export DARWIN_SWITCH_SUDO="$PWD/doubles/sudo"
  export DARWIN_SWITCH_READLINK="$PWD/doubles/readlink"
  export DARWIN_SWITCH_NVD="$PWD/doubles/nvd"
  printf '%s\n' /old-system > "$GENERATION"
  "$command" --show-trace
  test "$(cat calls)" = "$(printf '%s\n' sudo "switch switch --flake $EXPECTED_CHECKOUT --show-trace" apply diff)"
  : > calls
  "$command" --show-trace > unchanged
  grep -Fx 'darwin-switch: closure unchanged' unchanged
  test "$(wc -l < calls)" -eq 3
  : > calls
  if SWITCH_FAIL=1 "$command" --show-trace > stdout 2> stderr; then exit 1; else test "$?" -eq 7; fi
  test "$(wc -l < calls)" -eq 2
  grep -F 'user apply was not run' stderr
  : > calls
  if APPLY_FAIL=9 "$command" --show-trace > stdout 2> stderr; then exit 1; else test "$?" -eq 9; fi
  test "$(wc -l < calls)" -eq 3
  grep -F 'user apply failed after system switch' stderr
  touch "$out"
''
