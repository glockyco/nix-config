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
      system,
      ...
    }:
    let
      hosts = lib.filterAttrs (_: host: host.system == system) config.fleet.hosts;
      inherit (import ../modules/shared) binaryCaches tailnetPeers;
      supports = package: lib.meta.availableOn pkgs.stdenv.hostPlatform package;
      tailnetPolicyRenderer = pkgs.callPackage ../lib/tailnet-policy.nix { };
      tailnetPolicy = tailnetPolicyRenderer {
        managedHosts = config.fleet.hosts;
        peers = tailnetPeers;
      };

      markdownTests = pkgs.callPackage ../packages/markdown-oxide/tests.nix { };
      roslynTests = pkgs.callPackage ../packages/roslyn-language-server/tests.nix { };
      moduleImportTests = pkgs.callPackage ../packages/module-imports-check/tests.nix { };
      personalOmpTests = pkgs.callPackage ../packages/personal-omp/tests.nix { };

      hostChecks =
        host:
        let
          configuration =
            if host.kind == "darwin" then
              self.darwinConfigurations.${host.name}
            else
              self.nixosConfigurations.${host.name};
          hostConfig = configuration.config;
          home = hostConfig.home-manager.users.${host.username};
          settings =
            if host.kind == "darwin" then hostConfig.determinateNix.customSettings else hostConfig.nix.settings;
          installed = map (package: package.drvPath) home.home.packages;
          installedPackage = package: builtins.elem package.drvPath installed;
          user = hostConfig.users.users.${host.username};
          shell = user.shell;
        in
        {
          system = hostConfig.system.build.toplevel;
          home = home.home.activationPackage;
          nix-settings = pkgs.callPackage ../checks/host-nix-settings-check.nix {
            inherit binaryCaches;
            hostName = host.name;
            settings = {
              substituters = settings.extra-substituters;
              trustedPublicKeys = settings.extra-trusted-public-keys;
            };
          };
          personal-omp =
            assert lib.assertMsg (installedPackage pkgs.personal-omp)
              "${host.name}: installed OMP wrapper differs from pkgs.personal-omp";
            assert lib.assertMsg (installedPackage pkgs.personal-omp.devUpdate)
              "${host.name}: installed OMP updater differs from pkgs.personal-omp.devUpdate";
            assert lib.assertMsg (installedPackage pkgs.personal-omp.verifyPersonalOmp)
              "${host.name}: installed OMP verifier differs from pkgs.personal-omp.verifyPersonalOmp";
            assert lib.assertMsg (installedPackage pkgs.openspec)
              "${host.name}: pinned OpenSpec is absent from home.packages";
            assert lib.hasInfix "path=(\"/etc/profiles/per-user/${host.username}/bin\""
              home.programs.zsh.initContent;
            pkgs.runCommand "check-${host.name}-personal-omp" { } "touch $out";
          login-shell =
            assert home.programs.zsh.enable;
            assert home.home.homeDirectory == user.home;
            assert (
              if host.kind == "nixos" then
                shell.pname == "zsh"
                && builtins.any (
                  entry: lib.hasPrefix (toString shell) (toString entry)
                ) hostConfig.environment.shells
              else
                hostConfig.system.primaryUser == host.username
            );
            pkgs.runCommand "check-${host.name}-login-shell" { } "touch $out";
        }
        // lib.optionalAttrs (host.kind == "nixos") {
          isolation =
            let
              builders = builtins.filter (peer: peer.name != host.name && peer.build.logicalCores != null) (
                builtins.attrValues config.fleet.hosts
              );
              buildMachines = hostConfig.nix.buildMachines;
            in
            assert !hostConfig.services.openssh.enable;
            assert hostConfig.networking.firewall.allowedTCPPorts == [ ];
            assert hostConfig.networking.firewall.allowedUDPPorts == [ ];
            assert !(hostConfig ? sops);
            assert hostConfig.services.tailscale.enable;
            assert !hostConfig.services.tailscale.openFirewall;
            assert hostConfig.services.tailscale.disableTaildrop;
            assert hostConfig.services.tailscale.extraSetFlags == [ "--shields-up" ];
            assert hostConfig.nix.distributedBuilds;
            assert builtins.length buildMachines == builtins.length builders;
            assert
              lib.naturalSort (map (machine: machine.hostName) buildMachines)
              == lib.naturalSort (map (builder: builder.name) builders);
            pkgs.runCommand "check-${host.name}-isolation" { } "touch $out";
          container-runtime =
            assert hostConfig.virtualisation.podman.enable;
            assert hostConfig.virtualisation.podman.dockerCompat;
            assert !hostConfig.virtualisation.podman.dockerSocket.enable;
            assert !hostConfig.virtualisation.docker.enable;
            assert !hostConfig.virtualisation.libvirtd.enable;
            pkgs.runCommand "check-${host.name}-container-runtime" { } "touch $out";
          omp-browser-runtime = pkgs.callPackage ../checks/omp-browser-runtime-check.nix {
            personalOmp = pkgs.personal-omp;
            systemPath = hostConfig.system.path;
          };
        }
        // lib.optionalAttrs (host.kind == "darwin") {
          air-batch-configuration = pkgs.callPackage ../checks/air-batch-config-check.nix {
            homeConfiguration = home;
          };
          container-runtime-configuration = pkgs.callPackage ../checks/container-runtime-config-check.nix {
            containerRuntimeCheck = pkgs.container-runtime-check;
            homeConfiguration = home;
          };
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
            assert lib.elem host.username hostConfig.determinateNix.customSettings.trusted-users;
            assert !(builtins.hasAttr "ssh/authorized_keys.d/${host.username}" hostConfig.environment.etc);
            assert lib.hasInfix "AuthorizedKeysFile ${authorizedKeysFile}" sshdConfig;
            assert lib.hasInfix "StrictModes yes" sshdConfig;
            assert lib.hasInfix "/usr/bin/install -o root -g wheel -m 0444" activation;
            assert lib.hasInfix authorizedKeysFile activation;
            assert !(lib.elem "-e" sshdArguments);
            pkgs.runCommand "check-${host.name}-tailnet" { } "touch $out";
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

        hostDeclaration = pkgs.callPackage ../checks/host-declaration-check.nix { };
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
        windowsConfiguration = pkgs.callPackage ../checks/windows-configuration.nix {
          windowsConfiguration = pkgs.windows-configuration;
        };
        openspecContracts = inputs.personal-omp-plugin.lib.openspecCheck {
          inherit pkgs;
          src = ../.;
          name = "check-openspec-contracts";
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
              configuration =
                if host.kind == "darwin" then
                  self.darwinConfigurations.${host.name}
                else
                  self.nixosConfigurations.${host.name};
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
      // lib.optionalAttrs (supports pkgs.roslyn-language-server) {
        inherit (roslynTests) roslynInitialization;
      }
      // lib.optionalAttrs (supports pkgs.module-imports-check) {
        inherit (moduleImportTests) moduleImports moduleImportsCommand;
      }
      // lib.optionalAttrs (supports pkgs.personal-omp) {
        inherit (personalOmpTests)
          personalOmpShape
          personalOmpGeneration
          personalOmpVerification
          herdrOmpReconciliation
          ;
      }
      // lib.optionalAttrs (supports pkgs.omp-dev-update) {
        personalOmpUpdate = pkgs.omp-dev-update.tests;
      }
      // lib.optionalAttrs (supports pkgs.tailscale-set-after-login) {
        tailscaleSetAfterLogin = pkgs.callPackage ../packages/tailscale-set-after-login/tests.nix { };
      }
      // lib.optionalAttrs (supports pkgs.wsl-open) {
        wslOpenCommand = pkgs.callPackage ../packages/wsl-open/tests.nix {
          wslOpen = pkgs.wsl-open;
        };
      }
      // lib.optionalAttrs (supports pkgs.air-batch-check) {
        airBatchCommand = pkgs.callPackage ../packages/air-batch-check/tests.nix {
          airBatchCheck = pkgs.air-batch-check;
        };
      }
      // lib.optionalAttrs (supports pkgs.container-runtime-check) {
        containerRuntimeCommand = pkgs.callPackage ../packages/container-runtime-check/tests.nix {
          containerRuntimeCheck = pkgs.container-runtime-check;
        };
      }
      // perHost;
    };
}
