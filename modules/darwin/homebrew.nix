{
  inputs,
  username,
  ...
}:

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

    casks = [
      # The vendor cask supplies the signed pkg required by Karabiner's DriverKit extension.
      "karabiner-elements"

      # Match the official Neo2 rules for `com.mitchellh.ghostty`.
      "ghostty"

      # Fork is proprietary; use the Homebrew cask.
      "fork"

      # Use vendor casks so browser security updates follow vendor releases, not flake updates.
      # Brave is required for the Chrome-only browser relay.
      "zen"
      "brave-browser"

      # Thunderbird is a Firefox-scale C++/Rust build. Use Mozilla's signed
      # binary and updater instead of risking a nixpkgs source build on Darwin.
      "thunderbird"

      # Secretive needs a signed app bundle for Secure Enclave and Touch ID entitlements.
      "secretive"

      # The cask bundles the Safari extension (`Contents/PlugIns/safari.appex`), so no
      # Mac App Store copy is needed.
      "bitwarden"

      # Use the cask so Zed's vendor updater follows its release cadence.
      "zed"

      "discord"

      "ticktick"

      # Rectangle Pro retains bundle id `com.knollsoft.Hookshot` from Hookshot.
      "rectangle-pro"

      "crossover"
    ];

    onActivation = {
      # `cleanup = "uninstall"` avoids `zap`, which would delete `~/.config/karabiner`.
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = false;
    };
  };
}
