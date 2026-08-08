{ inputs, ... }:

{
  # zsh's `command_not_found_handler` needs an index of which package ships
  # which binary. Determinate Nix has no channels, so nixpkgs' own
  # `command-not-found` has nothing to read; this ships a prebuilt database
  # instead of indexing the store locally.
  imports = [ inputs.nix-index-database.homeModules.nix-index ];

  programs.nix-index.enable = true;
}
