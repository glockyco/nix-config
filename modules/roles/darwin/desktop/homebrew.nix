{
  config,
  inputs,
  ...
}:

let
  inherit (config.host) username;
in
{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  # nix-homebrew manages the `/opt/homebrew` installation and disables `brew update-self`.
  nix-homebrew = {
    enable = true;
    user = username;

    # Apple Silicon only; enabling Rosetta would provision `/usr/local`.
    enableRosetta = false;

    # Keep taps mutable instead of pinning `homebrew-core` and `homebrew-cask` as flake inputs.
    mutableTaps = true;
  };

  # nix-darwin declares installed casks via a generated Brewfile.
  homebrew = {
    enable = true;

    taps = [ "can1357/tap" ];

    brews = [
      # Retain the official installation for pre-cutover Nix generations.
      # The source-generation wrapper does not use this executable.
      "can1357/tap/omp"
    ];

    casks = map (application: application.cask) (
      builtins.filter (application: application.cask != null) config.host.darwin.applications
    );

    onActivation = {
      # `cleanup = "uninstall"` avoids `zap`, which would delete `~/.config/karabiner`.
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = false;
    };
  };
}
