{ lib, ... }:
{
  options.fleet.hosts = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = (import ./host.nix { inherit lib; }).options.host;
      }
    );
    description = "Typed host facts shared with peer modules.";
  };
}
