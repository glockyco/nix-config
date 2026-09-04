{
  inputs,
  name,
  pkgs,
}:
# `darwin-rebuild --flake .` resolves `darwinConfigurations.<LocalHostName>` after activation.
let
  username = "glockyco";
in
inputs.nix-darwin.lib.darwinSystem {
  specialArgs = { inherit inputs; };
  modules = [
    # The flake instantiates one package set per system and hands it to the
    # host, so the host and the flake outputs cannot resolve a package
    # differently. This also fixes the platform and the overlay list, which is
    # why no module here declares either.
    { nixpkgs.pkgs = pkgs; }

    ../../modules/fleet
    ../../modules/darwin

    # Values that differ per machine. `modules/home/` declares no identity and
    # names no application, so another host can select the same modules and
    # supply its own values here.
    {
      host = {
        inherit name username;
        tailnet.tag = "tag:macbook-pro";
        ompRuntime = {
          executable.absolute = "/opt/homebrew/bin/omp";
          installCommand = "brew install can1357/tap/omp";
        };
      };

      home-manager.users.${username} = {
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
  ];
}
