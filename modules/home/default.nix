{
  imports = [
    ./shell.nix
    ./cli.nix
    ./ghostty.nix
    ./apple-terminal.nix
    ./default-apps.nix
    ./git.nix
    ./gh.nix
    ./ghq.nix
    ./ssh.nix
    ./packages.nix
    ./typst.nix
    ./crossover.nix
    ./neo2.nix
    ./karabiner.nix
    ./screenshots.nix
    ./zed.nix
  ];

  # Matches the nixpkgs/Home Manager release this flake is pinned to. Do not
  # bump this casually: it selects backwards-compatible option defaults.
  home.stateVersion = "26.05";
}
