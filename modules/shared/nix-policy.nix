{ nixpkgs }:
{
  registry.nixpkgs.flake = nixpkgs;
  channels.enable = false;
  maintenance = {
    garbageCollection = true;
    storeOptimisation = true;
    schedule = "weekly";
  };
}
