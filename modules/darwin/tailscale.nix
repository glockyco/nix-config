{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tailscale;
  tailscaleSetAfterLogin = pkgs.callPackage ../../packages/tailscale-set-after-login.nix {
    tailscale = cfg.package;
  };
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
      serviceConfig = {
        ProgramArguments = [ (lib.getExe tailscaleSetAfterLogin) ] ++ cfg.extraSetFlags;
        RunAtLoad = true;
        KeepAlive.SuccessfulExit = false;
      };
    };
  };
}
