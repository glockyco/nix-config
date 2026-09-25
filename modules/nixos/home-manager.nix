{
  config,
  inputs,
  pkgs,
  ...
}:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  services.gnome.gnome-keyring.enable = true;

  home-manager.users.${config.host.username} = {
    # Only the portable list. `../home/darwin` is absent here, so a module that
    # names a macOS interface cannot reach this host.
    imports = [ ../home ];

    home.packages = [
      pkgs.wsl-open
      pkgs.git-credential-manager
    ];

    programs.git.settings.credential = {
      helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      credentialStore = "secretservice";
    };
  };
}
