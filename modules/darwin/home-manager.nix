{
  config,
  inputs,
  ...
}:

{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  # Every Darwin host receives portable Home Manager modules. Optional user
  # modules are selected with their roles in the host configuration.
  home-manager.users.${config.host.username}.imports = [ ../home ];
}
