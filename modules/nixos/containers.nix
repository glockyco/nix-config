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

    # No socket. Rootless containers run as the interactive user, and a socket
    # would be a listening endpoint this host declares it does not have.
    dockerSocket.enable = false;
  };
}
