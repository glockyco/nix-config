{
  config,
  inputs,
  pkgs,
  ...
}:

let
  inherit (config.host) username;
in
{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  wsl = {
    enable = true;

    # The interactive session runs as this user. WSL starts it without a login
    # manager, so the value here is what `wsl.exe` attaches to.
    defaultUser = username;

    # Restore Windows execution even when WSL's startup registration is absent.
    interop.register = true;

    # systemd-resolved keeps Windows DNS tunneling as its upstream without WSL
    # replacing the file. Windows Tailscale owns MagicDNS; WSL has no daemon.
    wslConf.network.generateResolvConf = false;

    # Native Windows integrations invoke `cp` and `git` through `wsl.exe`
    # without a login shell. Those calls use WSL's fixed FHS PATH rather than
    # the NixOS profile, so expose only the required bridge commands.
    extraBin = [
      { src = "${pkgs.coreutils}/bin/cp"; }
      { src = "${pkgs.git}/bin/git"; }
    ];
  };

  # Windows DNS tunneling carries public, employer and Windows-owned MagicDNS.
  # Keep NAT networking; do not add a second Tailscale resolver or identity.
  services.resolved.enable = true;
  networking.nameservers = [ "10.255.255.254" ];

  # WSL provides no `tty1`, so this unit cannot start and leaves the system
  # permanently `degraded`. A degraded system hides a real failure, so the unit
  # is disabled rather than tolerated.
  systemd.services."getty@tty1".enable = false;
}
