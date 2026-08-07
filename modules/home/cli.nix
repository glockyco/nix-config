{
  # Home Manager modules provide shell integration; installing fzf as a package
  # alone does not rebind Ctrl-R.
  programs = {
    fzf = {
      enable = true;
      # Exclude .git so pickers do not traverse repository object files.
      defaultCommand = "fd --type f --hidden --exclude .git";
      fileWidgetCommand = "fd --type f --hidden --exclude .git";
      changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
    };

    zoxide.enable = true;

    ripgrep.enable = true;
    fd.enable = true;
    bat.enable = true;

    eza = {
      enable = true;
      git = true;
      icons = "auto";
    };
  };
}
