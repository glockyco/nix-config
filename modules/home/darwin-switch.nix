{
  config,
  lib,
  pkgs,
  ...
}:

let
  flake = "${config.home.homeDirectory}/.config/nix-darwin";
in

{
  # `darwin-rebuild switch` reports that it activated a generation, but not
  # what actually changed. This wraps it and diffs the closure afterwards, so a
  # switch shows which packages moved and how the closure size changed.
  home.packages = [
    (pkgs.writeShellApplication {
      name = "darwin-switch";
      runtimeInputs = [ pkgs.nvd ];
      text = ''
        before=$(readlink -f /run/current-system)

        # `sudo` rather than requiring the caller to be root, so that nvd below
        # still runs as the user.
        sudo darwin-rebuild switch --flake ${lib.escapeShellArg flake} "$@"

        after=$(readlink -f /run/current-system)

        if [ "$before" = "$after" ]; then
          echo "darwin-switch: closure unchanged"
        else
          nvd diff "$before" "$after"
        fi
      '';
    })
  ];
}
