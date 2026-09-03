{
  inputs,
  pkgs,
  username,
  ...
}:

{
  imports = [ inputs.nixos-wsl.nixosModules.default ];

  wsl = {
    enable = true;

    # The interactive session runs as this user. WSL starts it without a login
    # manager, so the value here is what `wsl.exe` attaches to.
    defaultUser = username;

    # Zed propagates extensions with `wsl.exe --exec cp`. That invocation uses
    # WSL's fixed FHS PATH rather than the NixOS profile, so expose only the
    # command that the native WSL integration requires.
    extraBin = [ { src = "${pkgs.coreutils}/bin/cp"; } ];
  };

  # WSL provides no `tty1`, so this unit cannot start and leaves the system
  # permanently `degraded`. A degraded system hides a real failure, so the unit
  # is disabled rather than tolerated.
  systemd.services."getty@tty1".enable = false;
}
