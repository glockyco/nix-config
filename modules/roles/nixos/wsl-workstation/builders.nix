{ config, lib, ... }:
let
  builders = lib.filterAttrs (
    name: host: name != config.host.name && host.build.logicalCores != null
  ) config.fleet.hosts;
in
{
  nix.settings.builders-use-substitutes = true;
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
}
