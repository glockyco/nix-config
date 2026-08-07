{
  config,
  lib,
  pkgs,
  ...
}:

let
  screenshotDir = "${config.home.homeDirectory}/Pictures/Screenshots";
in

{
  # macOS falls back to the Desktop if this directory is absent; create it
  # explicitly because `home.file` cannot materialize an empty directory.
  home.activation.screenshotDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/mkdir -p $VERBOSE_ARG ${lib.escapeShellArg screenshotDir}
  '';
}
