{
  inputs,
  username,
  ...
}:

{
  imports = [ inputs.determinate.darwinModules.default ];

  # Determinate Nix owns /etc/nix/nix.conf. Enabling this forces
  # `nix.enable = false`, which makes nix-darwin's `nix.settings` and
  # `nix.extraOptions` inert -- every custom Nix setting has to go through
  # `customSettings`, which is rendered to /etc/nix/nix.custom.conf.
  determinateNix = {
    enable = true;

    customSettings = {
      # Parallel evaluation.
      eval-cores = 0;

      # Build-time flake inputs.
      extra-experimental-features = [ "build-time-fetch-tree" ];

      # Prebuilt binaries for llm-agents.nix (omp). These must be the `extra-*`
      # variants: a plain `substituters` would displace cache.nixos.org.
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];

      # Without this the substituter above is ignored for non-root builds.
      trusted-users = [
        "root"
        username
      ];
    };
  };
}
