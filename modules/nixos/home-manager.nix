{
  config,
  inputs,
  ...
}:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  # Only the portable list. `../home/darwin` is absent here, so a module that
  # names a macOS interface cannot reach this host.
  home-manager.users.${config.host.username}.imports = [ ../home ];
}
