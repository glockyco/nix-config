{ config, lib, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # nix-homebrew prepends its prefix in /etc/zshrc. Put the Home Manager
    # profile back first so public commands resolve to their curated wrappers.
    initContent = lib.mkAfter ''
      typeset -U path PATH
      path=("${config.home.profileDirectory}/bin" "''${path[@]}")
    '';

    # Large history keeps fzf Ctrl-R searches useful.
    history = {
      size = 100000;
      save = 100000;

      # Share and append history to avoid clobbering entries across terminals.
      share = true;
      append = true;

      # Collapse repeats so Ctrl-R shows distinct commands. This prunes older
      # duplicates anywhere in the history, which subsumes the consecutive-only
      # `ignoreDups`; that one is left at its default rather than restated here.
      ignoreAllDups = true;

      # A leading space excludes one-off commands containing secrets from history.
      ignoreSpace = true;
    };
  };

  # Powerline separators require the Nerd Font from modules/darwin/fonts.nix;
  # otherwise arrows render as tofu.
  programs.starship = {
    enable = true;
    presets = [ "catppuccin-powerline" ];

    settings = {
      directory.truncation_length = 5;

      # The catppuccin-powerline preset enables command-duration output and
      # notifications; disabling the module suppresses both.
      cmd_duration.disabled = true;
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
