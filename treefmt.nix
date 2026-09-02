_:

{
  # treefmt walks up from the invocation directory to find this marker, so
  # `nix fmt` covers the whole tree no matter which subdirectory it runs from.
  projectRootFile = "flake.nix";

  # sops writes these; a formatter has no business rewriting ciphertext. The
  # MAC covers values rather than layout, so reindenting happens to survive,
  # but it would fight `sops` on every edit and any reflowing of the ENC[...]
  # blobs would corrupt the file outright.
  settings.excludes = [
    ".omp/**"
    "secrets/*"
  ];

  programs = {
    # RFC 166 formatter.
    nixfmt.enable = true;

    # modules/home/darwin/*.py
    ruff-format.enable = true;

    # Plain mdformat only speaks CommonMark, which has no tables: it collapses
    # the cells and leaves the delimiter row ragged. The GFM plugin adds
    # tables, strikethrough and task lists, and aligns table columns.
    mdformat = {
      enable = true;
      plugins = ps: [ ps.mdformat-gfm ];
    };

    jsonfmt.enable = true;

    # .github/workflows/. yamlfmt collapses every blank line by default, which
    # runs the workflow steps together.
    yamlfmt = {
      enable = true;
      settings.formatter.retain_line_breaks = true;
    };
  };
}
