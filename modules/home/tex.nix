{ pkgs, ... }:

{
  # `scheme-full` rather than a smaller scheme: documents name fonts and
  # packages in their own preamble, so a missing one surfaces as a build error
  # in a document rather than as a decision made here.
  #
  # The two companions are not optional. minted shells out to pygmentize for
  # syntax highlighting, and spell checking shells out to aspell. Neither
  # failure is loud: a document builds with unhighlighted listings, or the
  # check silently passes over everything.
  home.packages = [
    pkgs.texliveFull
    (pkgs.python3.withPackages (ps: [ ps.pygments ]))
    pkgs.aspell
    pkgs.aspellDicts.en
  ];
}
