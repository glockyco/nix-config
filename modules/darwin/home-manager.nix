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

    # `../home` holds the portable user-scope modules, and `../home/darwin`
    # holds the modules that depend on a macOS interface. Only this host imports
    # the second list.
    users.${username}.imports = [
      ../home
      ../home/darwin
    ];
  };
}
