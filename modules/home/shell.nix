{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
  };

  # Makes the .envrc in this repository (`use flake`) actually do something.
  # nix-direnv caches the evaluated dev shell and keeps it alive against the
  # garbage collector, so entering the directory is instant after the first time.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
