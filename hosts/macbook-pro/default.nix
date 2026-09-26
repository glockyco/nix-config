{ config, ... }:
{
  imports = [
    ./host.nix
    ../../modules/fleet
    ../../modules/darwin
  ];

  home-manager.users.${config.host.username} = {
    programs.git.settings.user = {
      name = "Johann Glock";

      # GitHub's noreply address associates commits with the account
      # without exposing a real mailbox.
      email = "11704293+glockyco@users.noreply.github.com";
    };

    # `git` and `gh` both fall back to this, so the editor is named once
    # rather than per program.
    home.sessionVariables.EDITOR = "zed --wait";
  };
}
