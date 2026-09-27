{
  inputs,
  ...
}:
let
  shared = import ../shared;
  inherit (shared) binaryCaches;
  nixPolicy = shared.nixPolicy { nixpkgs = inputs.nixpkgs; };
in
{
  nix.registry.nixpkgs.flake = nixPolicy.registry.nixpkgs.flake;
  nix.channel.enable = nixPolicy.channels.enable;
  nix.gc = {
    automatic = nixPolicy.maintenance.garbageCollection;
    dates = nixPolicy.maintenance.schedule;
  };
  nix.optimise = {
    automatic = nixPolicy.maintenance.storeOptimisation;
    dates = nixPolicy.maintenance.schedule;
  };
  # A daemon setting is the only source of this cache on this host. The root
  # flake declares no `nixConfig`: untrusted users cannot apply its keys.
  nix.settings = {
    extra-substituters = binaryCaches.substituters;
    extra-trusted-public-keys = binaryCaches.trustedPublicKeys;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # `trusted-users` stays at its default of `root` alone. An interactive user
  # must not add a substituter or signing key through a flake.
}
