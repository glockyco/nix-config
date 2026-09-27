{ config, ... }:
{
  imports = [
    ./tailscale.nix
    ./rosetta.nix
    ./defaults.nix
    ./power.nix
    ./fonts.nix
    ./homebrew.nix
    ./rectangle.nix
    ./zen.nix
  ];

  home-manager.users.${config.host.username}.imports = [ ../../../home/darwin ];
}
