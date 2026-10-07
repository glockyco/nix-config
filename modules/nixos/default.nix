{
  # Platform modules install tools and initialize plugins; chezmoi owns files.
  imports = [
    ./system.nix
    ./nix.nix
    ./programs.nix
    (import ../shared).userEnvironment
  ];
}
