{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.tailscale;
  tailscaleSetAfterLogin = pkgs.tailscale-set-after-login.override { tailscale = cfg.package; };
in
{
  services.tailscale = {
    enable = true;
    extraSetFlags = [ "--shields-up" ];
    disableTaildrop = true;
    openFirewall = false;
  };

  # The upstream oneshot can finish before the first interactive login. That
  # login resets preferences, so keep the declared setting pending until the
  # backend is authenticated and running.
  systemd.services.tailscaled-set.script = lib.mkForce ''
    exec ${lib.getExe tailscaleSetAfterLogin} ${lib.escapeShellArgs cfg.extraSetFlags}
  '';
}
