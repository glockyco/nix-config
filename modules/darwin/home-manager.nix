{
  config,
  inputs,
  ...
}:

{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  # `../home` holds the portable user-scope modules, and `../home/darwin`
  # holds the modules that depend on a macOS interface. Only this host imports
  # the second list.
  home-manager.users.${config.host.username}.imports = [
    ../home
    ../home/darwin
  ];
}
