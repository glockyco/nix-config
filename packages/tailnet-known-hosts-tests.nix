{
  callPackage,
  coreutils,
  diffutils,
  runCommand,
  writeShellApplication,
}:

let
  fixtureTailscale = writeShellApplication {
    name = "fixture-tailscale";
    runtimeInputs = [ coreutils ];
    text = ''
      if [ "$#" -ne 2 ] || [ "$1" != status ] || [ "$2" != --json ]; then
        printf 'unexpected tailscale arguments:' >&2
        printf ' %s' "$@" >&2
        printf '\n' >&2
        exit 2
      fi
      cat "$TAILNET_STATUS_FIXTURE"
    '';
  };

  tailnetKnownHosts = callPackage ./tailnet-known-hosts.nix {
    tailscaleCommand = "${fixtureTailscale}/bin/fixture-tailscale";
  };
in
runCommand "check-tailnet-known-hosts-command"
  {
    nativeBuildInputs = [ diffutils ];
  }
  ''
    cat > matching.json <<'EOF'
    {
      "Peer": {
        "nodekey:peer": {
          "HostName": "macbook-pro",
          "DNSName": "macbook-pro.tail8768af.ts.net.",
          "sshHostKeys": [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFixtureEd25519",
            "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYFixture"
          ]
        }
      }
    }
    EOF

    cat > expected <<'EOF'
    macbook-pro ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFixtureEd25519
    macbook-pro ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYFixture
    EOF

    TAILNET_STATUS_FIXTURE=$PWD/matching.json \
      ${tailnetKnownHosts}/bin/tailnet-known-hosts macbook-pro > actual
    diff -u expected actual

    cat > expected-fqdn <<'EOF'
    macbook-pro.tail8768af.ts.net ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFixtureEd25519
    macbook-pro.tail8768af.ts.net ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYFixture
    EOF

    TAILNET_STATUS_FIXTURE=$PWD/matching.json \
      ${tailnetKnownHosts}/bin/tailnet-known-hosts macbook-pro.tail8768af.ts.net > actual-fqdn
    diff -u expected-fqdn actual-fqdn

    cat > no-keys.json <<'EOF'
    {
      "Peer": {
        "nodekey:peer": {
          "HostName": "macbook-pro",
          "DNSName": "macbook-pro.tail8768af.ts.net."
        }
      }
    }
    EOF

    if TAILNET_STATUS_FIXTURE=$PWD/no-keys.json \
      ${tailnetKnownHosts}/bin/tailnet-known-hosts macbook-pro > no-keys.out 2> no-keys.err
    then
      echo 'peer without SSH host keys unexpectedly passed' >&2
      exit 1
    fi

    cat > unknown.json <<'EOF'
    {
      "Peer": {
        "nodekey:peer": {
          "HostName": "desktop",
          "DNSName": "desktop.tail8768af.ts.net.",
          "sshHostKeys": ["ssh-ed25519 AAAAC3NzaUnknownPeer"]
        }
      }
    }
    EOF

    if TAILNET_STATUS_FIXTURE=$PWD/unknown.json \
      ${tailnetKnownHosts}/bin/tailnet-known-hosts macbook-pro > unknown.out 2> unknown.err
    then
      echo 'unknown peer name unexpectedly passed' >&2
      exit 1
    fi

    touch $out
  ''
