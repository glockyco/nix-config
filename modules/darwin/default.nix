{
  imports = [
    ./system.nix
    ./nix.nix
    ./programs.nix
    ./chezmoi-resources.nix
    (import ../shared).userEnvironment
  ];
}
