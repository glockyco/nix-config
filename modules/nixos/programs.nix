{
  # Project work uses prebuilt executables that expect a conventional dynamic
  # loader: .NET tooling, Unity, and game loader toolchains. `nix-ld` supplies
  # that loader, which replaces the escape hatch a distribution package manager
  # would otherwise provide.
  programs.nix-ld.enable = true;
}
