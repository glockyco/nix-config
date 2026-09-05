{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (import ../shared) tailnetDnsDomain;
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
      extraSetFlags = [ "--ssh=false" ];
    };

    # Apple's socket-activated listener does not honor ListenAddress.
    services.openssh = {
      enable = false;
      hostKeys = [
        {
          type = "ed25519";
          path = "/etc/ssh/ssh_host_ed25519_key";
        }
      ];
    };

    # Store-backed files are root-owned and cannot be changed by the login user.
    environment.etc."ssh/authorized_keys.d/${config.host.username}".text = ''
      restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICv/rjs4XMaAm1F3k7J+SAmJ/Sf40O6ZLEh5sX/pTP8b korolev-builder
    '';
    environment.etc."ssh/sshd_config_tailnet".text = ''
      ListenAddress ${config.host.name}.${tailnetDnsDomain}
      HostKey /etc/ssh/ssh_host_ed25519_key
      AuthorizedKeysFile /etc/ssh/authorized_keys.d/%u
      UsePAM yes
      AuthenticationMethods publickey
      PubkeyAuthentication yes
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      PermitRootLogin no
      AllowUsers ${config.host.username}
      DisableForwarding yes
      PermitTunnel no
    '';

    launchd.daemons.tailnet-sshd.serviceConfig = {
      ProgramArguments = [
        "/usr/sbin/sshd"
        "-D"
        "-e"
        "-f"
        (toString config.environment.etc."ssh/sshd_config_tailnet".source)
      ];
      RunAtLoad = true;
      KeepAlive = true;
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
