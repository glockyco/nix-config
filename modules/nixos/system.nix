{
  hostname,
  inputs,
  username,
  ...
}:

{
  networking.hostName = hostname;

  # Matches the pinned nixpkgs release; changing it changes option defaults.
  system.stateVersion = "26.05";

  # Expose the active commit in `nixos-version`, as `modules/darwin/system.nix`
  # does for `darwin-version`. This value enters the system derivation, so the
  # system path moves with every commit. A closure diff is therefore the way to
  # compare two generations; a store-path comparison reports every commit as a
  # change.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";

    # `wheel` allows `sudo`, which `nixos-rebuild switch` needs. The host adds
    # no other group, because it runs no service that requires one.
    extraGroups = [ "wheel" ];
  };
}
