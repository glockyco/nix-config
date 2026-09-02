{ inputs }:
# `darwin-rebuild --flake .` resolves `darwinConfigurations.<LocalHostName>` after activation.
let
  hostname = "macbook-pro";
  username = "glockyco";
in
inputs.nix-darwin.lib.darwinSystem {
  specialArgs = { inherit inputs hostname username; };
  modules = [
    ../../modules/darwin

    # Values that differ per machine. `modules/home/` declares no identity and
    # names no application, so another host can select the same modules and
    # supply its own values here.
    {
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
