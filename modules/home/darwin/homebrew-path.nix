{ config, lib, ... }:
{
  # nix-homebrew prepends its prefix in /etc/zshrc. Keep the curated Home
  # Manager wrappers ahead of that prefix in interactive Darwin shells.
  programs.zsh.initContent = lib.mkAfter ''
    typeset -U path PATH
    path=("${config.home.profileDirectory}/bin" "''${path[@]}")
  '';
}
