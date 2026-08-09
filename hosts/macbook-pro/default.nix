{ inputs }:
# `darwin-rebuild --flake .` resolves `darwinConfigurations.<LocalHostName>` after activation.
let
  hostname = "macbook-pro";
  username = "glockyco";
in
inputs.nix-darwin.lib.darwinSystem {
  specialArgs = { inherit inputs hostname username; };
  modules = [ ../../modules/darwin ];
}
