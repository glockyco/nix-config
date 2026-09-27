{
  coreutils,
  gnugrep,
  rosetta,
  runCommand,
  writeShellApplication,
}:

let
  probe = writeShellApplication {
    name = "rosetta-probe-double";
    text = ''
      printf '%s\n' "$*" >> "''${ROSETTA_PROBE_LOG:?}"
      exit "''${ROSETTA_PROBE_STATUS:-0}"
    '';
  };
  installer = writeShellApplication {
    name = "rosetta-installer-double";
    text = ''
      printf '%s\n' "$*" >> "''${ROSETTA_INSTALL_LOG:?}"
      exit "''${ROSETTA_INSTALL_STATUS:-0}"
    '';
  };
in
runCommand "check-rosetta-command"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
    ];
  }
  ''
    set -eu
    export ROSETTA_ARCH=${probe}/bin/rosetta-probe-double
    export ROSETTA_SOFTWAREUPDATE=${installer}/bin/rosetta-installer-double
    export ROSETTA_PROBE_LOG=$PWD/probe.log
    export ROSETTA_INSTALL_LOG=$PWD/install.log
    : > "$ROSETTA_PROBE_LOG"
    : > "$ROSETTA_INSTALL_LOG"

    ${rosetta}/bin/rosetta >current.out 2>current.err
    test ! -s current.out
    grep -qFx 'rosetta: current: x86_64 execution works' current.err
    grep -qFx -- '-arch x86_64 /usr/bin/true' "$ROSETTA_PROBE_LOG"
    test "$(wc -l < "$ROSETTA_PROBE_LOG")" -eq 1
    test ! -s "$ROSETTA_INSTALL_LOG"

    export ROSETTA_PROBE_STATUS=1
    ${rosetta}/bin/rosetta >changed.out 2>changed.err
    test ! -s changed.out
    grep -qFx 'rosetta: changed: installed Rosetta' changed.err
    test "$(wc -l < "$ROSETTA_PROBE_LOG")" -eq 2
    grep -qFx -- '--install-rosetta --agree-to-license' "$ROSETTA_INSTALL_LOG"
    test "$(wc -l < "$ROSETTA_INSTALL_LOG")" -eq 1

    export ROSETTA_INSTALL_STATUS=17
    if ${rosetta}/bin/rosetta >failed.out 2>failed.err; then
      printf '%s\n' 'a failed Rosetta installation unexpectedly passed' >&2
      exit 1
    else
      test "$?" -eq 17
    fi
    test ! -s failed.out
    grep -qFx 'rosetta: Rosetta installation failed' failed.err
    test "$(wc -l < "$ROSETTA_PROBE_LOG")" -eq 3
    test "$(wc -l < "$ROSETTA_INSTALL_LOG")" -eq 2
    if grep -q 'rosetta: changed:' failed.err; then
      printf '%s\n' 'a failed installation reported a change' >&2
      exit 1
    fi

    touch "$out"
  ''
