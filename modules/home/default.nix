{
  imports = [
    ./shell.nix
    ./catppuccin.nix
    ./nix-index.nix
    ./darwin-switch.nix
    ./secrets.nix
    ./fastmail.nix
    ./cli.nix
    ./ghostty.nix
    ./brave.nix
    ./apple-terminal.nix
    ./default-apps.nix
    ./git.nix
    ./gh.nix
    ./ghq.nix
    ./ssh.nix
    ./packages.nix
    ./typst.nix
    ./neo2.nix
    ./karabiner.nix
    ./screenshots.nix
    ./zed.nix
  ];

  # Matches the pinned nixpkgs/Home Manager release; changing it changes option defaults.
  home.stateVersion = "26.05";
}
