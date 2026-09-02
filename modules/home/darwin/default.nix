{
  # User-scope modules that depend on a macOS interface: `launchd` agents,
  # LaunchServices, `osascript`, `~/Library` paths, an `NSKeyedArchiver` font
  # blob, `com.apple.symbolichotkeys`, the Secretive agent socket, a
  # Homebrew-supplied binary, or `darwin-rebuild`. Only the Darwin host imports
  # this list; `../default.nix` holds the modules that any host can use.
  #
  # `./catppuccin.nix` holds the theme ports for the programs in this directory.
  imports = [
    ./catppuccin.nix
    ./container-runtime.nix
    ./darwin-switch.nix
    ./secrets.nix
    ./fastmail.nix
    ./ghostty.nix
    ./brave.nix
    ./apple-terminal.nix
    ./default-apps.nix
    ./ssh.nix
    ./network-shares.nix
    ./neo2.nix
    ./karabiner.nix
    ./keyboard-shortcuts.nix
    ./screenshots.nix
  ];
}
