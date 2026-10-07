{ config, pkgs, ... }:
{
  # Chezmoi renders the role's SSH aliases; this role only installs its check.
  users.users.${config.host.username}.packages = [ pkgs.air-batch-check ];
}
