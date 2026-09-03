{ inputs, ... }:

{
  # One palette for every program that has a port, instead of a theme name
  # repeated per application. Home Manager is imported as a nix-darwin module,
  # so the Home Manager port belongs here rather than in `modules/darwin/`.
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

  catppuccin = {
    # The global toggle gates the whole module; without it nothing is themed.
    enable = true;

    flavor = "mocha";
    accent = "mauve";

    # `autoEnable` follows `enable` unless set. Pin it off and list ports
    # explicitly, so a future upstream release cannot theme a program silently.
    autoEnable = false;

    # Ports for programs that any host can install. A port for a
    # platform-specific program belongs beside that program, so the explicit
    # list in each scope still says exactly what is themed there.
    bat.enable = true;
    delta.enable = true;
    eza.enable = true;
    fzf.enable = true;

    # No starship port: Home Manager merges `programs.starship.settings` on top
    # of the presets, and the port sets `format`, which would drop the powerline
    # segments from the `catppuccin-powerline` preset in modules/home/shell.nix.
    # That preset is already Catppuccin.

    zsh-syntax-highlighting.enable = true;
  };
}
