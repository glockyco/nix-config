{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  flake = config.host.paths.configurationCheckout;
  darwinRebuild = inputs.nix-darwin.packages.${pkgs.stdenv.hostPlatform.system}.darwin-rebuild;
in

{
  # `darwin-rebuild switch` reports that it activated a generation, but not
  # what actually changed. This wraps it and diffs the closure afterwards, so a
  # switch shows which packages moved and how the closure size changed.
  home.packages = lib.mkOrder 600 [
    (pkgs.writeShellApplication {
      name = "darwin-switch";
      runtimeInputs = [ pkgs.nvd ];
      text = ''
        before=$(readlink -f /run/current-system)

        # `sudo` rather than requiring the caller to be root, so that nvd below
        # still runs as the user.
        sudo ${lib.getExe darwinRebuild} switch --flake ${lib.escapeShellArg flake} "$@"

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
