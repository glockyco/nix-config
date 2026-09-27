{ pkgs, ... }:

{
  # Terminal UIs need powerline/devicon glyphs; `symbols-only` provides fallback
  # glyphs and `jetbrains-mono` is a complete patched terminal face.
  fonts.packages = with pkgs.nerd-fonts; [
    symbols-only
    jetbrains-mono
  ];
}
