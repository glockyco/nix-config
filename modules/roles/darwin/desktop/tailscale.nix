{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (import ../../../shared) tailnetDnsDomain;
  cfg = config.services.tailscale;
  tailscaleSetAfterLogin = pkgs.tailscale-set-after-login.override { tailscale = cfg.package; };
  # Korolev's native Windows user administers the Mac and needs a terminal for
  # sudo prompts. The daemon denies forwarding and tunnels to every key.
  # Remove a line and reactivate to revoke that key alone.
  authorizedKeys = pkgs.writeText "macbook-pro-tailnet-authorized-keys" ''
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOdM+z+Cp2wKP0mXqJgBHQqaA/Qbf1x9w8/cDSWQNo9l korolev-windows
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
        ${authorizedKeys} ${authorizedKeysFile}
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
