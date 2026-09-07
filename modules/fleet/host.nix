{ lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.host = {
    name = mkOption {
      type = types.str;
      description = "Stable host name used by generated system outputs.";
    };

    username = mkOption {
      type = types.str;
      description = "Interactive user managed by the host configuration.";
    };

    build.logicalCores = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = "Measured logical CPU count when this host serves as a remote builder.";
    };

    tailnet = {
      tag = mkOption {
        type = types.strMatching "^tag:[a-z0-9-]+$";
        description = "Stable tailnet policy tag assigned to this host.";
      };

      reachable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether tailnet policy may name this host as a destination.";
      };
    };
  };
}
