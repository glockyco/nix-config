{
  config,
  lib,
  ...
}:
let
  cfg = config.services.tailscale;
in
{
  options.services.tailscale.extraSetFlags = lib.mkOption {
    description = "Extra flags to pass to {command}`tailscale set`.";
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "--advertise-exit-node" ];
  };

  config = {
    services.tailscale = {
      enable = true;
      extraSetFlags = [
        "--ssh"
        "--advertise-tags=${config.host.tailnet.tag}"
      ];
    };

    launchd.daemons.tailscaled-set = lib.mkIf (cfg.extraSetFlags != [ ]) {
      script = ''
        until ${lib.getExe cfg.package} status --json --peers=false >/dev/null 2>&1; do
          sleep 0.5
        done

        exec ${lib.getExe cfg.package} set ${lib.escapeShellArgs cfg.extraSetFlags}
      '';
      serviceConfig = {
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
      };
    };
  };
}
