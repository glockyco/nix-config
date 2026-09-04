{ ... }:
{
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--shields-up" ];
    disableTaildrop = true;
    openFirewall = false;
  };
}
