{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    ./hosts.nix
    ./packages.nix
    ./checks.nix
    ./devshell.nix
    ./formatter.nix
  ];
}
