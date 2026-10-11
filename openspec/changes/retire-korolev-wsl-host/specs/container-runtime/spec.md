# Spec Delta

## REMOVED Requirements

### Requirement: Container runtime on the WSL host

**Reason**: The NixOS-WSL host and its rootless Podman/Compose runtime are retired.
**Migration**: Use Intune-managed Docker Desktop for native Windows projects; retain Mac Colima and its Nix client. Preserve any owner-required old volumes/data in the private WSL backup before unregistering NixOS.

## ADDED Requirements

### Requirement: Container runtime on native Windows Korolev

Korolev SHALL use SCCH Intune-managed Docker Desktop, which provides the native Docker CLI and Docker Compose. Repository configuration SHALL NOT install Docker Desktop or a competing container runtime. Project repositories SHALL own images, Compose declarations and toolchain behavior. Mac Colima SHALL remain unchanged.

#### Scenario: Inspect Windows runtime ownership

- **WHEN** the owner prepares native container work on Korolev
- **THEN** Docker.DockerDesktop remains in the managed-applications exclusion audit and absent from repository install declarations
- **AND** docker and docker compose resolve natively and identify the intended Docker Desktop engine/context

#### Scenario: Run a native project workload

- **WHEN** an accepted native checkout starts its declared Docker image or Compose workload
- **THEN** required builds, mounts and service behavior work against Docker Desktop without the retired NixOS distribution
- **AND** test-generalization uses its own project-owned Docker image as its toolchain

#### Scenario: Managed runtime is unavailable

- **WHEN** Docker Desktop or its required managed engine is unavailable
- **THEN** the procedure reports the employer-managed prerequisite instead of installing a competing package or selecting a WSL-host fallback

#### Scenario: Retire the project distribution

- **WHEN** the owner unregisters the backed-up NixOS distribution
- **THEN** Docker Desktop engine-owned distributions and mutable containers, volumes and images remain untouched
