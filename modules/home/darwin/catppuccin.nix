{
  # Catppuccin ports for the programs in this directory. `../catppuccin.nix`
  # imports the upstream module, sets the palette, and pins `autoEnable` off, so
  # this file only adds ports.
  #
  # Each port lives beside its program. `./ghostty.nix` and `./zed.nix` both
  # configure Homebrew-supplied macOS applications, so a portable module must
  # not claim to theme them.
  catppuccin = {
    ghostty.enable = true;
    zed.enable = true;
  };
}
