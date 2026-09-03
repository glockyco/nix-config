{
  inputs,
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
  };

  # WSL provides no `tty1`, so this unit cannot start and leaves the system
  # permanently `degraded`. A degraded system hides a real failure, so the unit
  # is disabled rather than tolerated.
  systemd.services."getty@tty1".enable = false;
}
