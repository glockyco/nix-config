{
  coreutils,
  gnugrep,
  runCommand,
  runtimeShell,
  wslOpen,
}:

runCommand "check-wsl-open-command"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
    ];
  }
  ''
    fixture=$TMPDIR/fixture
    mkdir -p "$fixture"

    cat > "$fixture/wslpath" <<'EOF'
    #!${runtimeShell}
    set -eu
    : > "$WSLPATH_CALLS"
    for argument in "$@"; do
      printf '<%s>\n' "$argument" >> "$WSLPATH_CALLS"
    done
    if [ "''${WSLPATH_FAIL:-0}" -eq 1 ]; then
      exit 23
    fi
    printf '%s\n' 'C:\translated target'
    EOF
    chmod +x "$fixture/wslpath"

    cat > "$fixture/explorer.exe" <<'EOF'
    #!${runtimeShell}
    set -eu
    printf '%s\n' "$#" > "$EXPLORER_COUNT"
    : > "$EXPLORER_CALLS"
    for argument in "$@"; do
      printf '<%s>\n' "$argument" >> "$EXPLORER_CALLS"
    done
    exit "''${EXPLORER_STATUS:-0}"
    EOF
    chmod +x "$fixture/explorer.exe"

    run_open() {
      PATH="$fixture" \
        WSLPATH_CALLS="$TMPDIR/wslpath.calls" \
        EXPLORER_COUNT="$TMPDIR/explorer.count" \
        EXPLORER_CALLS="$TMPDIR/explorer.calls" \
        EXPLORER_STATUS="''${EXPLORER_STATUS:-0}" \
        ${wslOpen}/bin/open "$@"
    }

    run_failure() {
      expected_status=$1
      expected_error=$2
      shift 2
      set +e
      run_open "$@" > "$TMPDIR/failure.stdout" 2> "$TMPDIR/failure.stderr"
      status=$?
      set -e
      test "$status" -eq "$expected_status"
      grep -qF "$expected_error" "$TMPDIR/failure.stderr"
    }

    current=$TMPDIR/current
    mkdir -p "$current"
    (
      cd "$current"
      run_open
    )
    test "$(cat "$TMPDIR/wslpath.calls")" = "$(printf '%s\n' '<-aw>' '<-->' '<.>')"
    test "$(cat "$TMPDIR/explorer.count")" -eq 1
    test "$(cat "$TMPDIR/explorer.calls")" = '<C:\translated target>'

    metachar_target="$TMPDIR/path with spaces & \$(touch SHOULD_NOT_EXIST)"
    touch "$metachar_target"
    run_open "$metachar_target"
    test "$(cat "$TMPDIR/wslpath.calls")" = "$(printf '%s\n' '<-aw>' '<-->' "<$metachar_target>")"
    test "$(cat "$TMPDIR/explorer.count")" -eq 1
    test "$(cat "$TMPDIR/explorer.calls")" = '<C:\translated target>'
    test ! -e "$TMPDIR/SHOULD_NOT_EXIST"

    mv "$fixture/wslpath" "$TMPDIR/wslpath"
    run_open 'https://example.com/a?x=1&y=2'
    test "$(cat "$TMPDIR/explorer.count")" -eq 1
    test "$(cat "$TMPDIR/explorer.calls")" = '<https://example.com/a?x=1&y=2>'

    EXPLORER_STATUS=1 run_open 'https://example.com/dispatched'
    test "$(cat "$TMPDIR/explorer.calls")" = '<https://example.com/dispatched>'

    set +e
    EXPLORER_STATUS=126 run_open 'https://example.com/execution-failed'
    status=$?
    set -e
    test "$status" -eq 126

    mv "$TMPDIR/wslpath" "$fixture/wslpath"

    : > "$TMPDIR/explorer.calls"
    run_failure 64 'open: expected zero or one target' one two
    test ! -s "$TMPDIR/explorer.calls"

    run_failure 66 'open: target does not exist and is not an absolute URI: missing target' 'missing target'
    test ! -s "$TMPDIR/explorer.calls"

    mv "$fixture/wslpath" "$TMPDIR/wslpath"
    run_failure 69 'open: WSL path translation is unavailable (wslpath not found)' "$metachar_target"
    test ! -s "$TMPDIR/explorer.calls"
    mv "$TMPDIR/wslpath" "$fixture/wslpath"

    set +e
    PATH="$fixture" \
      WSLPATH_FAIL=1 \
      WSLPATH_CALLS="$TMPDIR/wslpath.calls" \
      EXPLORER_COUNT="$TMPDIR/explorer.count" \
      EXPLORER_CALLS="$TMPDIR/explorer.calls" \
      ${wslOpen}/bin/open "$metachar_target" > "$TMPDIR/translation.stdout" 2> "$TMPDIR/translation.stderr"
    status=$?
    set -e
    test "$status" -eq 69
    grep -qF 'open: could not translate WSL path:' "$TMPDIR/translation.stderr"
    test ! -s "$TMPDIR/explorer.calls"

    mv "$fixture/explorer.exe" "$TMPDIR/explorer.exe"
    run_failure 69 'open: Windows executable interoperation is unavailable (explorer.exe not found)' "$metachar_target"
    mv "$TMPDIR/explorer.exe" "$fixture/explorer.exe"

    touch $out
  ''
