{
  coreutils,
  flakeSource,
  gnugrep,
  jq,
  writeShellApplication,
}:

# Fails when an output this repository asks Nix to build on Darwin reaches a
# source-built .NET package, Swift compiler, Markdown Oxide application, or
# Roslyn language server.
#
# Nixpkgs publishes no `aarch64-darwin` binary for these builds, so a plan that
# reaches one compiles an application or its toolchain. That is not a slow build;
# it takes hours. A test-only dependency of one formatter tool once cost this
# repository five of them.
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
    if [ "$#" -ne 0 ]; then
      echo "usage: check-darwin-build-plans (checks its packaged flake snapshot)" >&2
      exit 64
    fi

    flake="path:${flakeSource}"

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

    # Matches the source-built toolchains and language-server applications by
    # derivation name. The controls below prove that every branch still bites.
    pattern='-(dotnet-vmr|dotnet-stage0-vmr|swift|markdown-oxide|roslyn-ls)-[0-9]'

    # Use the root input, not an unrelated Nixpkgs node in the same lock.
    # Resolve controls at runtime so this app does not retain their input closures.
    nixpkgs="$(jq -er '
      .nodes as $nodes
      | $nodes[$nodes[.root].inputs.nixpkgs].locked
      | if .type == "tarball" then
          "tarball+\(.url)?narHash=\(.narHash | @uri)"
        else
          error("check-darwin-build-plans: unsupported root nixpkgs lock type: \(.type)")
        end
    ' '${flakeSource}/flake.lock')"

    hits() {
      local requisites status
      requisites="$(nix-store --query --requisites "$1")" || return "$?"

      # Only grep's no-match status is success. Store and inspection errors fail.
      if printf '%s\n' "$requisites" | grep -E -- "$pattern"; then
        return 0
      else
        status=$?
        if [ "$status" -eq 1 ]; then
          return 0
        fi
        return "$status"
      fi
    }

    # Match each source derivation itself. A dependency from another forbidden
    # class must not hide a missing pattern, particularly in Roslyn's closure.
    controls_failed=0
    for control in \
      dotnetCorePackages.dotnet_8.vmr \
      dotnetCorePackages.dotnet_8.vmr.stage0.vmr \
      swiftPackages.swift-unwrapped \
      markdown-oxide \
      roslyn-ls; do
      control_drv="$(nix eval --raw "$nixpkgs#legacyPackages.$system.$control.drvPath")"

      if ! printf '%s\n' "''${control_drv##*/}" | grep -E -- "$pattern" >/dev/null; then
        echo "control failed: $control ($control_drv) does not match the detection pattern." >&2
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
      attrs="$(nix eval --json "$flake#$group.$system" --apply builtins.attrNames)"
      attrs="$(printf '%s' "$attrs" | jq -r '.[]')"

      for attr in $attrs; do
        checked=$((checked + 1))
        drv="$(nix eval --raw "$flake#$group.$system.$attr.drvPath")"
        offenders="$(hits "$drv")"

        if [ -n "$offenders" ]; then
          violations=1
          offender="''${offenders%%$'\n'*}"

          echo "" >&2
          echo "$group.$system.$attr reaches $(basename "$offender")" >&2
          nix why-depends --derivation "$flake#$group.$system.$attr" "$offender" >&2
        fi
      done
    done

    if [ "$violations" -ne 0 ]; then
      echo "" >&2
      echo "These outputs compile a forbidden toolchain or language server from source on Darwin." >&2
      echo "Point the dependency at an official fixed-output binary package." >&2
      exit 1
    fi

    if [ "$checked" -eq 0 ]; then
      echo "check-darwin-build-plans: read no outputs, so this run proved nothing." >&2
      exit 1
    fi

    echo "check-darwin-build-plans: $checked outputs, none reaching a forbidden source build."
  '';
}
