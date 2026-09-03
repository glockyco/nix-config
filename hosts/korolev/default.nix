{ inputs }:
# `nixos-rebuild switch --flake .#korolev` selects this configuration by name,
# because WSL reports no stable hostname before activation.
let
  hostname = "korolev";
  username = "user";
in
inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit inputs hostname username; };
  modules = [ ../../modules/nixos ];
}
