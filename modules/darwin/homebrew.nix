{
  inputs,
  username,
  ...
}:

{
  imports = [ inputs.nix-homebrew.darwinModules.nix-homebrew ];

  # nix-homebrew owns the Homebrew *installation*: it creates /opt/homebrew and
  # points it at a pinned Homebrew/brew checkout from the Nix store. Homebrew's
  # own curl-into-bash installer is never run, and `brew update-self` is disabled.
  nix-homebrew = {
    enable = true;
    user = username;

    # Apple Silicon only. Setting this would additionally provision an
    # x86_64 prefix under /usr/local and require Rosetta.
    enableRosetta = false;

    # Taps stay mutable, which keeps Homebrew on its JSON metadata API. Pinning
    # homebrew-core and homebrew-cask as flake inputs is the fully reproducible
    # alternative, but it drags hundreds of megabytes through the store on every
    # update for very little practical benefit here.
    mutableTaps = true;
  };

  # nix-darwin owns *what* Homebrew installs, via a generated Brewfile.
  homebrew = {
    enable = true;

    casks = [
      # Karabiner-Elements provides Neo2 layers 3-6. The cask is the right
      # mechanism: it installs the vendor-signed pkg at the vendor's paths,
      # which is what the DriverKit virtual-HID system extension needs in order
      # to be approvable. nixpkgs lags upstream and nix-darwin's
      # `services.karabiner-elements` has been broken since Karabiner 15.
      "karabiner-elements"

      # Terminal. Not available from nixpkgs on aarch64-darwin, and the
      # official Neo2 Karabiner rules already whitelist com.mitchellh.ghostty
      # for layer-4 Home/End.
      "ghostty"
    ];

    onActivation = {
      # Uninstall anything not declared above. Deliberately not "zap", which
      # would also delete ~/.config/karabiner.
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = false;
    };
  };
}
