# Container Runtime Specification

## Purpose

Provides a Docker-compatible container interface for local development and verification workloads: Colima on the Apple Silicon workstation and Docker Desktop on native Windows Korolev.

## Requirements

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

The workstation SHALL provide reviewed Colima profile defaults that use Apple Virtualization.framework and Rosetta for `linux/amd64` execution. Shared host TOML facts validated through `hosts/macbook-pro/host.nix` SHALL own the profile's positive CPU, memory, disk and mount values; chezmoi SHALL render the user profile. The system-owned `container-client` resource manifest SHALL derive profile architecture from `pkgs.stdenv.hostPlatform.qemuArch`. The role SHALL declare its runtime rather than rely on changing upstream defaults.

#### Scenario: Native container execution

- **WHEN** the declared profile is running and the user starts a `linux/arm64` smoke container
- **THEN** the container exits successfully and reports the ARM64 architecture

#### Scenario: Intel container execution

- **WHEN** the declared profile is running and the user starts a `linux/amd64` smoke container
- **THEN** the container exits successfully under Rosetta and reports the AMD64 architecture

#### Scenario: Change a reviewed resource value

- **WHEN** the host changes one declared CPU, memory, disk, or mount value
- **THEN** the generated Colima profile and its configuration check use the new value
- **AND** neither consumer needs a matching literal edit

#### Scenario: Evaluate for Apple Silicon

- **WHEN** the Darwin host evaluates on `aarch64-darwin`
- **THEN** the rendered chezmoi profile architecture derives from the package set's host platform through its resource manifest
- **AND** no module repeats the architecture string

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

Colima virtual machine disks, images, containers, volumes, credentials, and logs SHALL remain mutable runtime state outside the Nix store. Rebuilding, system activation and chezmoi apply SHALL preserve that state; chezmoi SHALL own only the declared user profile and environment files.

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

### Requirement: Container runtime on native Windows Korolev

Korolev SHALL use repository-declared native Docker Desktop, supplying Docker CLI/Compose as a self-updating machine-scope exception with owner-approved UAC and no version pin or downgrade. Intune SHALL remain the update-only owner, not the initial installer. Owner/employer licensing confirmation SHALL precede installation. Project repositories SHALL own images/Compose/toolchains; Mac Colima SHALL remain unchanged.

#### Scenario: Inspect Windows runtime ownership

- **WHEN** the owner prepares native container work on Korolev
- **THEN** Docker.DockerDesktop has one native document declaration and is removed from the managed-applications exclusions with the dated update-only Intune evidence
- **AND** the machine-scope resource uses self-updating policy without a version pin or downgrade of a newer installed release
- **AND** docker and docker compose resolve natively and identify the intended Docker Desktop engine/context

#### Scenario: Run a native project workload

- **WHEN** an accepted native checkout starts its declared Docker image or Compose workload
- **THEN** required builds, mounts and service behavior work against Docker Desktop without the retired NixOS distribution
- **AND** test-generalization uses its own project-owned Docker image as its toolchain

#### Scenario: Repository-declared runtime installation fails

- **WHEN** the declared Docker Desktop installation or required engine readiness fails
- **THEN** the operation reports failure and blocks native container-project migration
- **AND** no WSL-host fallback or competing runtime silently satisfies acceptance

#### Scenario: Confirm licensing before installation

- **WHEN** Docker Desktop installation is requested
- **THEN** the owner/employer confirms required subscription entitlement before the installer runs
- **AND** the Intune update package alone is not accepted as licensing confirmation

#### Scenario: Install with owner-assisted elevation

- **WHEN** licensing is confirmed and the owner authorizes the declared initial installation
- **THEN** only the Docker installer uses its approved machine-scope UAC prompt with owner-typed credentials
- **AND** ordinary chezmoi/user-file work remains in the standard account
- **AND** a bounded native Docker Compose smoke passes before projects migrate

#### Scenario: Retire the project distribution

- **WHEN** the owner unregisters the backed-up NixOS distribution
- **THEN** Docker Desktop engine-owned distributions and mutable containers, volumes and images remain untouched
