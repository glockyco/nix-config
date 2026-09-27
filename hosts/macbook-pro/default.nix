{ config, ... }:
{
  imports = [
    ./host.nix
    ../../modules/fleet
    ../../modules/darwin
    ../../modules/roles/darwin/desktop
    ../../modules/roles/darwin/postgresql
    ../../modules/roles/darwin/container-client
    ../../modules/roles/darwin/air-client
  ];

  home-manager.users.${config.host.username} = { config, ... }: {
    programs.git.settings.user = {
      name = config.host.git.authorName;

      # Use the GitHub no-reply address without exposing a mailbox.
      email = config.host.git.defaultEmail;
    };

    # `git` and `gh` share the same editor.
    home.sessionVariables.EDITOR = "zed --wait";
  };
}
