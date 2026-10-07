{ config, ... }:
{
  assertions = [
    {
      assertion = config.host.darwin.containerProfile != null;
      message = "container-client role requires host.darwin.containerProfile";
    }
  ];
  host.importedRoles.containerClient = true;
  imports = [ ./container-runtime.nix ];
}
