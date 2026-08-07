{
  programs.ghostty = {
    enable = true;

    # Ghostty comes from the Homebrew cask (modules/darwin/homebrew.nix); this
    # module only writes ~/.config/ghostty/config. Ghostty reads that file and
    # never rewrites it, so a store symlink is safe here -- unlike Karabiner
    # and Zed, which both persist their own state back to disk.
    package = null;

    settings = {
      theme = "Catppuccin Mocha";

      # Installed system-wide by modules/darwin/fonts.nix. Two things matter in
      # this family name: "Nerd Font" supplies the powerline and devicon glyphs
      # that omp and other TUIs draw, and the "NL" variant is JetBrains Mono
      # with the ligatures physically removed. That is preferable to disabling
      # `calt` at the renderer -- there is no ligature to suppress in the first
      # place, so nothing can re-enable them per-application.
      font-family = "JetBrainsMonoNL Nerd Font";
      font-size = 14;

      # Ghostty defaults to 2px of padding, which is why the stock window looks
      # cramped. `balance` distributes the leftover pixels from rounding the
      # grid, so the text block stays centred instead of drifting right.
      window-padding-x = 14;
      window-padding-y = 10;
      window-padding-balance = true;

      macos-titlebar-style = "tabs";

      cursor-style = "bar";
      mouse-hide-while-typing = true;

      # Deliberately NOT set: `macos-option-as-alt`. Neo2 uses left Option as
      # the Mod3 modifier, so Option must keep producing composed layer-3
      # characters. Turning it on makes Option send Esc-prefixed meta sequences
      # instead, which silently breaks layer 3 inside the terminal.
    };
  };
}
