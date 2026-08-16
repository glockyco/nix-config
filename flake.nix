{
  description = "Apple Silicon workstation: Determinate Nix + nix-darwin + Home Manager";

  inputs = {
    # Pin nixpkgs to 26.05 to keep nix-darwin and Home Manager on the same release.
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2605";

    nix-darwin = {
      url = "https://flakehub.com/f/nix-darwin/nix-darwin/0.2605";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "https://flakehub.com/f/nix-community/home-manager/0.2605";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Determinate owns `/etc/nix/nix.conf`; coordinate it with nix-darwin through this module.
    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";

      # flake-parts consumes nixpkgs-lib rather than nixpkgs; follow the pinned library explicitly.
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Do not set `inputs.nixpkgs.follows`: upstream pins nixpkgs-unstable for its packages and cache.
    # Overriding it breaks cache hits and is unsupported on this stable release branch.
    llm-agents.url = "github:numtide/llm-agents.nix";

    # Personal OMP behavior has its own release cadence and immutable plugin output.
    personal-omp-plugin = {
      url = "github:glockyco/omp-agent-setup";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.llm-agents.follows = "llm-agents";
    };

    # Include upstream Karabiner rules, including the Neo2 group from `neo-layout.org/Einrichtung/macOS/`.
    karabiner-complex-modifications = {
      url = "github:pqrs-org/KE-complex_modifications";
      flake = false;
    };
  };

  outputs =
    inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
        "x86_64-linux"
      ];

      imports = [ inputs.treefmt-nix.flakeModule ];

      flake = {
        darwinConfigurations.macbook-pro = import ./hosts/macbook-pro { inherit inputs; };

        overlays.default = final: _prev: {
          neo-keyboard-layouts = final.callPackage ./packages/neo-keyboard-layouts.nix { };
        };
      };

      perSystem =
        {
          config,
          lib,
          system,
          ...
        }:
        let
          isDarwin = system == "aarch64-darwin";

          # Reuse the package set nix-darwin already instantiated for the system, so
          # the other outputs cannot drift from it and nixpkgs is evaluated once.
          pkgs =
            if isDarwin then
              self.darwinConfigurations.macbook-pro.pkgs
            else
              inputs.nixpkgs.legacyPackages.${system}.extend self.overlays.default;

          llmAgents = inputs.llm-agents.packages.${system};
          openspec = llmAgents.openspec;
          personalOmp = pkgs.callPackage ./packages/personal-omp.nix {
            inherit (llmAgents) herdr omp;
            plugin = inputs.personal-omp-plugin.packages.${system}.default;
          };
        in
        {
          # `nix fmt` formats every language listed in ./treefmt.nix, tree-wide.
          # Fail the check when any tracked file is unformatted.
          treefmt = import ./treefmt.nix pkgs;

          # flake-parts' default package set does not include this flake's overlay.
          # Use the Darwin package set above, or extend the per-system package set on Linux.
          _module.args.pkgs = pkgs;

          packages = {
            inherit (pkgs) neo-keyboard-layouts;
            inherit openspec;
            personal-omp = personalOmp;
          }
          // lib.optionalAttrs isDarwin {
            # Expose pinned `darwin-rebuild` for the first activation, before it is on PATH:
            #   sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
            inherit (inputs.nix-darwin.packages.${system}) darwin-rebuild;
          };

          checks = {
            # An unimported module is absent rather than an error.
            # Assert every module is reachable from its sibling `default.nix`.
            moduleImports = pkgs.runCommand "check-module-imports" { } ''
              cd ${./modules}
              missing=
              for dir in */; do
                for f in "$dir"*.nix; do
                  base=''${f#"$dir"}
                  if [ "$base" != default.nix ] && ! grep -qF "./$base" "$dir/default.nix"; then
                    missing="$missing $f"
                  fi
                done
              done
              if [ -n "$missing" ]; then
                echo "not imported by their sibling default.nix:$missing" >&2
                exit 1
              fi
              touch $out
            '';

            personalOmpShape =
              pkgs.runCommand "check-personal-omp-shape"
                {
                  nativeBuildInputs = [ pkgs.jq ] ++ personalOmp.languageServers;
                }
                ''
                  test -x ${personalOmp}/bin/omp
                  grep -qF -- ${lib.escapeShellArg (lib.getExe llmAgents.omp)} ${personalOmp}/bin/omp
                  grep -qF -- ${lib.escapeShellArg "--plugin-dir ${personalOmp.plugin}"} ${personalOmp}/bin/omp
                  grep -qF -- ${lib.escapeShellArg "--extension ${personalOmp.plugin}"} ${personalOmp}/bin/omp
                  ! grep -qF /Users/ ${personalOmp}/bin/omp

                  test "$(jq -r '.omp.extensions | length' ${personalOmp.plugin}/package.json)" = 1
                  test "$(jq -r '.servers | keys | sort | join(",")' ${personalOmp.plugin}/lsp.json)" = roslyn-language-server,svelte

                  command -v Microsoft.CodeAnalysis.LanguageServer
                  command -v pyright-langserver
                  command -v typescript-language-server
                  command -v svelteserver
                  command -v nixd
                  command -v marksman
                  command -v texlab
                  test "$(${lib.getExe openspec} --version)" = "${openspec.version}"
                  touch $out
                '';

            personalOmpVerification = pkgs.runCommand "check-personal-omp-verification" { } ''
              omp_stub=$TMPDIR/omp-stub
              cat > "$omp_stub" <<'EOF'
              #!${pkgs.runtimeShell}
              printf '%s\n' "$*" > "$OMP_CALLS"
              printf '%s\n' '17.2.15'
              EOF
              chmod +x "$omp_stub"

              herdr_stub=$TMPDIR/herdr-stub
              cat > "$herdr_stub" <<'EOF'
              #!${pkgs.runtimeShell}
              printf '%s\n' "$*" > "$HERDR_CALLS"
              printf '%s\n' "''${STATUS:-omp: current (v8)}"
              EOF
              chmod +x "$herdr_stub"

              export OMP_BIN="$omp_stub"
              export HERDR_BIN="$herdr_stub"
              export OMP_CALLS=$TMPDIR/omp.calls
              export HERDR_CALLS=$TMPDIR/herdr.calls
              ${lib.getExe personalOmp.verifyPersonalOmp} > $TMPDIR/output

              test "$(cat "$OMP_CALLS")" = "--plugin-dir ${personalOmp.plugin} --extension ${personalOmp.plugin} --version"
              test "$(cat "$HERDR_CALLS")" = "integration status"
              grep -qF 'OMP: 17.2.15' $TMPDIR/output
              grep -qF 'Plugin: ${personalOmp.plugin}' $TMPDIR/output
              grep -qF 'omp: current (v8)' $TMPDIR/output

              if STATUS='omp: outdated (v7)' ${lib.getExe personalOmp.verifyPersonalOmp} >/dev/null 2>&1; then
                echo 'verification accepted an outdated Herdr integration' >&2
                exit 1
              fi

              touch $out
            '';

            herdrOmpReconciliation = pkgs.runCommand "check-herdr-omp-reconciliation" { } ''
              stub=$TMPDIR/herdr-stub
              cat > "$stub" <<'EOF'
              #!${pkgs.runtimeShell}
              printf '%s\n' "$*" >> "$CALLS"
              if [ "$1 $2" = "integration status" ]; then
                printf '%s\n' "''${STATUS:-}"
              elif [ "$1 $2 $3" = "integration install omp" ]; then
                mkdir -p "$OMP_AGENT_DIR/extensions"
                touch "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"
              fi
              EOF
              chmod +x "$stub"
              export HERDR_BIN="$stub"

              export OMP_AGENT_DIR=$TMPDIR/missing/agent
              export CALLS=$TMPDIR/missing.calls
              ${lib.getExe personalOmp.reconcileHerdrOmp}
              test "$(cat "$CALLS")" = "integration install omp"
              test -f "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"

              export OMP_AGENT_DIR=$TMPDIR/current/agent
              mkdir -p "$OMP_AGENT_DIR/extensions"
              touch "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"
              export CALLS=$TMPDIR/current.calls
              STATUS= ${lib.getExe personalOmp.reconcileHerdrOmp}
              test "$(cat "$CALLS")" = "integration status --outdated-only"

              export OMP_AGENT_DIR=$TMPDIR/stale/agent
              mkdir -p "$OMP_AGENT_DIR/extensions"
              touch "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts"
              export CALLS=$TMPDIR/stale.calls
              STATUS='omp: outdated (v7)' ${lib.getExe personalOmp.reconcileHerdrOmp}
              test "$(cat "$CALLS")" = "integration status --outdated-only
              integration install omp"

              touch $out
            '';

            openspecContracts =
              pkgs.runCommand "check-openspec-contracts"
                {
                  nativeBuildInputs = [ openspec ];
                }
                ''
                  export CI=1
                  export HOME="$TMPDIR/home"
                  export OPENSPEC_TELEMETRY=0
                  mkdir -p "$HOME"
                  cd ${./.}
                  openspec validate --all --strict --no-interactive
                  openspec validate --archived --strict --no-interactive
                  touch $out
                '';

            openspecAdapters =
              pkgs.runCommand "check-openspec-adapters"
                {
                  nativeBuildInputs = [
                    openspec
                    pkgs.diffutils
                  ];
                }
                ''
                  export CI=1
                  export HOME="$TMPDIR/home"
                  export OPENSPEC_TELEMETRY=0
                  mkdir -p "$HOME"
                  cp -R ${./.} source
                  chmod -R u+w source
                  cd source
                  openspec update . --force
                  diff -ru ${./.}/.omp/commands .omp/commands
                  diff -ru ${./.}/.omp/skills .omp/skills
                  touch $out
                '';
          }
          // lib.optionalAttrs isDarwin {
            darwinSystem = self.darwinConfigurations.macbook-pro.system;
          };

          devShells = lib.optionalAttrs isDarwin {
            default = pkgs.mkShellNoCC {
              packages = [
                inputs.nix-darwin.packages.${system}.darwin-rebuild
                pkgs.git
                pkgs.dnscontrol

                # The interpreter comes from the pinned nixpkgs, and every
                # consumer names it independently: this shell, the `fastmail`
                # wrapper and the apple-terminal activation script. The shell
                # has to name it too rather than inherit one, because an
                # undeclared `python3` resolves to macOS's 3.9, which cannot
                # parse the `X | None` annotations these scripts use and fails
                # in a way that reads like a code bug.
                pkgs.python3

                config.treefmt.build.wrapper
              ];
            };
          };
        };
    };
}
