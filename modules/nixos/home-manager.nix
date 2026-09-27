{
  config,
  inputs,
  ...
}:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.users.${config.host.username}.imports = [ ../home ];
}
