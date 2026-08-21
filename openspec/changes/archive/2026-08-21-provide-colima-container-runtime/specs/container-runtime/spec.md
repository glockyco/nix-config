## Purpose

Provides a reproducible Docker-compatible container interface for local development and verification workloads on the Apple Silicon workstation.

## ADDED Requirements

### Requirement: Declarative container client installation

The workstation configuration SHALL install `colima`, `docker`, and a Compose plugin from the pinned Nixpkgs input. The installed Docker client SHALL expose Compose through `docker compose` without requiring an application bundle or an imperative plugin installation.

#### Scenario: Container clients are available after activation

- **WHEN** the user activates a successfully built workstation generation
- **THEN** `colima`, `docker`, and `docker compose version` resolve from Nix-managed paths

#### Scenario: Compose plugin discovery does not depend on mutable state

- **WHEN** the user has no Compose plugin under the mutable Docker configuration directory
- **THEN** `docker compose version` still succeeds through the Nix-managed plugin

### Requirement: User-controlled runtime lifecycle

Workstation activation SHALL NOT create, start, reset, or delete a Colima virtual machine. The user SHALL be able to start, inspect, stop, and delete the declared profile through documented commands.

#### Scenario: Activation leaves the runtime stopped

- **WHEN** the Colima profile does not exist and the user activates the workstation configuration
- **THEN** activation completes without creating or starting a Colima virtual machine

#### Scenario: User starts and stops the runtime

- **WHEN** the user follows the documented start and stop procedure
- **THEN** the Docker endpoint becomes available after start and becomes unavailable after stop

### Requirement: Declared Apple Silicon runtime profile

The workstation SHALL provide reviewed Colima profile defaults that use Apple Virtualization.framework and Rosetta for `linux/amd64` execution. The profile SHALL declare its CPU, memory, disk, mount, runtime, and architecture settings rather than relying on changing upstream defaults.

#### Scenario: Native container execution

- **WHEN** the declared profile is running and the user starts a `linux/arm64` smoke container
- **THEN** the container exits successfully and reports the ARM64 architecture

#### Scenario: Intel container execution

- **WHEN** the declared profile is running and the user starts a `linux/amd64` smoke container
- **THEN** the container exits successfully under Rosetta and reports the AMD64 architecture

### Requirement: Docker Compose workload compatibility

The runtime SHALL support the Docker Compose behaviors used by project repositories, including image builds, health conditions, named volumes, bind mounts, published loopback ports, service execution, file copy, and explicit project names.

#### Scenario: Stateful Compose workload becomes healthy

- **WHEN** the user starts the acceptance Compose project under a nondefault project name
- **THEN** its database service becomes healthy, its loopback port accepts connections, and its named volume persists across a service restart

#### Scenario: Compose service operations work

- **WHEN** the acceptance project is healthy
- **THEN** `docker compose exec`, `docker compose cp`, and `docker compose run --rm` complete successfully against its services

#### Scenario: Project cleanup is isolated

- **WHEN** the user removes the acceptance project with its declared volumes
- **THEN** resources owned by a different Compose project remain unchanged

### Requirement: Explicit Docker endpoint ownership

Starting the declared profile SHALL expose a named Docker context that identifies Colima as the active endpoint. The workstation configuration SHALL NOT create a global `/var/run/docker.sock` link and SHALL NOT silently select an unrelated local or remote Docker endpoint.

#### Scenario: Runtime identity is visible

- **WHEN** the declared profile is running
- **THEN** Docker status output identifies the Colima context and the expected Linux engine architecture

#### Scenario: Runtime is stopped

- **WHEN** the declared profile is stopped
- **THEN** a Docker workload command fails instead of running against an unrelated endpoint

### Requirement: Mutable runtime state remains outside Nix activation

Colima virtual machine disks, images, containers, volumes, credentials, and logs SHALL remain mutable runtime state outside the Nix store. Rebuilding or activating the same workstation declaration SHALL preserve that state.

#### Scenario: Workstation generation changes

- **WHEN** the user activates a new workstation generation without changing the runtime profile identity
- **THEN** existing Colima images, containers, and volumes remain available

#### Scenario: Explicit destructive cleanup

- **WHEN** the user invokes the documented profile deletion command
- **THEN** the command identifies the mutable state that it removes and does not modify Nix generations

### Requirement: Bounded verification and recovery guidance

The workstation documentation SHALL define startup, readiness, status, shutdown, upgrade, storage inspection, failed-start recovery, and profile recreation procedures. Verification SHALL use bounded commands and SHALL stop resources that it starts.

#### Scenario: Runtime verification succeeds

- **WHEN** the user runs the documented acceptance procedure on a healthy configuration
- **THEN** it proves client discovery, both image architectures, Compose health, service operations, isolation, and shutdown

#### Scenario: Runtime verification fails

- **WHEN** one acceptance step fails or exceeds its bound
- **THEN** the procedure reports the failed boundary and provides a cleanup command for resources it created
