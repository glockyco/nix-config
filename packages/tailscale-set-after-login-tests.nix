{
  callPackage,
  coreutils,
  gnugrep,
  runCommand,
  tailscale,
  writeShellApplication,
}:

let
  fixtureTailscale = writeShellApplication {
    name = "fixture-tailscale-lifecycle";
    runtimeInputs = [ coreutils ];
    text = ''
      state_file="''${TAILSCALE_FIXTURE_STATE:?}"
      set_log="''${TAILSCALE_FIXTURE_SET_LOG:?}"

      case "$*" in
        "status --json --peers=false")
          state=$(cat "$state_file")
          state=$((state + 1))
          printf '%s\n' "$state" > "$state_file"
          if [ "$state" -eq 1 ]; then
            printf '%s\n' '{"BackendState":"NeedsLogin"}'
          else
            printf '%s\n' '{"BackendState":"Running"}'
          fi
          ;;
        "set --ssh=false")
          if [ "$(cat "$state_file")" -lt 2 ]; then
            printf '%s\n' 'set ran before authentication completed' >&2
            exit 1
          fi
          printf '%s\n' "$*" > "$set_log"
          exit "''${TAILSCALE_FIXTURE_SET_STATUS:-0}"
          ;;
        *)
          printf '%s\n' "unexpected tailscale arguments: $*" >&2
          exit 2
          ;;
      esac
    '';
  };

  command = callPackage ./tailscale-set-after-login.nix {
    tailscaleCommand = "${fixtureTailscale}/bin/fixture-tailscale-lifecycle";
  };
in
runCommand "check-tailscale-set-after-login"
  {
    nativeBuildInputs = [
      coreutils
      gnugrep
    ];
  }
  ''
    printf '%s\n' 0 > state
    : > set.log

    TAILSCALE_FIXTURE_STATE=$PWD/state \
      TAILSCALE_FIXTURE_SET_LOG=$PWD/set.log \
      timeout 5 ${command}/bin/tailscale-set-after-login --ssh=false

    grep -qFx 'set --ssh=false' set.log

    if TAILSCALE_FIXTURE_STATE=$PWD/state \
      TAILSCALE_FIXTURE_SET_LOG=$PWD/set.log \
      TAILSCALE_FIXTURE_SET_STATUS=17 \
      timeout 5 ${command}/bin/tailscale-set-after-login --ssh=false
    then
      printf '%s\n' 'a failed tailscale set unexpectedly passed' >&2
      exit 1
    else
      test "$?" = 17
    fi

    TAILSCALE_FIXTURE_STATE=$PWD/state \
      TAILSCALE_FIXTURE_SET_LOG=$PWD/set.log \
      timeout 5 ${command}/bin/tailscale-set-after-login --ssh=false

    if ${tailscale}/bin/tailscale set \
      --advertise-tags=tag:macbook-pro >unsupported.out 2>&1
    then
      printf '%s\n' 'tailscale set unexpectedly accepted --advertise-tags' >&2
      exit 1
    fi

    touch $out
  ''
