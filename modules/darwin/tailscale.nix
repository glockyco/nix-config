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
  builderAuthorizedKeys = pkgs.writeText "macbook-pro-builder-authorized-keys" ''
    restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICv/rjs4XMaAm1F3k7J+SAmJ/Sf40O6ZLEh5sX/pTP8b korolev-builder
  '';
  authorizedKeysDirectory = "/var/lib/tailnet-sshd/authorized_keys";
  authorizedKeysFile = "${authorizedKeysDirectory}/${config.host.username}";
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

    # OpenSSH canonicalizes this path before applying StrictModes. Copy the
    # public key outside the group-writable Nix store before launchd reloads.
    system.activationScripts.extraActivation.text = ''
      /usr/bin/install -d -o root -g wheel -m 0755 \
        /var/lib/tailnet-sshd ${authorizedKeysDirectory}
      /usr/bin/install -o root -g wheel -m 0444 \
        ${builderAuthorizedKeys} ${authorizedKeysFile}
    '';

    environment.etc."ssh/sshd_config_tailnet".text = ''
      ListenAddress ${config.host.name}.${tailnetDnsDomain}
      HostKey /etc/ssh/ssh_host_ed25519_key
      AuthorizedKeysFile ${authorizedKeysFile}
      StrictModes yes
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
