{
  hosts,
  inputs,
  self,
  ...
}:
{
  flake = {
    overlays.default = final: _prev: {
      neo-keyboard-layouts = final.callPackage ../packages/neo-keyboard-layouts.nix { };
      nixosOptionsDoc = final.callPackage ../packages/options-context.nix {
        nixosOptionsDoc = _prev.nixosOptionsDoc;
      };
      wsl-open = final.callPackage ../packages/wsl-open.nix { };
    };
  };
  perSystem =
    { lib, system, ... }:
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
      inherit (import ../modules/shared) binaryCaches tailnetPeers;
      managedHosts = {
        macbook-pro = self.darwinConfigurations.macbook-pro.config.host;
        korolev = self.nixosConfigurations.korolev.config.host;
      };
      tailnetPolicyRenderer = pkgs.callPackage ../packages/tailnet-policy.nix { };
      tailnetPolicy = tailnetPolicyRenderer {
        inherit managedHosts;
        peers = tailnetPeers;
      };
      tailnetPolicyCheck = pkgs.callPackage ../packages/tailnet-policy-check.nix {
        inherit managedHosts tailnetPolicy tailnetPolicyRenderer;
        peers = tailnetPeers;
      };
      tailnetPolicyRejectsCheck = pkgs.callPackage ../packages/tailnet-policy-rejects.nix {
        inherit managedHosts tailnetPolicyRenderer;
        peers = tailnetPeers;
      };
      tailscaleSetAfterLoginTest = pkgs.callPackage ../packages/tailscale-set-after-login-tests.nix { };
      markdownOxide = pkgs.callPackage ../packages/markdown-oxide.nix { };
      roslynLanguageServer = pkgs.callPackage ../packages/roslyn-language-server.nix { };
      personalOmp = pkgs.callPackage ../packages/personal-omp.nix {
        inherit
          markdownOxide
          roslynLanguageServer
          ;
        inherit (llmAgents) herdr;
        plannotator = inputs.plannotator-packages.packages.${system}.plannotator;
        plugin = inputs.personal-omp-plugin.packages.${system}.default;
      };
      moduleImportsCheck = pkgs.callPackage ../packages/module-imports-check.nix { };
      moduleImportsCommandTest = pkgs.callPackage ../packages/module-imports-check-tests.nix {
        inherit moduleImportsCheck;
      };
      hostDeclarationCheck = pkgs.callPackage ../packages/host-declaration-check.nix { };
      airBatchCheck = pkgs.callPackage ../packages/air-batch-check.nix { };
      airBatchCommandTest = pkgs.callPackage ../packages/air-batch-check-tests.nix {
        inherit airBatchCheck;
      };
      airBatchConfigCheck = pkgs.callPackage ../packages/air-batch-config-check.nix {
        homeConfiguration = self.darwinConfigurations.macbook-pro.config.home-manager.users.glockyco;
      };
      containerRuntimeCheck = pkgs.callPackage ../packages/container-runtime-check.nix { };
      containerRuntimeCommandTest = pkgs.callPackage ../packages/container-runtime-check-tests.nix {
        inherit containerRuntimeCheck;
      };
      containerRuntimeConfigCheck = pkgs.callPackage ../packages/container-runtime-config-check.nix {
        inherit containerRuntimeCheck;
        homeConfiguration = self.darwinConfigurations.macbook-pro.config.home-manager.users.glockyco;
      };
      wslOpen = pkgs.wsl-open;
      wslOpenCommandTest = pkgs.callPackage ../packages/wsl-open-tests.nix {
        inherit wslOpen;
      };
      windowsConfiguration = pkgs.callPackage ../modules/windows { };
      windowsConfigurationCheck = pkgs.callPackage ../packages/windows-configuration-check.nix {
        inherit windowsConfiguration;
      };

      # `nixosConfigurations.korolev` is the only `x86_64-linux` host. These
      # bindings are lazy, so the Darwin outputs never force them.
      korolevConfig = self.nixosConfigurations.korolev.config;
      korolevBuildMachines = korolevConfig.nix.buildMachines;
      korolevBuildMachine = builtins.head korolevBuildMachines;
      korolevUser = korolevConfig.wsl.defaultUser;
      korolevHome = korolevConfig.home-manager.users.${korolevUser};
      korolevShell = korolevConfig.users.users.${korolevUser}.shell;
      ompBrowserRuntimeCheck = pkgs.callPackage ../packages/omp-browser-runtime-check.nix {
        inherit personalOmp;
        systemPath = korolevConfig.system.path;
      };
    in
    {
      _module.args.pkgs = pkgs;
      _module.args.fleetBindings = {
        inherit
          host
          onDarwinHost
          onNixosHost
          hostConfiguration
          pkgs
          llmAgents
          openspec
          configuredHost
          binaryCaches
          tailnetPeers
          managedHosts
          tailnetPolicyRenderer
          tailnetPolicy
          tailnetPolicyCheck
          tailnetPolicyRejectsCheck
          tailscaleSetAfterLoginTest
          markdownOxide
          roslynLanguageServer
          personalOmp
          moduleImportsCheck
          moduleImportsCommandTest
          hostDeclarationCheck
          airBatchCheck
          airBatchCommandTest
          airBatchConfigCheck
          containerRuntimeCheck
          containerRuntimeCommandTest
          containerRuntimeConfigCheck
          wslOpen
          wslOpenCommandTest
          windowsConfiguration
          windowsConfigurationCheck
          korolevConfig
          korolevBuildMachines
          korolevBuildMachine
          korolevUser
          korolevHome
          korolevShell
          ompBrowserRuntimeCheck
          ;
      };
      packages = {
        inherit openspec;
        markdown-oxide = markdownOxide;
        omp-dev-update = personalOmp.devUpdate;
        personal-omp = personalOmp;
        roslyn-language-server = roslynLanguageServer;
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
        check-darwin-build-plans = pkgs.callPackage ../packages/check-darwin-build-plans.nix {
          flakeSource = self.outPath;
        };
        air-batch-check = airBatchCheck;
        container-runtime-check = containerRuntimeCheck;
      };
    };
}
