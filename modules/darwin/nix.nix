{
  config,
  inputs,
  ...
}:

let
  inherit (config.host) username;
  shared = import ../shared;
  inherit (shared) binaryCaches;
  nixPolicy = shared.nixPolicy { nixpkgs = inputs.nixpkgs; };
in
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
    registry.nixpkgs.flake = nixPolicy.registry.nixpkgs.flake;
    # Determinate Nixd collects garbage in the background, not on a weekly
    # timer. It has no scheduled optimiser; leave auto-optimise-store unset.
    determinateNixd.garbageCollector.strategy =
      if nixPolicy.maintenance.garbageCollection then "automatic" else "disabled";

    customSettings = {
      eval-cores = 0;
      # The nix-darwin channel option is inactive when Determinate owns Nix.
      nix-path = if nixPolicy.channels.enable then "/nix/var/nix/profiles/per-user/root/channels" else "";

      extra-experimental-features = [ "build-time-fetch-tree" ];

      # Use `extra-*` variants so this cache supplements rather than replaces
      # `cache.nixos.org`.
      extra-substituters = binaryCaches.substituters;
      extra-trusted-public-keys = binaryCaches.trustedPublicKeys;

      # Trust the SSH login user so this remote builder can import unsigned
      # store paths that korolev sends for a build.
      trusted-users = [
        "root"
        username
      ];
    };
  };
}
