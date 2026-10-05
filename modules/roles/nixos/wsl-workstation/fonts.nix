{ pkgs, ... }:

{
  # Windows Terminal draws with Windows fonts, but Linux programs that render text
  # themselves, such as headless Chromium for VHS recordings and OMP's managed browser,
  # only see fontconfig. Without this, they fall back to the proportional DejaVu Sans.
  fonts.packages = [ pkgs.jetbrains-mono ];
}
