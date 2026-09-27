{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./wsl.nix
    ./tailscale.nix
    ./programs.nix
    ./containers.nix
    ./builders.nix
  ];

  users.users.${config.host.username}.shell = pkgs.zsh;

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    settings = {
      default-cache-ttl = 86400;
      max-cache-ttl = 604800;
    };
  };

  home-manager.users.${config.host.username} = {
    home.packages = [
      pkgs.wsl-open
      pkgs.git-credential-manager
      pkgs.gnupg
      pkgs.pass
    ];

    programs.zsh.initContent = lib.mkAfter ''
      if [[ -t 0 ]]; then
        export GPG_TTY=$(tty)
      fi
    '';

    programs.git.settings.credential = {
      helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
      credentialStore = "gpg";
      "https://git.overleaf.com".provider = "generic";
    };
  };
}
