{
  config,
  lib,
  pkgs,
  ...
}:

let
  bundle = "neo-layouts.bundle";
  layoutDir = "${config.home.homeDirectory}/Library/Keyboard Layouts";

  coreutils = "${pkgs.coreutils}/bin";
in

{
  # macOS scans this directory and recompiles layouts when its mtime changes;
  # copy the bundle from the store instead of symlinking it.
  # Removing this module does not remove the installed bundle.
  home.activation.neoKeyboardLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${coreutils}/mkdir -p $VERBOSE_ARG ${lib.escapeShellArg layoutDir}
    run ${coreutils}/rm -rf $VERBOSE_ARG ${lib.escapeShellArg "${layoutDir}/${bundle}"}
    run ${coreutils}/cp -R $VERBOSE_ARG ${lib.escapeShellArg "${pkgs.neo-keyboard-layouts}/${bundle}"} ${lib.escapeShellArg layoutDir}
    # Store copies are read-only; make the bundle writable and bump directory mtime
    # to trigger recompilation.
    run ${coreutils}/chmod -R u+w ${lib.escapeShellArg "${layoutDir}/${bundle}"}
    run ${coreutils}/touch ${lib.escapeShellArg layoutDir}
  '';
}
