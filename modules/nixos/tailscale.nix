{ config, ... }:
{
  services.tailscale = {
    enable = true;
    extraSetFlags = [
      "--shields-up"
      "--advertise-tags=${config.host.tailnet.tag}"
    ];
    disableTaildrop = true;
    openFirewall = false;
  };
}
