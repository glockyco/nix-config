{ config, inputs, ... }:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";
    extraSpecialArgs = { inherit inputs; };
    # Give user modules the same typed host declaration as system modules.
    sharedModules = [
      ./host.nix
      { host = config.host; }
    ];
  };
}
