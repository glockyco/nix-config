{
  callPackage,
  coreutils,
  gawk,
  gnugrep,
  runCommand,
  runtimeShell,
}:

let
  command = callPackage ./package.nix { };
in
runCommand "check-power-settings"
  {
    nativeBuildInputs = [
      coreutils
      gawk
      gnugrep
    ];
  }
  ''
    # Captured from `pmset -g custom` on an Apple silicon Mac.
    cat > pmset.custom <<'EOF'
    Battery Power:
     Sleep On Power Button 1
     powermode            1
     standby              1
     ttyskeepawake        1
     hibernatemode        3
     powernap             1
     hibernatefile        /var/vm/sleepimage
     displaysleep         15
     womp                 0
     networkoversleep     0
     sleep                1
     lessbright           1
     tcpkeepalive         1
     disksleep            10
    AC Power:
     Sleep On Power Button 1
     powermode            2
     standby              1
     ttyskeepawake        1
     hibernatemode        3
     powernap             1
     hibernatefile        /var/vm/sleepimage
     displaysleep         10
     womp                 1
     networkoversleep     0
     sleep                0
     tcpkeepalive         1
     disksleep            10
    EOF
    cat > pmset <<'EOF'
    #!${runtimeShell}
    set -eu
    printf '%s\n' "$*" >> "$PMSET_CALLS"
    if [ "$*" = '-g custom' ]; then
      if [ "''${PMSET_FAIL:-}" = read ]; then
        printf '%s\n' 'pmset read failed' >&2
        exit 28
      fi
      cat "$PMSET_FIXTURE"
    elif [ "''${PMSET_FAIL:-}" = write ]; then
      printf '%s\n' 'pmset write failed' >&2
      exit 29
    else
      case "$*" in
        '-c sleep 0 displaysleep 10'|'-b sleep 1 displaysleep 15') ;;
        *) printf 'unexpected pmset write: %s\n' "$*" >&2; exit 30 ;;
      esac
    fi
    EOF
    chmod +x pmset
    export POWER_SETTINGS_PMSET=$PWD/pmset PMSET_CALLS=$PWD/pmset.calls PMSET_FIXTURE=$PWD/pmset.custom
    run_case() {
      ${command}/bin/power-settings -c sleep 0 displaysleep 10 -b sleep 1 displaysleep 15 > command.stdout 2> command.stderr
    }

    : > pmset.calls
    run_case
    test ! -s command.stdout
    test "$(cat pmset.calls)" = '-g custom'
    grep -qFx 'power-settings: AC current' command.stderr
    grep -qFx 'power-settings: battery current' command.stderr

    awk '/Battery Power:/ { battery = 1 } /AC Power:/ { battery = 0 } battery && $1 == "sleep" { $2 = 2 } { print }' pmset.custom > battery-different
    export PMSET_FIXTURE=$PWD/battery-different
    : > pmset.calls
    run_case
    test "$(cat pmset.calls)" = "$(printf '%s\n' '-g custom' '-b sleep 1 displaysleep 15')"
    grep -qFx 'power-settings: AC current' command.stderr
    grep -qFx 'power-settings: battery changed: sleep 1 displaysleep 15' command.stderr

    awk '/Battery Power:/ { battery = 1 } /AC Power:/ { battery = 0 } !battery && $1 == "displaysleep" { $2 = 20 } { print }' pmset.custom > ac-different
    export PMSET_FIXTURE=$PWD/ac-different
    : > pmset.calls
    run_case
    test "$(cat pmset.calls)" = "$(printf '%s\n' '-g custom' '-c sleep 0 displaysleep 10')"
    grep -qFx 'power-settings: AC changed: sleep 0 displaysleep 10' command.stderr
    grep -qFx 'power-settings: battery current' command.stderr

    : > pmset.calls
    if PMSET_FAIL=write run_case; then
      printf '%s\n' 'unexpected pmset write success' >&2
      exit 1
    else
      test "$?" -eq 29
    fi
    test "$(cat pmset.calls)" = "$(printf '%s\n' '-g custom' '-c sleep 0 displaysleep 10')"
    grep -qF 'pmset write failed' command.stderr
    if PMSET_FAIL=read run_case; then
      printf '%s\n' 'unexpected pmset read success' >&2
      exit 1
    else
      test "$?" -eq 1
    fi
    test "$(cat pmset.calls)" = "$(printf '%s\n' '-g custom' '-c sleep 0 displaysleep 10' '-g custom')"
    grep -qF 'could not read pmset -g custom' command.stderr

    printf '%s\n' 'AC Power:' ' sleep 0' > incomplete
    export PMSET_FIXTURE=$PWD/incomplete
    : > pmset.calls
    if run_case; then
      printf '%s\n' 'unexpected success with incomplete pmset data' >&2
      exit 1
    else
      test "$?" -eq 1
    fi
    test "$(cat pmset.calls)" = '-g custom'
    grep -qF 'missing AC or battery sleep settings' command.stderr

    touch "$out"
  ''
