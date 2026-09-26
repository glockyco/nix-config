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
  configurations =
    kind: builder:
    lib.mapAttrs (
      name: host:
      withSystem host.system (
        { pkgs, ... }:
        builder {
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
    ) (lib.filterAttrs (_: host: host.kind == kind) config.fleet.hosts);
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
    systems = lib.unique (lib.mapAttrsToList (_: host: host.system) config.fleet.hosts);
    flake.darwinConfigurations = configurations "darwin" inputs.nix-darwin.lib.darwinSystem;
    flake.nixosConfigurations = configurations "nixos" inputs.nixpkgs.lib.nixosSystem;
  };
}
