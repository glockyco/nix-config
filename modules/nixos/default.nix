{
  # System scope for the WSL host, mirroring `modules/darwin/` for the Darwin
  # host. User scope stays in `modules/home/`, which both hosts share, and
  # `modules/home/darwin/` stays out of this host's reach.
  imports = [
    ./wsl.nix
    ./system.nix
    ./nix.nix
    ./programs.nix
    ./containers.nix
    ./home-manager.nix
  ];
}
