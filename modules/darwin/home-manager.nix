{
  inputs,
  username,
  ...
}:

{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    # One nixpkgs instance, shared with the system configuration.
    useGlobalPkgs = true;

    # Install user packages into /etc/profiles/per-user/<user> rather than a
    # separate imperative ~/.nix-profile.
    useUserPackages = true;

    # Move pre-existing dotfiles aside instead of aborting activation, and allow
    # a later switch to replace a backup left behind by an earlier one.
    backupFileExtension = "hm-backup";

    extraSpecialArgs = { inherit inputs username; };

    users.${username} = import ../home;
  };
}
