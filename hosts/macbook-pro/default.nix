{
  imports = [
    ./host.nix
    ../../modules/fleet
    ../../modules/darwin
    ../../modules/roles/darwin/desktop
    ../../modules/roles/darwin/postgresql
    ../../modules/roles/darwin/container-client
    ../../modules/roles/darwin/air-client
  ];

}
