{
  # System scope for the WSL host, mirroring `modules/darwin/` for the Darwin
  # host. User scope stays in `modules/home/`, which both hosts share, and
  # `modules/home/darwin/` stays out of this host's reach.
  imports = [
    ./system.nix
    ./nix.nix
    ./home-manager.nix
  ];
}
