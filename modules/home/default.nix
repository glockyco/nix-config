{
  # User-scope modules that any supported host can import. A module that depends
  # on a macOS interface belongs in `./darwin`, which only the Darwin host
  # imports.
  #
  # `catppuccin.nix` and `zed.nix` stay here because their settings are portable
  # while their package selection is host scope.
  imports = [
    ./shell.nix
    ./catppuccin.nix
    ./nix-index.nix
    ./cli.nix
    ./git.nix
    ./gh.nix
    ./ghq.nix
    ./packages.nix
    ./omp.nix
    ./typst.nix
    ./tex.nix
    ./zed.nix
  ];

  # Matches the pinned nixpkgs/Home Manager release; changing it changes option defaults.
  home.stateVersion = "26.05";
}
