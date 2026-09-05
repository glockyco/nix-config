{
  hostName,
  lib,
  nix,
  tailscale,
  writeShellApplication,
  writeText,
}:

let
  probe = writeText "tailnet-builder-probe.nix" ''
    { nonce }:
    builtins.derivation {
      name = "tailnet-builder-probe-''${nonce}";
      system = "aarch64-darwin";
      builder = "/bin/sh";
      args = [
        "-c"
        ${builtins.toJSON ''
          set -eu
          {
            /usr/bin/uname -m
            /bin/hostname -s
          } > "$out"
        ''}
      ];
    }
  '';
in
writeShellApplication {
  name = "tailnet-builder-check";

  runtimeInputs = [
    nix
    tailscale
  ];

  text = ''
    expected_host=${lib.escapeShellArg hostName}

    # A unique derivation prevents a cached output from satisfying this live
    # proof. --rebuild cannot check a Darwin derivation on the Linux client.
    export TAILNET_BUILDER_PROBE_NONCE="''${EPOCHREALTIME//./-}-$$-$RANDOM"
    result=$(nix build \
      --impure \
      --no-link \
      --print-out-paths \
      --expr 'import ${probe} {
        nonce = builtins.getEnv "TAILNET_BUILDER_PROBE_NONCE";
      }')

    mapfile -t probe_lines < "$result"
    if [ "''${#probe_lines[@]}" -ne 2 ]; then
      printf '%s\n' "tailnet-builder-check: expected two probe lines from $result" >&2
      exit 1
    fi

    architecture=''${probe_lines[0]}
    builder_host=''${probe_lines[1]}

    if [ "$architecture" != arm64 ]; then
      printf '%s\n' "tailnet-builder-check: expected arm64, got $architecture" >&2
      exit 1
    fi
    if [ "$builder_host" != "$expected_host" ]; then
      printf '%s\n' "tailnet-builder-check: expected $expected_host, got $builder_host" >&2
      exit 1
    fi

    printf '%s\n' "tailnet-builder-check: architecture $architecture"
    printf '%s\n' "tailnet-builder-check: builder $builder_host"

    if ! ping_output=$(tailscale ping --c 1 "$expected_host" 2>&1); then
      printf '%s\n' "$ping_output" >&2
      exit 1
    fi
    printf '%s\n' "$ping_output"
    printf '%s\n' 'tailnet-builder-check: passed'
  '';
}
