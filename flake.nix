{
  description = "Apple Silicon workstation: Determinate Nix + nix-darwin + Home Manager";

  # Root flakes do not inherit an input flake's cache settings. Publish the
  # llm-agents cache here so Linux installs substitute OMP instead of compiling it.
  nixConfig = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

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

      imports = [
        inputs.treefmt-nix.flakeModule
      ];

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
          isLinux = system == "x86_64-linux";

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
          personalOmpWsl = pkgs.callPackage ./packages/personal-omp-wsl.nix {
            inherit openspec personalOmp;
          };
          bootstrapOmpOnWsl = pkgs.callPackage ./packages/bootstrap-omp-on-wsl.nix {
            environment = personalOmpWsl;
          };
          bootstrapOmpOnWslTest = pkgs.callPackage ./packages/bootstrap-omp-on-wsl-tests.nix {
            inherit bootstrapOmpOnWsl;
          };
          moduleImportsCheck = pkgs.callPackage ./packages/module-imports-check.nix { };
          moduleImportsCommandTest = pkgs.callPackage ./packages/module-imports-check-tests.nix {
            inherit moduleImportsCheck;
          };
          airBatchCheck = pkgs.callPackage ./packages/air-batch-check.nix { };
          airBatchCommandTest = pkgs.callPackage ./packages/air-batch-check-tests.nix {
            inherit airBatchCheck;
          };
          airBatchConfigCheck = pkgs.callPackage ./packages/air-batch-config-check.nix {
            homeConfiguration = self.darwinConfigurations.macbook-pro.config.home-manager.users.glockyco;
          };
          containerRuntimeCheck = pkgs.callPackage ./packages/container-runtime-check.nix { };
          containerRuntimeCommandTest = pkgs.callPackage ./packages/container-runtime-check-tests.nix {
            inherit containerRuntimeCheck;
          };
          containerRuntimeConfigCheck = pkgs.callPackage ./packages/container-runtime-config-check.nix {
            inherit containerRuntimeCheck;
            homeConfiguration = self.darwinConfigurations.macbook-pro.config.home-manager.users.glockyco;
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
          // lib.optionalAttrs isLinux {
            bootstrap-omp-on-wsl = bootstrapOmpOnWsl;
            personal-omp-wsl = personalOmpWsl;
          }
          // lib.optionalAttrs isDarwin {
            # Expose pinned `darwin-rebuild` for the first activation, before it is on PATH:
            #   sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
            inherit (inputs.nix-darwin.packages.${system}) darwin-rebuild;

            # Walks build plans, so it needs the store and cannot be a check.
            #   nix run .#check-darwin-build-plans
            check-darwin-build-plans = pkgs.callPackage ./packages/check-darwin-build-plans.nix { };
            air-batch-check = airBatchCheck;
            container-runtime-check = containerRuntimeCheck;
          };

          apps = lib.optionalAttrs isLinux {
            bootstrap-omp-on-wsl = {
              type = "app";
              program = lib.getExe bootstrapOmpOnWsl;
            };
          };

          checks = {
            # An unimported module is absent rather than an error.
            # Assert every module is reachable from its sibling `default.nix`.
            moduleImports = pkgs.runCommand "check-module-imports" { } ''
              ${lib.getExe moduleImportsCheck} ${./modules}
              touch $out
            '';

            # Prove that the check above can reject, so an empty result means
            # something.
            moduleImportsCommand = moduleImportsCommandTest;

            wslOmpEnvironment = pkgs.runCommand "check-personal-omp-wsl-environment" { } ''
              commands=
              for command in ${personalOmpWsl}/bin/*; do
                commands="$commands $(basename "$command")"
              done
              test "$commands" = " omp openspec reconcile-herdr-omp verify-personal-omp"
              test "$(readlink -f ${personalOmpWsl}/bin/omp)" = "$(readlink -f ${personalOmp}/bin/omp)"
              test "$(readlink -f ${personalOmpWsl}/bin/openspec)" = "$(readlink -f ${openspec}/bin/openspec)"
              test "$(readlink -f ${personalOmpWsl}/bin/reconcile-herdr-omp)" = "$(readlink -f ${personalOmp.reconcileHerdrOmp}/bin/reconcile-herdr-omp)"
              test "$(readlink -f ${personalOmpWsl}/bin/verify-personal-omp)" = "$(readlink -f ${personalOmp.verifyPersonalOmp}/bin/verify-personal-omp)"
              touch $out
            '';

            bootstrapOmpOnWslCommand = bootstrapOmpOnWslTest;

            personalOmpShape =
              pkgs.runCommand "check-personal-omp-shape"
                {
                  nativeBuildInputs = [ pkgs.jq ] ++ personalOmp.languageServers;
                }
                ''
                  test -x ${personalOmp}/bin/omp
                  grep -qF -- ${lib.escapeShellArg (lib.getExe llmAgents.omp)} ${personalOmp}/bin/omp
                  grep -qF -- ${lib.escapeShellArg "--extension ${personalOmp.plugin}"} ${personalOmp}/bin/omp
                  grep -qF -- ${lib.escapeShellArg "--plugin-dir ${personalOmp.plugin}/lsp"} ${personalOmp}/bin/omp
                  ! grep -qF /Users/ ${personalOmp}/bin/omp

                  test "$(jq -r '.omp.extensions | length' ${personalOmp.plugin}/package.json)" = 1
                  test "$(jq -r '.servers | keys | sort | join(",")' ${personalOmp.plugin}/lsp/lsp.json)" = roslyn-language-server,svelte

                  # The workflow commands ship in the payload, and the LSP root
                  # must stay free of them so they register exactly once.
                  test -f ${personalOmp.plugin}/commands/opsx-propose.md
                  test ! -e ${personalOmp.plugin}/lsp/commands

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

              test "$(cat "$OMP_CALLS")" = "--extension ${personalOmp.plugin} --plugin-dir ${personalOmp.plugin}/lsp --version"
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
              test -d "$OMP_AGENT_DIR"
              printf '%s\n' "$*" >> "$CALLS"
              if [ "$1 $2" = "integration status" ]; then
                printf '%s\n' "''${STATUS:-}"
              elif [ "$1 $2 $3" = "integration install omp" ]; then
                if [ ! -f "$OMP_AGENT_DIR/extensions/herdr-omp-agent-state.ts" ]; then
                  test ! -e "$OMP_AGENT_DIR/extensions"
                fi
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

            # Defined once for the whole fleet in the plugin flake, which this
            # configuration already tracks, so the workstation validates its
            # artifacts exactly as every repository does.
            openspecContracts = inputs.personal-omp-plugin.lib.openspecCheck {
              inherit pkgs;
              src = ./.;
              name = "check-openspec-contracts";
            };

          }
          // lib.optionalAttrs isDarwin {
            airBatchCommand = airBatchCommandTest;
            airBatchConfiguration = airBatchConfigCheck;
            containerRuntimeCommand = containerRuntimeCommandTest;
            containerRuntimeConfiguration = containerRuntimeConfigCheck;
            darwinSystem = self.darwinConfigurations.macbook-pro.system;
          };

          devShells = lib.optionalAttrs isDarwin {
            default = pkgs.mkShellNoCC {
              packages = [
                inputs.nix-darwin.packages.${system}.darwin-rebuild
                pkgs.git
                pkgs.dnscontrol
                pkgs.lefthook

                # The commit hook runs this wrapper through `nix develop`, and
                # `nix fmt` and `checks.treefmt` run the same one.
                config.treefmt.build.wrapper

                # The interpreter comes from the pinned nixpkgs, and every
                # consumer names it independently: this shell, the `fastmail`
                # wrapper and the apple-terminal activation script. The shell
                # has to name it too rather than inherit one, because an
                # undeclared `python3` resolves to macOS's 3.9, which cannot
                # parse the `X | None` annotations these scripts use and fails
                # in a way that reads like a code bug.
                pkgs.python3
              ];

              # Install the commit hook on entry. The grep keeps this cheap on
              # re-entry, and it also catches a hook file left behind by a
              # previous runner: that file does not mention lefthook, so
              # `--force` replaces it.
              shellHook = ''
                if ! grep -qs lefthook .git/hooks/pre-commit; then
                  ${lib.getExe pkgs.lefthook} install --force >/dev/null
                fi
              '';
            };
          };
        };
    };
}
