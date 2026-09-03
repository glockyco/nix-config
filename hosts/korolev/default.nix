{ inputs }:
# `nixos-rebuild switch --flake .#korolev` selects this configuration by name,
# because WSL reports no stable hostname before activation.
let
  hostname = "korolev";
  username = "user";
in
inputs.nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  specialArgs = { inherit inputs hostname username; };
  modules = [
    ../../modules/nixos

    # Values that differ per machine. `modules/home/` declares no identity, so
    # this host supplies its own here.
    {
      home-manager.users.${username} = {
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
