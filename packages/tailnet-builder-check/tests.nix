{
  callPackage,
  lib,
  runCommand,
  writeShellScriptBin,
}:
let
  fakeNix = writeShellScriptBin "nix" ''
    test -n "$TAILNET_BUILDER_PROBE_NONCE"
    printf '%s\n' "$*" > "$TEST_LOG/build"
    if [ "$BUILD_STATUS" -ne 0 ]; then exit "$BUILD_STATUS"; fi
    printf '%s\n' arm64 macbook-pro > "$TEST_LOG/probe"
    printf '%s\n' "$TEST_LOG/probe"
  '';
  nativeCli = runCommand "windows-tailscale-fixture" { } ''
    mkdir -p "$out/Program Files/Tailscale"
    cp ${lib.getExe (
      writeShellScriptBin "native-cli" ''
        printf '%s\n' "$*" > "$TEST_LOG/ping"
        printf '%s\n' "$PING_REPLY"
        exit "$PING_STATUS"
      ''
    )} "$out/Program Files/Tailscale/tailscale.exe"
  '';
  check = callPackage ./package.nix {
    hostName = "macbook-pro";
    nix = fakeNix;
    windowsTailscalePath = "${nativeCli}/Program Files/Tailscale/tailscale.exe";
  };
in
runCommand "check-tailnet-builder-behavior" { } ''
  export TEST_LOG="$TMPDIR/fixture"
  mkdir -p "$TEST_LOG"
  export BUILD_STATUS=0 PING_STATUS=0
  export PING_REPLY='pong from macbook-pro via 100.88.17.38 in 1ms'
  ${lib.getExe check} > "$TEST_LOG/output"
  test "$(cat "$TEST_LOG/ping")" = 'ping --c 1 --until-direct=false macbook-pro'
  export PING_REPLY='pong from macbook-pro via DERP(fra) in 69ms'
  ${lib.getExe check} > "$TEST_LOG/output"
  export PING_STATUS=23 PING_REPLY='native CLI failed'
  status=0
  ${lib.getExe check} > "$TEST_LOG/output" 2>&1 || status=$?
  test "$status" = 23
  export BUILD_STATUS=37
  rm "$TEST_LOG/ping"
  status=0
  ${lib.getExe check} > "$TEST_LOG/output" 2>&1 || status=$?
  test "$status" = 37
  test ! -e "$TEST_LOG/ping"
  touch "$out"
''
