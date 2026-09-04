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

    ompRuntime = {
      executable = mkOption {
        type = types.attrTag {
          absolute = mkOption {
            type = types.path;
            description = "Absolute path to the platform-owned OMP executable.";
          };
          homeRelative = mkOption {
            type = types.str;
            description = "OMP executable path relative to the interactive user's home.";
          };
        };
        description = "Platform-owned OMP executable location.";
      };

      installCommand = mkOption {
        type = types.nonEmptyStr;
        description = "Command shown when the platform-owned OMP executable is absent.";
      };
    };
  };
}
