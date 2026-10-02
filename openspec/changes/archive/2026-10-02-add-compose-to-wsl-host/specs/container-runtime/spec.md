## MODIFIED Requirements

### Requirement: Container runtime on the WSL host

The WSL host SHALL provide a rootless container runtime that accepts Docker commands. The runtime SHALL run inside the WSL distribution. The workstation SHALL NOT require a Windows container product, and SHALL NOT require nested virtualization. `docker compose` and `podman compose` SHALL run the official Docker Compose from the pinned Nixpkgs input against the user's rootless runtime, without searching `PATH` for another provider and without printing a provider banner.

#### Scenario: Run a container

- **WHEN** the user runs a container image on the WSL host after activation
- **THEN** the container starts and exits with its own status
- **AND** the runtime requires no root privileges and no separate virtual machine

#### Scenario: Use the Docker command name

- **WHEN** a project command invokes the Docker command name
- **THEN** the declared runtime serves that command

#### Scenario: Compose is available after activation

- **WHEN** the user runs `docker compose version` after activation
- **THEN** it reports the Docker Compose version from the pinned Nixpkgs input
- **AND** no `podman-compose` or user-installed plugin is involved

#### Scenario: Compose honors service dependencies

- **WHEN** a Compose service depends on another service completing successfully and that service fails
- **THEN** `docker compose run` does not start the dependent service and exits with a nonzero status

#### Scenario: Compose files stay owned by the user

- **WHEN** a Compose service writes into a bind-mounted directory as the container's root user
- **THEN** the files belong to the invoking WSL user

#### Scenario: Preserve the boundary

- **WHEN** the host configuration is reviewed
- **THEN** it declares no Windows container product
- **AND** it declares no listening container service that another host can reach
- **AND** it creates no `/run/docker.sock`
