{
  config,
  inputs,
  lib,
  self,
  ...
}:
let
  inherit (import ../modules/shared) tailnetPeers;
in
{
  flake.overlays.default =
    final: prev:
    lib.packagesFromDirectoryRecursive {
      inherit (final) callPackage;
      directory = ../packages;
    }
    // {
      inherit (inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}) herdr openspec;
      personal-omp-plugin =
        inputs.personal-omp-plugin.packages.${final.stdenv.hostPlatform.system}.default;
      plannotator = inputs.plannotator-packages.packages.${final.stdenv.hostPlatform.system}.plannotator;
      nixosOptionsDoc = final.callPackage ../overlays/nixos-options-doc.nix {
        nixosOptionsDoc = prev.nixosOptionsDoc;
      };
    };

  perSystem =
    { system, ... }:
    let
      # Flake packages and hosts consume this one overlay-extended package set.
      pkgs = inputs.nixpkgs.legacyPackages.${system}.extend self.overlays.default;
      hasDarwinHost = lib.any (host: host.system == system && host.kind == "darwin") (
        builtins.attrValues config.fleet.hosts
      );
      # Export the overlay's own derivations, so an exported package and the
      # package a host installs are one value with one call site.
      packageNames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../packages)
      );
      supported = lib.filterAttrs (_: package: lib.meta.availableOn pkgs.stdenv.hostPlatform package) (
        lib.genAttrs packageNames (name: pkgs.${name})
      );
      tailnetPolicy = (pkgs.callPackage ../lib/tailnet-policy.nix { }) {
        managedHosts = config.fleet.hosts;
        peers = tailnetPeers;
      };
    in
    {
      _module.args.pkgs = pkgs;
      packages =
        supported
        // {
          inherit (pkgs) openspec;
          tailnet-policy = tailnetPolicy;
        }
        // lib.optionalAttrs hasDarwinHost {
          inherit (inputs.nix-darwin.packages.${system}) darwin-rebuild;
          check-darwin-build-plans = pkgs.check-darwin-build-plans.override {
            flakeSource = self.outPath;
          };
        };
    };
}
