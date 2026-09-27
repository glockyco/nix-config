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
  assertions = [
    {
      assertion =
        config.host.displayName != null
        && config.host.paths.screenshots != null
        && config.host.locale.use24HourClock != null
        && config.host.locale.useMetric != null;
      message = "desktop role requires host display name, screenshots path, and locale formats";
    }
  ];

  home-manager.users.${config.host.username}.imports = [ ../../../home/darwin ];
}
