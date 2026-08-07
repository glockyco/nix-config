{
  inputs,
  username,
  ...
}:

{
  imports = [ inputs.home-manager.darwinModules.home-manager ];

  home-manager = {
    # Share the system's nixpkgs instance.
    useGlobalPkgs = true;

    # Install user packages in `/etc/profiles/per-user/<user>` rather than an
    # imperative `~/.nix-profile`.
    useUserPackages = true;

    # Move conflicting dotfiles aside instead of aborting activation.
    backupFileExtension = "hm-backup";

    extraSpecialArgs = { inherit inputs username; };

    users.${username} = import ../home;
  };
}
