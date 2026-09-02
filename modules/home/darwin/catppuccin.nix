{
  # Catppuccin ports for the programs in this directory. `../catppuccin.nix`
  # imports the upstream module, sets the palette, and pins `autoEnable` off, so
  # this file only adds ports.
  #
  # The port lives beside its program: `./ghostty.nix` configures a
  # Homebrew-supplied macOS application, so a portable module must not claim to
  # theme it.
  catppuccin.ghostty.enable = true;
}
