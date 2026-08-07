{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # zsh's defaults are a small, per-session, duplicate-ridden history. That
    # matters more now that Ctrl-R is fzf: the search is only as good as what
    # is behind it.
    history = {
      size = 100000;
      save = 100000;

      # Two terminals open at once no longer clobber each other's history.
      share = true;
      append = true;

      # Collapse repeats so Ctrl-R shows distinct commands.
      ignoreDups = true;
      ignoreAllDups = true;

      # A leading space keeps a command out of history -- useful for one-off
      # invocations that contain a token or password.
      ignoreSpace = true;

      # Record timestamps and durations.
      extended = true;
    };
  };

  # Prompt. Starship is a single static binary that renders the prompt itself,
  # rather than a pile of zsh functions, so it stays fast in large git repos.
  #
  # The catppuccin-powerline preset matches the Ghostty theme, and its
  # separators need the Nerd Font installed by modules/darwin/fonts.nix -- with
  # a plain font the powerline arrows render as tofu.
  programs.starship = {
    enable = true;
    presets = [ "catppuccin-powerline" ];

    settings = {
      # Do not truncate the path to a couple of components; on this machine
      # the useful information is usually the deep end of the path.
      directory.truncation_length = 5;

      # Show how long the previous command took when it was slow enough to
      # notice, which is most of what a status line is actually for.
      cmd_duration.min_time = 2000;
    };
  };

  # Makes the .envrc in this repository (`use flake`) actually do something.
  # nix-direnv caches the evaluated dev shell and keeps it alive against the
  # garbage collector, so entering the directory is instant after the first time.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
