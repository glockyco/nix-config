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
  # `system.defaults.screencapture.location` in modules/darwin/defaults.nix
  # points here. macOS does not create the directory and silently reverts to
  # writing on the Desktop if it is missing, so it has to exist.
  #
  # Not a `home.file` entry: that would need a placeholder file inside the
  # directory to materialise it, and this folder should stay empty until you
  # take a screenshot.
  home.activation.screenshotDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/mkdir -p $VERBOSE_ARG ${lib.escapeShellArg screenshotDir}
  '';
}
