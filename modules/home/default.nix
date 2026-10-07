{
  # User-scope modules that every supported host can import. Modules that
  # depend on macOS interfaces belong in `./darwin` under the desktop role.
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
    ./typst.nix
    ./tex.nix
  ];

  # Matches the pinned nixpkgs/Home Manager release; changing it changes option defaults.
  home.stateVersion = "26.05";
}
