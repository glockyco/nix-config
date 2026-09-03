{
  inputs,
  hostname,
  pkgs,
  username,
  ...
}:

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
    computerName = "MacBook Pro";
    hostName = hostname;
    localHostName = hostname;

    # Stealth mode blocks ICMP pings and probes to closed ports.
    applicationFirewall = {
      enable = true;
      enableStealthMode = true;
    };
  };

  # Home Manager derives `home.homeDirectory` from `users.users.<name>.home`.
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Install git system-wide so root has it during `darwin-rebuild switch`; user
  # configuration is in `modules/home/git.nix`.
  environment.systemPackages = [ pkgs.git ];

  # Use Touch ID for sudo, including `sudo darwin-rebuild switch`; nix-darwin
  # writes `/etc/pam.d/sudo_local`.
  security.pam.services.sudo_local.touchIdAuth = true;
}
