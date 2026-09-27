{ config, ... }:
{
  assertions = [
    {
      assertion = config.host.darwin.containerProfile != null;
      message = "container-client role requires host.darwin.containerProfile";
    }
  ];
  home-manager.users.${config.host.username}.imports = [ ./container-runtime.nix ];
}
