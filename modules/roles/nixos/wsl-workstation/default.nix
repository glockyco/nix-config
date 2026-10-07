{
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./wsl.nix
    ./programs.nix
    ./containers.nix
    ./builders.nix
    ./fonts.nix
  ];

  host.importedRoles.wslWorkstation = true;

  users.users.${config.host.username} = {
    shell = pkgs.zsh;
    home = config.host.homeDirectory;
    packages = [
      pkgs.wsl-open
      pkgs.git-credential-manager
      pkgs.gnupg
      pkgs.pass
    ];
  };

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    settings = {
      default-cache-ttl = 86400;
      max-cache-ttl = 604800;
    };
  };

}
