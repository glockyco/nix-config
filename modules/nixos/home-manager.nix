{
  inputs,
  ompExecutable,
  ompInstallCommand,
  username,
  ...
}:

{
  imports = [ inputs.home-manager.nixosModules.home-manager ];

  home-manager = {
    # Share the system's nixpkgs instance.
    useGlobalPkgs = true;

    # Install user packages in `/etc/profiles/per-user/<user>` rather than an
    # imperative `~/.nix-profile`.
    useUserPackages = true;

    # Move conflicting dotfiles aside instead of aborting activation.
    backupFileExtension = "hm-backup";

    # `../home` modules read these. `omp.nix` also needs the platform-owned
    # executable path and its installation command.
    extraSpecialArgs = {
      inherit
        inputs
        ompExecutable
        ompInstallCommand
        username
        ;
    };

    # Only the portable list. `../home/darwin` is absent here, so a module that
    # names a macOS interface cannot reach this host.
    users.${username}.imports = [ ../home ];
  };
}
