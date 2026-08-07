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
  # Install the Neo keyboard layout bundle (base layer / layers 1 and 2).
  #
  # macOS discovers keyboard layouts by scanning ~/Library/Keyboard Layouts and
  # compiling what it finds there (Apple TN2056). It does not load a layout
  # through a symlink into the Nix store, and the store's read-only permissions
  # also defeat the directory-mtime check that triggers recompilation. So
  # `home.file` is the wrong tool here: the bundle is copied out of the store on
  # every activation instead.
  #
  # This is idempotent, but it is not tracked as a Home Manager file: removing
  # this module will not remove the installed bundle.
  home.activation.neoKeyboardLayout = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${coreutils}/mkdir -p $VERBOSE_ARG ${lib.escapeShellArg layoutDir}
    run ${coreutils}/rm -rf $VERBOSE_ARG ${lib.escapeShellArg "${layoutDir}/${bundle}"}
    run ${coreutils}/cp -R $VERBOSE_ARG ${lib.escapeShellArg "${pkgs.neo-keyboard-layouts}/${bundle}"} ${lib.escapeShellArg layoutDir}
    # The copy inherits the store's read-only mode; make it writable so the next
    # activation can replace it, then bump the directory mtime to force macOS to
    # recompile the layouts.
    run ${coreutils}/chmod -R u+w ${lib.escapeShellArg "${layoutDir}/${bundle}"}
    run ${coreutils}/touch ${lib.escapeShellArg layoutDir}
  '';
}
