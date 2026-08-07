{
  programs.ghostty = {
    enable = true;

    # Ghostty is installed by Homebrew; this module writes only its config.
    # Ghostty does not rewrite that file, so a store symlink is safe.
    package = null;

    settings = {
      theme = "Catppuccin Mocha";

      # Nerd Font supplies powerline/devicon glyphs; `NL` removes ligatures
      # from JetBrains Mono, so `calt` need not be disabled.
      font-family = "JetBrainsMonoNL Nerd Font";
      font-size = 14;

      # Padding prevents a cramped text block.
      # `balance` centers pixels left by grid rounding.
      window-padding-x = 14;
      window-padding-y = 10;
      window-padding-balance = true;

      macos-titlebar-style = "tabs";

      cursor-style = "bar";
      mouse-hide-while-typing = true;

      # Neo2 uses left Option as Mod3; `macos-option-as-alt` would replace
      # layer-3 characters with Esc-prefixed meta sequences.
    };
  };
}
