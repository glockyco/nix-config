{ pkgs, ... }:
{
  # The Darwin host runs Colima, which exists because macOS needs a Linux
  # virtual machine to run containers. WSL 2 already provides that machine, so
  # this host needs no second one and no nested virtualization.
  virtualisation.podman = {
    enable = true;

    # Provides the `docker` command, so a project command that names Docker
    # keeps working without a Windows container product. Intune manages Docker
    # Desktop on this machine, and a declaration here would collide with it.
    dockerCompat = true;

    # No /run/docker.sock link to the root-only system API socket. The module's
    # socket-activated API sockets stay local: the user's lives in its 0700
    # runtime directory, the system one belongs to root and an empty podman
    # group. Neither is a container service another host can reach.
    dockerSocket.enable = false;
  };

  # `docker compose` reaches `podman compose`, which runs this provider against
  # the user's API socket. The explicit path keeps a PATH search from choosing
  # podman-compose, which starts a service even when a dependency it must wait
  # for has failed. The banner would otherwise precede every Compose command.
  virtualisation.containers.containersConf.settings.engine = {
    compose_providers = [ "${pkgs.docker-compose}/bin/docker-compose" ];
    compose_warning_logs = false;
  };
}
