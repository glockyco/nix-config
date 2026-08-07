{
  inputs,
  hostname,
  pkgs,
  username,
  ...
}:

{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.overlays = [ inputs.self.overlays.default ];

  # Current nix-darwin state version (`system.maxStateVersion`).
  system.stateVersion = 7;

  # Required by every option that touches a specific user's macOS defaults,
  # `homebrew.*` among them.
  system.primaryUser = username;

  # Shows up in `darwin-version`, which makes it obvious which commit is live.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Own the machine's identity declaratively. `localHostName` is what
  # `darwin-rebuild --flake .` uses to pick the configuration, so it has to
  # agree with the attribute name in flake.nix.
  networking = {
    computerName = "MacBook Pro";
    hostName = hostname;
    localHostName = hostname;
  };

  # `home` is mandatory here: the Home Manager nix-darwin module derives
  # `home.homeDirectory` from it.
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # System-wide git, so root has one during `darwin-rebuild switch` and the
  # machine is usable before Home Manager has ever run. The user-facing
  # configuration lives in modules/home/git.nix.
  environment.systemPackages = [ pkgs.git ];

  # Authenticate `sudo` with Touch ID, including `sudo darwin-rebuild switch`.
  # nix-darwin writes /etc/pam.d/sudo_local, which macOS updates leave alone.
  security.pam.services.sudo_local.touchIdAuth = true;
}
