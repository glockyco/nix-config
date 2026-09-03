{
  # Project work uses prebuilt executables that expect a conventional dynamic
  # loader: .NET tooling, Unity, and game loader toolchains. `nix-ld` supplies
  # that loader, which replaces the escape hatch a distribution package manager
  # would otherwise provide.
  programs.nix-ld.enable = true;

  # `EDITOR` must name a program this host provides, and the portable user
  # modules carry no editor: the Darwin host uses Zed, and on this machine the
  # Windows layer owns that. `nano` is not in the NixOS default package set, so
  # it is declared here rather than assumed.
  programs.nano.enable = true;

  # `modules/home/shell.nix` configures zsh for the user. Enabling it here
  # registers zsh as a login shell, which `users.users.<name>.shell` needs.
  programs.zsh.enable = true;
}
