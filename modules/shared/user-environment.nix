{
  config,
  lib,
  pkgs,
  ...
}:
{
  users.users.${config.host.username}.packages = (import ./.).userPackages { inherit pkgs; };

  assertions = lib.mapAttrsToList (role: enabled: {
    assertion = enabled == config.host.importedRoles.${role};
    message = "host.roles.${role} must agree with its explicit role import";
  }) config.host.roles;
}
