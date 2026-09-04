{
  host,
  inputs,
  pkgs,
}:
# `nixos-rebuild switch --flake .#korolev` selects this configuration by name,
# because WSL reports no stable hostname before activation.
let
  hostname = host.name;
  inherit (host) username;
  ompExecutable = host.ompRuntime.executable;
  ompInstallCommand = host.ompRuntime.installCommand;
in
inputs.nixpkgs.lib.nixosSystem {
  specialArgs = {
    inherit
      inputs
      hostname
      ompExecutable
      ompInstallCommand
      username
      ;
  };
  modules = [
    # The flake instantiates one package set per system and hands it to the
    # host, so this host resolves a package exactly as the flake outputs do.
    # `nixpkgs.pkgs` also fixes the platform, which is why no `system`
    # argument and no `nixpkgs.hostPlatform` declaration appears here.
    { nixpkgs.pkgs = pkgs; }

    ../../modules/nixos

    # Values that differ per machine. `modules/home/` declares no identity, so
    # this host supplies its own here.
    {
      home-manager.users.${username} = {
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

          # Personal repositories use the GitHub no-reply address instead.
          # `programs.git.settings.ghq.root` is `~/src`, and ghq lays a clone
          # out as `~/src/<host>/<owner>/<repo>`, so this condition selects the
          # personal owner and nothing else. A clone placed anywhere else, such
          # as directly under `~/src`, keeps the employer address above.
          includes = [
            {
              condition = "gitdir:~/src/github.com/glockyco/";
              contents.user.email = "11704293+glockyco@users.noreply.github.com";
            }
          ];
        };
      };
    }
  ];
}
