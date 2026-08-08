{
  inputs,
  username,
  ...
}:

{
  imports = [ inputs.determinate.darwinModules.default ];

  # Determinate Nix owns `/etc/nix/nix.conf` and disables nix-darwin's
  # `nix.settings`/`nix.extraOptions`; configure Nix through `customSettings`.
  determinateNix = {
    enable = true;

    # This module forces `nix.enable = false`, so nix-darwin's own
    # `nix.registry` never reaches disk. Pin the indirect `nixpkgs` reference
    # here instead: without it `nix run nixpkgs#...` resolves through
    # Determinate's `nixpkgs-weekly` default rather than the flake input this
    # system is built from.
    registry.nixpkgs.flake = inputs.nixpkgs;

    customSettings = {
      eval-cores = 0;

      extra-experimental-features = [ "build-time-fetch-tree" ];

      # Use `extra-*` variants so this cache supplements rather than replaces
      # `cache.nixos.org`.
      extra-substituters = [ "https://cache.numtide.com" ];
      extra-trusted-public-keys = [
        "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
      ];

      # Allow non-root builds to use the Numtide substituter.
      trusted-users = [
        "root"
        username
      ];
    };
  };
}
