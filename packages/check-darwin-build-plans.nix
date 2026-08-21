{
  coreutils,
  gnugrep,
  jq,
  writeShellApplication,
}:

# Fails when an output this repository asks Nix to build on Darwin reaches a
# source-built .NET package or a Swift compiler.
#
# Nixpkgs publishes no `aarch64-darwin` binary for either, so a build plan that
# reaches one compiles both toolchains. That is not a slow build, it is hours: a
# test-only dependency of one formatter tool once cost this repository five of
# them.
#
# This is an app rather than a `nix flake check` derivation because a check runs
# in a sandbox with no store access, and walking a derivation closure needs the
# store. `nix` therefore comes from the caller's PATH: the tool has to talk to
# the local daemon, so the system's own client is the correct one.
writeShellApplication {
  name = "check-darwin-build-plans";

  runtimeInputs = [
    coreutils
    gnugrep
    jq
  ];

  text = ''
    if [ ! -f flake.nix ]; then
      echo "check-darwin-build-plans: run this from the repository root." >&2
      exit 64
    fi

    if ! command -v nix >/dev/null 2>&1; then
      echo "check-darwin-build-plans: nix is required and is not on PATH." >&2
      exit 127
    fi

    system="$(nix eval --raw --impure --expr builtins.currentSystem)"

    case "$system" in
      *-darwin) ;;
      *)
        echo "check-darwin-build-plans: skipped on $system."
        echo "Nixpkgs caches these toolchains there, so a plan that names one costs nothing."
        exit 0
        ;;
    esac

    # Matches the source-built .NET packages and the Swift compiler by
    # derivation name. Task 4.4's controls below prove the pattern still bites.
    pattern='-(dotnet-vmr|dotnet-stage0-vmr|swift)-[0-9]'

    # The controls need the Nixpkgs this repository pins. Read it from the lock
    # rather than evaluating the flake from inside itself: `builtins.getFlake`
    # on a Git reference wants `revCount`, and a CI checkout is shallow.
    # Interpolating the derivations at build time is worse still, because the
    # store then has to hold their input closures, which is gigabytes.
    nixpkgs_type="$(jq -r '.nodes.nixpkgs.locked.type' flake.lock)"

    case "$nixpkgs_type" in
      tarball)
        nixpkgs="tarball+$(jq -r '.nodes.nixpkgs.locked.url' flake.lock)"
        ;;
      *)
        echo "check-darwin-build-plans: the nixpkgs lock entry is of type '$nixpkgs_type'." >&2
        echo "This app cannot turn that into a flake reference. Teach it the new form" >&2
        echo "rather than leaving the controls unchecked." >&2
        exit 1
        ;;
    esac

    hits() {
      # `--` because the pattern starts with a dash.
      nix-store --query --requisites "$1" 2>/dev/null | grep -E -- "$pattern" || true
    }

    # A detector that silently stops matching is worse than no detector, because
    # it reports success forever. Prove it still recognises the two toolchains
    # before trusting anything it says about this repository.
    controls_failed=0
    for control in dotnetCorePackages.sdk_8_0 swift; do
      control_drv="$(nix eval --raw "$nixpkgs#legacyPackages.$system.$control.drvPath")"

      if [ -z "$(hits "$control_drv")" ]; then
        echo "control failed: $control no longer matches the detection pattern." >&2
        controls_failed=1
      fi
    done

    if [ "$controls_failed" -ne 0 ]; then
      echo "" >&2
      echo "The pattern no longer recognises a known source build, so a pass here would prove nothing." >&2
      echo "An upstream rename is the usual cause. Update the pattern in packages/check-darwin-build-plans.nix." >&2
      exit 1
    fi

    # Read the output names from the flake rather than a list kept here, so an
    # output added later is covered without editing this file.
    violations=0
    checked=0
    for group in checks packages devShells; do
      attrs="$(nix eval --json ".#$group.$system" --apply builtins.attrNames)"

      for attr in $(printf '%s' "$attrs" | jq -r '.[]'); do
        checked=$((checked + 1))
        drv="$(nix eval --raw ".#$group.$system.$attr.drvPath")"
        offenders="$(hits "$drv")"

        if [ -n "$offenders" ]; then
          violations=1
          offender="$(printf '%s\n' "$offenders" | head -1)"

          echo "" >&2
          echo "$group.$system.$attr reaches $(basename "$offender")" >&2
          nix why-depends --derivation ".#$group.$system.$attr" "$offender" 2>/dev/null \
            | grep -v '^warning' >&2 || true
        fi
      done
    done

    if [ "$violations" -ne 0 ]; then
      echo "" >&2
      echo "These outputs compile a .NET SDK or a Swift toolchain from source on Darwin." >&2
      echo "Point the dependency at a fixed-output binary, as packages/personal-omp.nix does." >&2
      exit 1
    fi

    if [ "$checked" -eq 0 ]; then
      echo "check-darwin-build-plans: read no outputs, so this run proved nothing." >&2
      exit 1
    fi

    echo "check-darwin-build-plans: $checked outputs, none reaching a source-built .NET package or Swift compiler."
  '';
}
