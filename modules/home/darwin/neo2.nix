{
  config,
  lib,
  pkgs,
  ...
}:

let
  bundle = "neo-layouts.bundle";
  layoutDir = "${config.home.homeDirectory}/Library/Keyboard Layouts";

in

{
  # macOS scans this directory and recompiles layouts when its mtime changes;
  # copy the bundle from the store instead of symlinking it.
  # Removing this module does not remove the installed bundle.
  home.activation.neoKeyboardLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lib.getExe pkgs.neo-keyboard-layout-install} \
      ${lib.escapeShellArg "${pkgs.neo-keyboard-layouts}/${bundle}"} \
      ${lib.escapeShellArg "${layoutDir}/${bundle}"}
  '';
}
