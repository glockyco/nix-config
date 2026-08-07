{ pkgs, ... }:

{
  # Typst, plus tinymist -- its language server. tinymist is what gives an
  # editor completion, diagnostics, go-to-definition, formatting and live
  # preview for .typ files; Typst alone is just the compiler.
  #
  # Global rather than per-project because Typst is a single static binary with
  # no project-level dependency resolution to pin, and the editor needs the LSP
  # on PATH regardless of which directory is open. Papers with venue-specific
  # package sets should still pin `typst.withPackages` in their own flake.
  home.packages = [
    pkgs.typst
    pkgs.tinymist
  ];
}
