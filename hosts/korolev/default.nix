{ config, ... }:
{
  # `nixos-rebuild switch --flake .#korolev` selects this configuration by name,
  # because WSL reports no stable hostname before activation.
  imports = [
    ./host.nix
    ../../modules/fleet
    ../../modules/nixos
    ../../modules/roles/nixos/wsl-workstation
  ];

  home-manager.users.${config.host.username} =
    { config, lib, ... }:
    let
      root = config.programs.git.settings.ghq.root;
      home = config.home.homeDirectory;
      gitdir = if lib.hasPrefix "${home}/" root then "~${lib.removePrefix home root}" else root;
    in
    {
      # This host holds no GitHub key; gh drives Git over HTTPS.
      programs.gh.settings.git_protocol = "https";

      programs.git = {
        settings.user = {
          name = config.host.git.authorName;
          email = config.host.git.defaultEmail;
        };

        # ghq lays GitHub clones below its declared root.
        includes = [
          {
            condition = "gitdir:${gitdir}/github.com/";
            contents.user.email = config.host.git.githubNoReplyEmail;
          }
        ];
      };
    };
}
