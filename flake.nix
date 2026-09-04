{
  description = "Apple Silicon workstation: Determinate Nix + nix-darwin + Home Manager";

  # This flake declares no `nixConfig`. Each host declares the Numtide
  # substituter and its trusted public key in system scope, and Nix ignores a
  # flake-provided key for a user who is not in `trusted-users`. A machine that
  # has neither host configuration passes both values as command-line flags.
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

    # Set `inputs.nixpkgs.follows` here, unlike `llm-agents` below. This input is
    # a module set plus one small Rust package, so following the pinned nixpkgs
    # costs a local build of that package and keeps one nixpkgs in the lock.
    # `llm-agents` ships prebuilt outputs from a cache keyed to its own nixpkgs,
    # where following would cost the cache instead.
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
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
    let
      # One place says which host lives on which system. `systems` derives from
      # it, so a supported system without a host, or a host without a gate,
      # cannot be expressed. Everything that is genuinely platform-bound reads
      # `kind` from here instead of comparing the system string again.
      hosts = {
        aarch64-darwin = {
          kind = "darwin";
          name = "macbook-pro";
        };
        x86_64-linux = {
          kind = "nixos";
          name = "korolev";
        };
      };
    in
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { withSystem, ... }:
      {
        systems = builtins.attrNames hosts;

        imports = [
          inputs.treefmt-nix.flakeModule
        ];

        flake = {
          # Each host receives the package set that `perSystem` instantiates for
          # its system. The dependency runs outward, from one package set to the
          # hosts and the outputs, rather than from the outputs into a host.
          darwinConfigurations.macbook-pro = withSystem "aarch64-darwin" (
            { pkgs, ... }:
            import ./hosts/macbook-pro {
              inherit inputs pkgs;
              inherit (hosts.aarch64-darwin) name;
            }
          );

          # The WSL host is a NixOS configuration rather than a package, so it
          # owns a host directory and a system scope like the Darwin host.
          nixosConfigurations.korolev = withSystem "x86_64-linux" (
            { pkgs, ... }:
            import ./hosts/korolev {
              inherit inputs pkgs;
              inherit (hosts.x86_64-linux) name;
            }
          );

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
            # The host that this system carries. Only an intrinsically
            # platform-bound output reads `kind`; a repository output does not.
            host = hosts.${system};
            onDarwinHost = lib.optionalAttrs (host.kind == "darwin");
            onNixosHost = lib.optionalAttrs (host.kind == "nixos");
            hostConfiguration =
              if host.kind == "darwin" then
                self.darwinConfigurations.${host.name}
              else
                self.nixosConfigurations.${host.name};

            # One package set per system, instantiated here and handed to the
            # host through `nixpkgs.pkgs`. nixpkgs is evaluated once per system,
            # and a host cannot resolve a package differently from an output.
            pkgs = inputs.nixpkgs.legacyPackages.${system}.extend self.overlays.default;

            llmAgents = inputs.llm-agents.packages.${system};
            openspec = llmAgents.openspec;
            configuredHost = hostConfiguration.config.host;
            inherit (import ./modules/shared) binaryCaches tailnetPeers;
            managedHosts = {
              macbook-pro = self.darwinConfigurations.macbook-pro.config.host;
              korolev = self.nixosConfigurations.korolev.config.host;
            };
            tailnetPolicyRenderer = pkgs.callPackage ./packages/tailnet-policy.nix { };
            tailnetPolicy = tailnetPolicyRenderer {
              inherit managedHosts;
              peers = tailnetPeers;
            };
            tailnetPolicyCheck = pkgs.callPackage ./packages/tailnet-policy-check.nix {
              inherit managedHosts tailnetPolicy tailnetPolicyRenderer;
              peers = tailnetPeers;
            };
            tailnetPolicyRejectsCheck = pkgs.callPackage ./packages/tailnet-policy-rejects.nix {
              inherit managedHosts tailnetPolicyRenderer;
              peers = tailnetPeers;
            };
            personalOmp = pkgs.callPackage ./packages/personal-omp.nix {
              inherit (configuredHost) ompRuntime;
              inherit (llmAgents) herdr;
              plugin = inputs.personal-omp-plugin.packages.${system}.default;
            };
            moduleImportsCheck = pkgs.callPackage ./packages/module-imports-check.nix { };
            moduleImportsCommandTest = pkgs.callPackage ./packages/module-imports-check-tests.nix {
              inherit moduleImportsCheck;
            };
            hostDeclarationCheck = pkgs.callPackage ./packages/host-declaration-check.nix { };
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
            windowsConfiguration = pkgs.callPackage ./modules/windows { };
            windowsConfigurationCheck = pkgs.callPackage ./packages/windows-configuration-check.nix {
              inherit windowsConfiguration;
            };

            # `nixosConfigurations.korolev` is the only `x86_64-linux` host. These
            # bindings are lazy, so the Darwin outputs never force them.
            korolevConfig = self.nixosConfigurations.korolev.config;
            korolevUser = korolevConfig.wsl.defaultUser;
            korolevHome = korolevConfig.home-manager.users.${korolevUser};
            korolevShell = korolevConfig.users.users.${korolevUser}.shell;
            ompBrowserRuntimeCheck = pkgs.callPackage ./packages/omp-browser-runtime-check.nix {
              inherit personalOmp;
              systemPath = korolevConfig.system.path;
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
              inherit openspec;
              personal-omp = personalOmp;
              tailnet-policy = tailnetPolicy;
              windows-configuration = windowsConfiguration;
            }
            // onDarwinHost {
              # `meta.platforms` is Darwin only, so `nix flake check` on the WSL
              # host refuses to evaluate this package outside this branch.
              inherit (pkgs) neo-keyboard-layouts;

              # Expose pinned `darwin-rebuild` for the first activation, before it is on PATH:
              #   sudo nix run .#darwin-rebuild -- switch --flake .#macbook-pro
              inherit (inputs.nix-darwin.packages.${system}) darwin-rebuild;

              # Walks build plans, so it needs the store and cannot be a check.
              #   nix run .#check-darwin-build-plans
              check-darwin-build-plans = pkgs.callPackage ./packages/check-darwin-build-plans.nix { };
              air-batch-check = airBatchCheck;
              container-runtime-check = containerRuntimeCheck;
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

              # Force representative declarations so option errors cannot stay
              # hidden behind Nix laziness.
              hostDeclaration = hostDeclarationCheck;

              tailnetPolicy = tailnetPolicyCheck;
              tailnetPolicyRejects = tailnetPolicyRejectsCheck;

              hostNixSettings =
                let
                  settings =
                    if host.kind == "darwin" then
                      hostConfiguration.config.determinateNix.customSettings
                    else
                      hostConfiguration.config.nix.settings;
                in
                pkgs.callPackage ./packages/host-nix-settings-check.nix {
                  inherit binaryCaches;
                  hostName = host.name;
                  settings = {
                    substituters = settings.extra-substituters;
                    trustedPublicKeys = settings.extra-trusted-public-keys;
                  };
                };

              # Structure already prevents an asymmetric surface: the shell and
              # the repository checks carry no platform condition, and `systems`
              # derives from the host table. This asserts what structure cannot,
              # so a later edit that reintroduces a condition, or a host added
              # without a table entry, fails in review. It reads other output
              # attributes only, never `checks` itself.
              fleetSurface =
                let
                  declared = lib.naturalSort (
                    builtins.attrNames self.darwinConfigurations ++ builtins.attrNames self.nixosConfigurations
                  );
                  bound = lib.naturalSort (map (entry: entry.name) (builtins.attrValues hosts));
                in
                assert self.devShells.${system} ? default;
                assert declared == bound;
                assert hostConfiguration.pkgs.stdenv.hostPlatform.system == system;
                pkgs.runCommand "check-fleet-surface" { } "touch $out";

              personalOmpShape =
                let
                  zshInit =
                    hostConfiguration.config.home-manager.users.${configuredHost.username}.programs.zsh.initContent;
                in
                assert lib.hasInfix "path=(\"/etc/profiles/per-user/${configuredHost.username}/bin\"" zshInit;
                pkgs.runCommand "check-personal-omp-shape"
                  {
                    nativeBuildInputs = [ pkgs.jq ] ++ personalOmp.languageServers;
                  }
                  ''
                    test -x ${personalOmp}/bin/omp
                    grep -qF -- ${lib.escapeShellArg personalOmp.ompExecutable} ${personalOmp}/bin/omp
                    grep -qF -- ${lib.escapeShellArg personalOmp.ompInstallCommand} ${personalOmp}/bin/omp
                    ! grep -Eq '/nix/store/[^ ]+/bin/omp' ${personalOmp}/bin/omp
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

                missing_omp=$TMPDIR/missing-omp
                if OMP_BIN="$missing_omp" ${lib.getExe personalOmp.verifyPersonalOmp} >/dev/null 2>$TMPDIR/missing.err; then
                  echo 'verification accepted a missing OMP executable' >&2
                  exit 1
                fi
                grep -qF "$missing_omp" $TMPDIR/missing.err
                grep -qF -- ${lib.escapeShellArg personalOmp.ompInstallCommand} $TMPDIR/missing.err

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

              windowsConfiguration = windowsConfigurationCheck;

            }
            // onNixosHost {
              # The host build is a check, so a host that stops building appears
              # in review rather than during activation.
              korolevSystem = korolevConfig.system.build.toplevel;

              # Keep OMP's browser mutable while supplying its foreign-binary ABI
              # from the rollback-safe NixOS generation.
              ompBrowserRuntime = ompBrowserRuntimeCheck;

              # The portable user modules have to build for Linux, not only
              # evaluate. This is the complete set that the WSL host selects.
              korolevHomeGeneration = korolevHome.home.activationPackage;

              # No other machine drives this host. It also runs endpoint data loss
              # prevention, so it holds no decryption material.
              korolevIsolation =
                assert !korolevConfig.services.openssh.enable;
                assert korolevConfig.networking.firewall.allowedTCPPorts == [ ];
                assert !(korolevConfig ? sops);
                pkgs.runCommand "check-wsl-host-isolation" { } "touch $out";

              # WSL 2 is already the virtual machine, so the runtime needs no
              # second one, and it exposes no socket another host could reach.
              # A Windows container product is not expressible here: Intune owns
              # Docker Desktop, and review covers that boundary.
              korolevContainerRuntime =
                assert korolevConfig.virtualisation.podman.enable;
                assert korolevConfig.virtualisation.podman.dockerCompat;
                assert !korolevConfig.virtualisation.podman.dockerSocket.enable;
                assert !korolevConfig.virtualisation.docker.enable;
                assert !korolevConfig.virtualisation.libvirtd.enable;
                pkgs.runCommand "check-wsl-host-container-runtime" { } "touch $out";

              # A login shell that the portable set does not configure would read
              # none of its own configuration, because that set generates no bash
              # files at all. `environment.shells` holds binary paths, so the
              # comparison is a prefix of the declared shell's store path.
              korolevLoginShell =
                assert korolevHome.programs.zsh.enable;
                assert korolevShell.pname == "zsh";
                assert builtins.any (
                  entry: lib.hasPrefix (toString korolevShell) (toString entry)
                ) korolevConfig.environment.shells;
                pkgs.runCommand "check-wsl-host-login-shell" { } "touch $out";
            }
            // onDarwinHost {
              airBatchCommand = airBatchCommandTest;
              airBatchConfiguration = airBatchConfigCheck;
              containerRuntimeCommand = containerRuntimeCommandTest;
              containerRuntimeConfiguration = containerRuntimeConfigCheck;

              macbookProTailnet =
                let
                  darwinConfig = self.darwinConfigurations.macbook-pro.config;
                in
                assert darwinConfig.services.tailscale.enable;
                assert lib.elem "--ssh" darwinConfig.services.tailscale.extraSetFlags;
                assert darwinConfig.services.openssh.enable == null;
                assert lib.elem "glockyco" darwinConfig.determinateNix.customSettings.trusted-users;
                pkgs.runCommand "check-macbook-pro-tailnet" { } "touch $out";

              darwinSystem = self.darwinConfigurations.macbook-pro.system;
            };

            # Declared for every system, with no platform condition. `.envrc` and
            # `lefthook.yml` both enter this shell, and the shell is what installs
            # the commit hook, so a system without it has no local gate.
            devShells.default = pkgs.mkShellNoCC {
              packages = [
                pkgs.git
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
              ]
              # Host tools, not repository tools. `darwin-rebuild` activates the
              # Darwin host, and `dnsconfig.js` needs the credential that
              # `modules/home/darwin/secrets.nix` decrypts through sops. The WSL
              # host declares no secret, so shipping `dnscontrol` there would move
              # the failure from shell entry into the middle of a DNS operation.
              ++ lib.optionals (host.kind == "darwin") [
                inputs.nix-darwin.packages.${system}.darwin-rebuild
                pkgs.dnscontrol
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
      }
    );
}
