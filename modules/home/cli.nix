{
  # Modern replacements for the coreutils-era defaults. These are Home Manager
  # modules rather than bare `home.packages` entries on purpose: the modules
  # wire the shell integration, which is where most of the value is. Installing
  # fzf as a package alone leaves Ctrl-R untouched.
  programs = {
    # Fuzzy finder. Rebinds Ctrl-R to fuzzy history search, Ctrl-T to a file
    # picker and Alt-C to fuzzy directory change.
    fzf = {
      enable = true;
      # Respect .gitignore and include hidden files, but never descend into
      # .git -- otherwise every picker is drowned in object files.
      defaultCommand = "fd --type f --hidden --exclude .git";
      fileWidgetCommand = "fd --type f --hidden --exclude .git";
      changeDirWidgetCommand = "fd --type d --hidden --exclude .git";
    };

    # `cd` that ranks directories by how often you actually visit them, so
    # `z nixd` reaches this repository from anywhere.
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
