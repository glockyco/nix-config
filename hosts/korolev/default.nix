{ config, ... }:
let
  user = config.users.users.${config.host.username};
in
{
  # `nixos-rebuild switch --flake .#korolev` selects this configuration by name,
  # because WSL reports no stable hostname before activation.
  imports = [
    ./host.nix
    ../../modules/fleet
    ../../modules/nixos
    ../../modules/roles/nixos/wsl-workstation
  ];

  # The SCCH share, which Windows maps as `S:`. WSL's file bridge mounts it
  # with the signed-in Windows session's credentials, so no credential lives
  # here. The UNC path names the share itself; `S:` is a per-user Windows
  # drive mapping that can change or disappear independently of this host.
  # The automount defers the mount to first access, so an unreachable share
  # cannot fail boot or activation.
  fileSystems."/mnt/s" = {
    device = ''\\scch.at\SCCH'';
    fsType = "drvfs";
    options = [
      "ro"
      "uid=${toString user.uid}"
      "gid=${toString config.users.groups.${user.group}.gid}"
      "noauto"
      "x-systemd.automount"
      "nofail"
    ];
    # The source is no block device; with fsck pass 2,
    # systemd-fstab-generator warns about that on every run.
    noCheck = true;
  };

  # With the default start limit, two failed mounts put the automount into
  # `mount-start-limit-hit`, and later accesses list the empty mount point as
  # if the share were empty. Without the limit, each access while the share
  # is unreachable fails. A drop-in keeps the fstab-generated unit as the
  # only definition of `mnt-s.mount`.
  systemd.units."mnt-s.mount" = {
    overrideStrategy = "asDropin";
    text = ''
      [Unit]
      StartLimitIntervalSec=0
    '';
  };

}
