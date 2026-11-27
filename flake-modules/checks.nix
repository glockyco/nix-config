{
  config,
  inputs,
  self,
  ...
}:
{
  perSystem =
    {
      lib,
      pkgs,
      self',
      system,
      ...
    }:
    let
      hosts = lib.filterAttrs (_: host: host.system == system) config.fleet.hosts;
      inherit (import ../modules/shared) binaryCaches tailnetPeers;
      supports = package: lib.meta.availableOn pkgs.stdenv.hostPlatform package;
      # The fixtures render variants; the policy under test is the exported
      # one that the workflow applies.
      tailnetPolicyRenderer = pkgs.callPackage ../lib/tailnet-policy.nix { };
      tailnetPolicy = self'.packages.tailnet-policy;

      markdownTests = pkgs.callPackage ../packages/markdown-oxide/tests.nix { };
      roslynTests = pkgs.callPackage ../packages/roslyn-language-server/tests.nix { };
      moduleImportTests = pkgs.callPackage ../packages/module-imports-check/tests.nix { };

      hostChecks =
        host:
        let
          configuration = self.darwinConfigurations.${host.name};
          hostConfig = configuration.config;
          resources = hostConfig.chezmoi.resources or { };
          settings = hostConfig.determinateNix.customSettings;
          installed = map (package: package.drvPath) user.packages;
          installedPackage = package: builtins.elem package.drvPath installed;
          user = hostConfig.users.users.${host.username};
          shell = user.shell;
          darwinSwitch = pkgs.darwin-switch.override {
            configurationCheckout = host.paths.configurationCheckout;
            darwinRebuild = inputs.nix-darwin.packages.${system}.darwin-rebuild;
          };
          renderedHome = pkgs.callPackage ../checks/chezmoi-render-check.nix {
            inherit host resources;
            userPackages = user.packages;
          };
          sharedFacts =
            (builtins.fromTOML (builtins.readFile ../home/.chezmoidata/hosts.toml)).hosts.${host.name};
          platformFacts = sharedFacts.platforms.darwin;
        in
        {
          system = hostConfig.system.build.toplevel;
          chezmoi = renderedHome;
          shared-facts =
            assert host.username == platformFacts.username;
            assert user.home == platformFacts.home;
            assert host.homeDirectory == platformFacts.home;
            assert host.paths.repositoryRoot == platformFacts.ghqRoot;
            assert host.paths.configurationCheckout == platformFacts.checkout;
            assert host.git == sharedFacts.git;
            assert host.roles == sharedFacts.roles;
            assert hostConfig.host.roles == hostConfig.host.importedRoles;
            assert host.paths.screenshots == (sharedFacts.paths.screenshots or null);
            assert
              host.darwin.applications == map (
                application:
                {
                  cask = null;
                  masId = null;
                  masName = null;
                  appPath = null;
                  dockPosition = null;
                  startAtLogin = false;
                }
                // application
              ) (sharedFacts.applications or [ ]);
            assert !host.roles.containerClient || host.darwin.containerProfile == sharedFacts.container;
            pkgs.runCommand "check-${host.name}-shared-facts" { } "touch $out";
          nix-settings = pkgs.callPackage ../checks/host-nix-settings-check.nix {
            inherit binaryCaches;
            hostName = host.name;
            settings = {
              substituters = settings.extra-substituters;
              trustedPublicKeys = settings.extra-trusted-public-keys;
            };
          };
          # Upstream OMP and the personal plugin live outside Nix; the host
          # still owns the ordinary tools they call.
          agent-tools =
            let
              shared = import ../modules/shared/user-packages.nix { inherit pkgs; };
              native = [
                pkgs.openssh
                pkgs.roslyn-language-server
                darwinSwitch
              ];
              desktop = lib.optionals host.roles.desktop [
                pkgs.neo-keyboard-layout-install
                pkgs.karabiner-configuration
                pkgs.zed-configuration
                pkgs.default-applications
                pkgs.symbolic-hotkeys
                pkgs.apple-terminal-font
                pkgs.fastmail
              ];
              container = lib.optionals host.roles.containerClient [
                pkgs.colima
                pkgs.docker-client
                pkgs.container-runtime-check
              ];
              air = lib.optionals host.roles.airClient [
                pkgs.air-batch-check
                pkgs.air-share-mount
              ];
              required = shared ++ native ++ desktop ++ container ++ air;
              missing = builtins.filter (package: !installedPackage package) required;
              unavailable = builtins.filter (package: !supports package) required;
              helpers = lib.filterAttrs (_: concern: concern ? helper) resources;
            in
            assert lib.assertMsg (missing == [ ])
              "${host.name}: users.users packages lack ${lib.concatMapStringsSep ", " lib.getName missing}";
            assert lib.assertMsg (
              unavailable == [ ]
            ) "${host.name}: installed package unavailable on ${system}";
            assert lib.assertMsg (
              builtins.length installed == builtins.length (lib.unique installed)
            ) "${host.name}: duplicated user package derivation";
            assert builtins.all (
              concern: builtins.any (package: lib.hasPrefix "${package}/" concern.helper) user.packages
            ) (builtins.attrValues helpers);
            assert builtins.elem pkgs.git.drvPath (
              map (package: package.drvPath) hostConfig.environment.systemPackages
            );
            pkgs.runCommand "check-${host.name}-agent-tools" { nativeBuildInputs = [ pkgs.openspec ]; } ''
              reported="$(HOME="$TMPDIR" openspec --version)"
              if [ "$reported" != "${pkgs.openspec.version}" ]; then
                echo "openspec reports $reported, its package declares ${pkgs.openspec.version}" >&2
                exit 1
              fi
              touch "$out"
            '';
          login-shell =
            assert hostConfig.programs.zsh.enable;
            assert hostConfig.programs.zsh.enableCompletion;
            assert hostConfig.programs.direnv.enable;
            assert hostConfig.programs.direnv.nix-direnv.enable;
            assert hostConfig.programs.nix-index.enable;
            assert shell.drvPath == pkgs.zsh.drvPath;
            assert hostConfig.programs.zsh.enableAutosuggestions;
            assert hostConfig.programs.zsh.enableSyntaxHighlighting;
            assert !hostConfig.programs.zsh.enableFzfCompletion;
            assert !hostConfig.programs.zsh.enableFzfGit;
            assert !hostConfig.programs.zsh.enableFzfHistory;
            assert hostConfig.system.primaryUser == host.username;
            pkgs.runCommand "check-${host.name}-login-shell" { } "touch $out";
          darwin-switch-command = pkgs.callPackage ../packages/darwin-switch/tests.nix {
            darwin-switch = darwinSwitch;
          };
        }
        // lib.optionalAttrs (hostConfig.launchd.daemons ? tailnet-sshd) {
          tailnet =
            let
              authorizedKeysFile = "/var/lib/tailnet-sshd/authorized_keys/${host.username}";
              sshdConfig = hostConfig.environment.etc."ssh/sshd_config_tailnet".text;
              sshdArguments = hostConfig.launchd.daemons.tailnet-sshd.serviceConfig.ProgramArguments;
              activation = hostConfig.system.activationScripts.extraActivation.text;
            in
            assert hostConfig.services.tailscale.enable;
            assert hostConfig.services.tailscale.extraSetFlags == [ "--ssh=false" ];
            assert !hostConfig.services.openssh.enable;
            # No WSL builder imports unsigned paths any more, so the login user is not a trusted Nix user.
            assert !(lib.elem host.username (hostConfig.determinateNix.customSettings.trusted-users or [ ]));
            assert !(builtins.hasAttr "ssh/authorized_keys.d/${host.username}" hostConfig.environment.etc);
            assert lib.hasInfix "AuthorizedKeysFile ${authorizedKeysFile}" sshdConfig;
            assert lib.hasInfix "StrictModes yes" sshdConfig;
            assert lib.hasInfix "/usr/bin/install -o root -g wheel -m 0444" activation;
            assert lib.hasInfix authorizedKeysFile activation;
            assert !(lib.elem "-e" sshdArguments);
            pkgs.runCommand "check-${host.name}-tailnet" { } "touch $out";
        }
        // lib.optionalAttrs host.roles.desktop {
          applications =
            let
              applications = host.darwin.applications;
              casks = builtins.filter (application: application.cask != null) applications;
              masApps = builtins.filter (application: application.masId != null) applications;
              systemPackages = map (package: package.drvPath) hostConfig.environment.systemPackages;
            in
            assert hostConfig.homebrew.enable;
            assert map (cask: cask.name) hostConfig.homebrew.casks == map (app: app.cask) casks;
            assert
              hostConfig.homebrew.masApps
              == builtins.listToAttrs (map (app: lib.nameValuePair app.masName app.masId) masApps);
            assert masApps == [ ] || builtins.elem pkgs.mas.drvPath systemPackages;
            pkgs.runCommand "check-${host.name}-applications" { } "touch $out";
          personal-plugin-updates =
            let
              agent = hostConfig.launchd.user.agents.personal-plugin-upgrade.serviceConfig;
              checkEnvironment = ''
                if [[ "$GIT_TERMINAL_PROMPT" != 0 || "$GIT_SSH_COMMAND" != "ssh -o BatchMode=yes" ]]; then
                  echo "Command did not run with noninteractive Git settings" >&2
                  exit 99
                fi
              '';
              fakeGit = pkgs.writeShellScript "fake-git" ''
                ${checkEnvironment}
                printf 'git %s\n' "$*" >> "$COMMAND_LOG"
                if [[ "$3" == "''${FAILED_GIT_URL:-}" ]]; then
                  exit 128
                fi
              '';
              fakeOmp = pkgs.writeShellScript "fake-omp" ''
                ${checkEnvironment}
                printf '%s\n' "$*" >> "$COMMAND_LOG"
                case "$*" in
                  'plugin marketplace list')
                    case "''${LIST_FORMAT:-}" in
                      invalid)
                        echo "Unrecognized marketplace listing"
                        exit 0
                        ;;
                      empty)
                        printf 'No marketplaces configured\n\nAdd one with: omp plugin marketplace add <source>\n'
                        exit 0
                        ;;
                    esac
                    printf 'Configured Marketplaces:\n\n'
                    printf '  %s  %s\n' glockyco glockyco/omp-agent-setup \
                      obsidian-skills kepano/obsidian-skills
                    if [[ "''${LIST_FORMAT:-}" != missing ]]; then
                      printf '  %s  %s\n' glockyco-booking "''${BOOKING_SOURCE:-glockyco/omp-booking}"
                    fi
                    printf '  %s  %s\n' glockyco-workbench glockyco/obsidian-workbench
                    ;;
                  'plugin marketplace update glockyco-booking')
                    if [[ "''${REFRESH_RESULT:-}" == timeout ]]; then
                      sleep 10
                    else
                      exit "''${REFRESH_RESULT:-0}"
                    fi
                    ;;
                esac
              '';
            in
            assert agent.StartInterval == 3600;
            assert agent.RunAtLoad;
            assert agent.LimitLoadToSessionType == "Aqua";
            assert agent.StandardOutPath == "${user.home}/Library/Logs/personal-plugin-upgrade.log";
            assert agent.StandardErrorPath == agent.StandardOutPath;
            pkgs.runCommand "check-${host.name}-personal-plugin-updates" { } ''
              mkdir -p "$TMPDIR/home/Library/Application Support/Tern/omp/bin"
              cp ${fakeOmp} "$TMPDIR/home/Library/Application Support/Tern/omp/bin/omp"
              substitute ${builtins.head agent.ProgramArguments} "$TMPDIR/runner" \
                --replace-fail ${lib.escapeShellArg user.home} "$TMPDIR/home" \
                --replace-fail '${pkgs.git}/bin/git' ${fakeGit} \
                --replace-fail ' 300s ' ' 1s '
              export COMMAND_LOG="$TMPDIR/commands"

              cat > "$TMPDIR/expected" <<'EOF'
              git ls-remote --exit-code https://github.com/glockyco/omp-agent-setup HEAD
              git ls-remote --exit-code https://github.com/glockyco/omp-booking HEAD
              git ls-remote --exit-code https://github.com/glockyco/obsidian-workbench HEAD
              git ls-remote --exit-code https://github.com/kepano/obsidian-skills HEAD
              plugin marketplace list
              plugin marketplace update glockyco
              plugin upgrade --scope user personal@glockyco
              plugin marketplace update glockyco-booking
              plugin upgrade --scope user booking@glockyco-booking
              plugin marketplace update glockyco-workbench
              plugin upgrade --scope user workbench@glockyco-workbench
              plugin marketplace update obsidian-skills
              plugin upgrade --scope user obsidian@obsidian-skills
              EOF
              grep -vxF 'plugin upgrade --scope user booking@glockyco-booking' "$TMPDIR/expected" > "$TMPDIR/skipped-upgrade"
              grep -vxF 'plugin marketplace update glockyco-booking' "$TMPDIR/skipped-upgrade" > "$TMPDIR/skipped-plugin"
              head -n 5 "$TMPDIR/expected" > "$TMPDIR/skipped-all"

              run_case() {
                local expected_status="$1" expected_commands="$2" status=0
                shift 2
                : > "$COMMAND_LOG"
                env "$@" ${pkgs.bash}/bin/bash "$TMPDIR/runner" > "$TMPDIR/run.log" 2>&1 || status=$?
                cat "$TMPDIR/run.log"
                test "$status" = "$expected_status"
                grep -q "personal plugin update finished: $expected_status$" "$TMPDIR/run.log"
                diff -u "$TMPDIR/$expected_commands" "$COMMAND_LOG"
              }

              run_case 0 expected
              run_case 1 skipped-upgrade REFRESH_RESULT=23
              grep -q 'Command failed (exit 23): .* plugin marketplace update glockyco-booking$' "$TMPDIR/run.log"
              run_case 1 skipped-upgrade REFRESH_RESULT=timeout
              grep -q 'Command timed out: .* plugin marketplace update glockyco-booking$' "$TMPDIR/run.log"
              run_case 0 expected FAILED_GIT_URL=https://github.com/glockyco/omp-booking
              grep -Fxq 'Git cannot read https://github.com/glockyco/omp-booking: run gh auth login -h github.com --web' "$TMPDIR/run.log"
              run_case 0 expected BOOKING_SOURCE=git@github.com:glockyco/omp-booking.git
              grep -Fxq 'Marketplace glockyco-booking is registered as git@github.com:glockyco/omp-booking.git, declared glockyco/omp-booking: run omp plugin marketplace remove glockyco-booking && omp plugin marketplace add glockyco/omp-booking' "$TMPDIR/run.log"
              run_case 1 skipped-plugin LIST_FORMAT=missing
              grep -Fxq 'Marketplace glockyco-booking is not registered: run omp plugin marketplace add glockyco/omp-booking' "$TMPDIR/run.log"
              run_case 1 skipped-all LIST_FORMAT=empty
              grep -Fxq 'Marketplace glockyco-booking is not registered: run omp plugin marketplace add glockyco/omp-booking' "$TMPDIR/run.log"
              run_case 0 expected LIST_FORMAT=invalid
              grep -Fxq 'Cannot read omp plugin marketplace list' "$TMPDIR/run.log"
              touch "$out"
            '';
          desktop-batch-configuration = pkgs.callPackage ../checks/ssh-endpoint-config-check.nix {
            inherit host renderedHome;
            endpoint = "desktop";
          };
          korolev-batch-configuration = pkgs.callPackage ../checks/ssh-endpoint-config-check.nix {
            inherit host renderedHome;
            endpoint = "korolev";
          };
          desktop-ac-batch-configuration = pkgs.callPackage ../checks/ssh-endpoint-config-check.nix {
            inherit host renderedHome;
            endpoint = "desktop-ac";
          };
        }
        // lib.optionalAttrs host.roles.airClient {
          air-batch-configuration = pkgs.callPackage ../checks/air-batch-config-check.nix {
            inherit host renderedHome;
          };
          air-agent =
            let
              agent = hostConfig.launchd.user.agents.mount-air-share.serviceConfig;
              airFacts = (builtins.fromTOML (builtins.readFile ../home/.chezmoidata/air.toml)).air;
            in
            assert agent.StartInterval == 60;
            assert agent.RunAtLoad;
            assert agent.LimitLoadToSessionType == "Aqua";
            assert agent.StandardOutPath == "${user.home}/Library/Logs/mount-air-share.log";
            assert agent.StandardErrorPath == "${user.home}/Library/Logs/mount-air-share.log";
            assert !((hostConfig.launchd.agents or { }) ? mount-air-share);
            assert
              agent.ProgramArguments == [
                (lib.getExe pkgs.air-share-mount)
                airFacts.home
                "smb://${airFacts.user}@${airFacts.hostName}/${airFacts.shareName}"
                airFacts.hostName
              ];
            pkgs.runCommand "check-${host.name}-air-agent" { } ''
              test "$(readlink ${renderedHome}/home/Air)" = "${airFacts.home}"
              touch "$out"
            '';
        }
        // lib.optionalAttrs host.roles.containerClient {
          container-runtime-configuration = pkgs.callPackage ../checks/container-runtime-config-check.nix {
            containerRuntimeCheck = pkgs.container-runtime-check;
            inherit host hostConfig renderedHome;
            platform = configuration.pkgs.stdenv.hostPlatform;
          };
        };

      perHost = lib.foldl' (checks: host: checks // host) { } (
        lib.mapAttrsToList (
          name: host:
          lib.mapAttrs' (gate: derivation: lib.nameValuePair "${name}-${gate}" derivation) (hostChecks host)
        ) hosts
      );

      directoryNames = lib.naturalSort (
        builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../hosts))
      );
      missingFiles = lib.concatMap (
        name:
        map (file: "${name}/${file}") (
          builtins.filter (file: !(builtins.pathExists (../hosts + "/${name}/${file}"))) [
            "host.nix"
            "default.nix"
          ]
        )
      ) directoryNames;
    in
    {
      checks = {

        dnsZone = pkgs.callPackage ../checks/dns-zone.nix { };
        hostDeclaration = pkgs.callPackage ../checks/host-declaration-check.nix { };
        chezmoiFactTypes = pkgs.callPackage ../checks/chezmoi-facts-check.nix {
          hosts = config.fleet.hosts;
        };
        secretEncryption = pkgs.callPackage ../checks/secret-encryption-check.nix { };
        tailnetPolicy = pkgs.callPackage ../checks/tailnet-policy-check.nix {
          managedHosts = config.fleet.hosts;
          peers = tailnetPeers;
          inherit tailnetPolicy tailnetPolicyRenderer;
        };
        tailnetPolicyRejects = pkgs.callPackage ../checks/tailnet-policy-rejects.nix {
          managedHosts = config.fleet.hosts;
          peers = tailnetPeers;
          inherit tailnetPolicyRenderer;
        };
        fleetSurface =
          assert lib.assertMsg (
            missingFiles == [ ]
          ) "fleetSurface: missing host files: ${lib.concatStringsSep ", " missingFiles}";
          assert lib.assertMsg (
            self.devShells.${system} ? default
          ) "fleetSurface: ${system} has no default shell";
          assert builtins.all (
            host:
            let
              configuration = self.darwinConfigurations.${host.name};
            in
            lib.assertMsg (
              configuration.pkgs.stdenv.hostPlatform.system == system
              && configuration.config.host.system == host.system
            ) "fleetSurface: ${host.name} evaluated system differs from ${host.system}"
          ) (builtins.attrValues hosts);
          pkgs.runCommand "check-fleet-surface" { } "touch $out";
      }
      // lib.optionalAttrs (supports pkgs.markdown-oxide) {
        inherit (markdownTests) markdownOxideVersion;
      }
      // lib.optionalAttrs (supports pkgs.bun-bin) {
        inherit (pkgs.callPackage ../packages/bun-bin/tests.nix { }) bunVersion;
      }
      // lib.optionalAttrs (supports pkgs.roslyn-language-server) {
        inherit (roslynTests) roslynInitialization;
      }
      // lib.optionalAttrs (supports pkgs.module-imports-check) {
        inherit (moduleImportTests) moduleImports moduleImportsCommand;
      }
      // lib.optionalAttrs (supports pkgs.tailscale-set-after-login) {
        tailscaleSetAfterLogin = pkgs.callPackage ../packages/tailscale-set-after-login/tests.nix { };
      }
      // lib.optionalAttrs (supports pkgs.fastmail) {
        fastmailCommand = pkgs.callPackage ../packages/fastmail/tests.nix { };
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        appleTerminalFontCommand = pkgs.callPackage ../packages/apple-terminal-font/tests.nix { };
        symbolicHotkeysCommand = pkgs.callPackage ../packages/symbolic-hotkeys/tests.nix { };
        neoKeyboardLayoutInstallCommand =
          pkgs.callPackage ../packages/neo-keyboard-layout-install/tests.nix
            { };
        karabinerConfigurationCommand = pkgs.callPackage ../packages/karabiner-configuration/tests.nix { };
        defaultApplicationsCommand = pkgs.callPackage ../packages/default-applications/tests.nix { };
        powerSettingsCommand = pkgs.callPackage ../packages/power-settings/tests.nix { };
        rosettaCommand = pkgs.callPackage ../packages/rosetta/tests.nix { };
        zedConfigurationCommand = pkgs.callPackage ../packages/zed-configuration/tests.nix { };
      }
      // lib.optionalAttrs (self'.packages ? air-batch-check) {
        airBatchCommand = pkgs.callPackage ../packages/air-batch-check/tests.nix {
          airBatchCheck = pkgs.air-batch-check;
        };
        airShareMountCommand = pkgs.callPackage ../packages/air-share-mount/tests.nix { };
      }
      // lib.optionalAttrs (supports pkgs.container-runtime-check) {
        containerRuntimeCommand = pkgs.callPackage ../packages/container-runtime-check/tests.nix {
          containerRuntimeCheck = pkgs.container-runtime-check;
        };
      }
      // perHost;
    };
}
