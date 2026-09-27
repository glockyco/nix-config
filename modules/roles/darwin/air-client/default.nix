{ config, ... }:
{
  home-manager.users.${config.host.username}.imports = [
    ./ssh.nix
    ./network-shares.nix
  ];
}
