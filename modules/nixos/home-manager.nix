{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  programs.gnupg.agent = {
    enable = true;
    pinentryPackage = pkgs.pinentry-curses;
    settings = {
      default-cache-ttl = 86400;
      max-cache-ttl = 604800;
    };
  };

  home-manager.users.${config.host.username} = {
    # Only the portable list. `../home/darwin` is absent here, so a module that
    # names a macOS interface cannot reach this host.
    imports = [ ../home ];

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
