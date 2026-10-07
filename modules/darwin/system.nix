{
  config,
  inputs,
  pkgs,
  ...
}:

let
  inherit (config.host) name username;
in
{
  # `nixpkgs.hostPlatform` and `nixpkgs.overlays` are absent on purpose. The
  # flake supplies a complete package set through `nixpkgs.pkgs`, which fixes
  # both, and declaring either here is an evaluation error.
  system.stateVersion = 7;

  # `system.primaryUser` is required by options targeting a user's macOS
  # defaults, including `homebrew.*`.
  system.primaryUser = username;

  # Expose the active commit in `darwin-version`.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Keep `localHostName` aligned with the flake attribute used by
  # `darwin-rebuild --flake .`.
  networking = {
    computerName = config.host.displayName;
    hostName = name;
    localHostName = name;

    # Stealth mode blocks ICMP pings and probes to closed ports.
    applicationFirewall = {
      enable = true;
      enableStealthMode = true;
    };
  };

  users.users.${username} = {
    name = username;
    home = config.host.homeDirectory;
  };

  # Install git system-wide so root has it during `darwin-rebuild switch`; user
  # configuration is owned by the portable chezmoi source.
  environment.systemPackages = [ pkgs.git ];

  # GUI apps do not inherit the interactive zsh profile. Persist Nix discovery
  # for user launchd domains across reboots; repository hooks keep pinned tools.
  system.activationScripts.postActivation.text = ''
    /bin/launchctl config user path '/usr/bin:/bin:/usr/sbin:/sbin:/nix/var/nix/profiles/default/bin'
  '';

  # Use Touch ID for sudo, including `sudo darwin-rebuild switch`; nix-darwin
  # writes `/etc/pam.d/sudo_local`.
  security.pam.services.sudo_local.touchIdAuth = true;
}
