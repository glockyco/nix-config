{ inputs, ... }:
let
  hosts = {
    aarch64-darwin = {
      kind = "darwin";
      name = "macbook-pro";
    };
    x86_64-linux = {
      kind = "nixos";
      name = "korolev";
    };
  };
in
{
  systems = builtins.attrNames hosts;
  imports = [
    inputs.treefmt-nix.flakeModule
    ./hosts.nix
    ./packages.nix
    ./checks.nix
    ./devshell.nix
    ./formatter.nix
  ];
  _module.args.hosts = hosts;
}
