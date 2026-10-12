{
  config,
  inputs,
  lib,
  withSystem,
  ...
}:
let
  entries = builtins.readDir ../hosts;
  directories = lib.filterAttrs (_: kind: kind == "directory") entries;
  hostNames = builtins.filter (name: builtins.pathExists (../hosts + "/${name}/host.nix")) (
    builtins.attrNames directories
  );
  declaredHosts = lib.genAttrs hostNames (
    name:
    (lib.evalModules {
      modules = [
        ../modules/fleet/host.nix
        (../hosts + "/${name}/host.nix")
        { host.name = name; }
      ];
    }).config.host
  );
  configurations = lib.mapAttrs (
    name: host:
    withSystem host.system (
      { pkgs, ... }:
      inputs.nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [
          {
            nixpkgs.pkgs = pkgs;
            fleet.hosts = config.fleet.hosts;
            host.name = name;
          }
          (../hosts + "/${name}/default.nix")
        ];
      }
    )
  ) config.fleet.hosts;
in
{
  options.fleet.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = (import ../modules/fleet/host.nix { inherit lib; }).options.host;
      }
    );
    readOnly = true;
    description = "Standalone host declarations indexed by directory name.";
  };

  config = {
    fleet.hosts = declaredHosts;
    # Linux has no host. CI still runs the generic checks there: formatting,
    # DNS, the tailnet policy and the packages that build on Linux.
    systems = lib.unique (
      lib.mapAttrsToList (_: host: host.system) config.fleet.hosts ++ [ "x86_64-linux" ]
    );
    flake.darwinConfigurations = configurations;
  };
}
