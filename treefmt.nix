_:

{
  # treefmt walks up from the invocation directory to find this marker, so
  # `nix fmt` covers the whole tree no matter which subdirectory it runs from.
  projectRootFile = "flake.nix";

  programs = {
    # RFC 166 formatter.
    nixfmt.enable = true;

    # modules/home/apple-terminal.py
    ruff-format.enable = true;

    mdformat.enable = true;
    jsonfmt.enable = true;

    # .github/workflows/. yamlfmt collapses every blank line by default, which
    # runs the workflow steps together.
    yamlfmt = {
      enable = true;
      settings.formatter.retain_line_breaks = true;
    };
  };
}
