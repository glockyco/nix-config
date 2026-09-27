{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (import ../shared) binaryCaches;
  nixPolicy = import ../shared/nix-policy.nix { nixpkgs = inputs.nixpkgs; };
  builders = lib.filterAttrs (
    name: host: name != config.host.name && host.build.logicalCores != null
  ) config.fleet.hosts;
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
    builders-use-substitutes = true;
  };

  nix.distributedBuilds = true;
  nix.buildMachines = lib.mapAttrsToList (_: builder: {
    hostName = builder.name;
    sshUser = builder.username;
    sshKey = "/root/.ssh/${builder.name}-builder";
    system = builder.system;
    protocol = "ssh-ng";
    maxJobs = builder.build.logicalCores;
    speedFactor = builder.build.logicalCores;
    supportedFeatures = [ "big-parallel" ];
  }) builders;

  # `trusted-users` stays at its default of `root` alone. An interactive user
  # must not add a substituter or signing key through a flake.
}
