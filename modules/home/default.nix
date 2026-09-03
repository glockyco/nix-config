{
  # User-scope modules that any supported host can import. A module that depends
  # on a macOS interface belongs in `./darwin`, which only the Darwin host
  # imports.
  #
  # `catppuccin.nix` stays here because its palette and its ports for portable
  # programs apply to any host. Ports for a platform-specific program live
  # beside that program.
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
  ];

  # Matches the pinned nixpkgs/Home Manager release; changing it changes option defaults.
  home.stateVersion = "26.05";
}
