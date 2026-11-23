{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.host) username;
  masApplications = builtins.filter (
    application: application.masId != null
  ) config.host.darwin.applications;
in
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  environment.systemPackages = lib.optional (masApplications != [ ]) pkgs.mas;

  # nix-homebrew manages the `/opt/homebrew` installation and disables `brew update-self`.
  nix-homebrew = {
    enable = true;
    user = username;

    # Apple Silicon only; enabling Rosetta would provision `/usr/local`.
    enableRosetta = false;

    # Keep taps mutable instead of pinning `homebrew-core` and `homebrew-cask` as flake inputs.
    mutableTaps = true;
  };

  # nix-darwin declares casks and Mac App Store apps via a generated Brewfile.
  homebrew = {
    enable = true;

    casks = map (application: application.cask) (
      builtins.filter (application: application.cask != null) config.host.darwin.applications
    );

    masApps = builtins.listToAttrs (
      map (application: lib.nameValuePair application.masName application.masId) masApplications
    );

    onActivation = {
      # `cleanup = "uninstall"` avoids `zap`, which would delete `~/.config/karabiner`.
      cleanup = "uninstall";
      # After an automatic update, brew restarts itself with a reduced PATH that
      # hides mas, and every Mac App Store entry fails. Run brew update by hand
      # before adding a cask that the taps do not know yet.
      autoUpdate = false;
      upgrade = false;
    };
  };
}
