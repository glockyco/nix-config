{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager.users.${config.host.username} = {
    # Only the portable list. `../home/darwin` is absent here, so a module that
    # names a macOS interface cannot reach this host.
    imports = [ ../home ];

    home.packages = [ pkgs.wsl-open ];
  };
}
