{ pkgs, ... }:

{
  # Install Typst and tinymist globally so the language server is always on PATH.
  # Pin venue-specific packages with `typst.withPackages` in the project flake.
  home.packages = [
    pkgs.typst
    pkgs.tinymist
  ];
}
