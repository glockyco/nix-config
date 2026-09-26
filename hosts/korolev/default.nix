{ config, ... }:
{
  # `nixos-rebuild switch --flake .#korolev` selects this configuration by name,
  # because WSL reports no stable hostname before activation.
  imports = [
    ./host.nix
    ../../modules/fleet
    ../../modules/nixos
  ];

  home-manager.users.${config.host.username} = {
    # This host holds no GitHub key, because it declares no secret and
    # copies no key. `gh` therefore drives Git over HTTPS here, and its
    # declared credential helper answers the prompt. `modules/home/gh.nix`
    # keeps `ssh` for the Darwin host, which does hold a key.
    programs.gh.settings.git_protocol = "https";

    programs.git = {
      settings.user = {
        name = "Johann Glock";

        # The employer address is the default on this machine, because most
        # work here belongs to the employer.
        email = "johann.glock@scch.at";
      };

      # Every GitHub repository uses the no-reply address instead.
      # `programs.git.settings.ghq.root` is `~/src`, and ghq lays a clone
      # out as `~/src/<host>/<owner>/<repo>`, so this condition selects the
      # complete GitHub host tree. Repositories under other hosts, or
      # directly under `~/src`, keep the employer address above.
      includes = [
        {
          condition = "gitdir:~/src/github.com/";
          contents.user.email = "11704293+glockyco@users.noreply.github.com";
        }
      ];
    };
  };
}
