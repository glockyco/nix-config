{ config, pkgs, ... }:
{
  # Runtime state and VM lifecycle remain operator-owned. Chezmoi renders only
  # the profile and environment from shared facts and this derived architecture.
  users.users.${config.host.username}.packages = [
    pkgs.colima
    pkgs.docker-client
    pkgs.container-runtime-check
  ];
  chezmoi.resources.colima.arch = pkgs.stdenv.hostPlatform.qemuArch;
}
