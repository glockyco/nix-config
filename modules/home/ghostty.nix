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

      # Installed system-wide by modules/darwin/fonts.nix. The Nerd Font
      # variant matters: omp and other TUIs draw powerline and devicon glyphs.
      font-family = "JetBrainsMono Nerd Font";
      font-size = 14;

      # Ghostty defaults to 2px of padding, which is why the stock window looks
      # cramped. `balance` distributes the leftover pixels from rounding the
      # grid, so the text block stays centred instead of drifting right.
      window-padding-x = 14;
      window-padding-y = 10;
      window-padding-balance = true;

      # Slight translucency with the macOS blur behind it. Subtle on purpose:
      # anything below ~0.9 starts to hurt readability of dim ANSI colours.
      background-opacity = 0.95;
      background-blur = true;

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
