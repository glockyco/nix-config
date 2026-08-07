{ pkgs, ... }:

{
  # Terminal UIs such as omp draw powerline/devicon glyphs. `symbols-only`
  # supplies just those glyphs as a fallback for any font, `jetbrains-mono` is a
  # complete patched terminal face to select outright.
  fonts.packages = with pkgs.nerd-fonts; [
    symbols-only
    jetbrains-mono
  ];
}
