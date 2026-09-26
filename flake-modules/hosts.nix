{
  hosts,
  inputs,
  withSystem,
  ...
}:
{
  flake = {
    # Each host receives the package set that `perSystem` instantiates for
    # its system. The dependency runs outward, from one package set to the
    # hosts and the outputs, rather than from the outputs into a host.
    darwinConfigurations.macbook-pro = withSystem "aarch64-darwin" (
      { pkgs, ... }:
      import ../hosts/macbook-pro {
        inherit inputs pkgs;
        inherit (hosts.aarch64-darwin) name;
      }
    );

    # The WSL host is a NixOS configuration rather than a package, so it
    # owns a host directory and a system scope like the Darwin host.
    nixosConfigurations.korolev = withSystem "x86_64-linux" (
      { pkgs, ... }:
      import ../hosts/korolev {
        inherit inputs pkgs;
        inherit (hosts.x86_64-linux) name;
      }
    );
  };
}
