# Spec Delta

## REMOVED Requirements

### Requirement: Container runtime on the WSL host

**Reason**: The NixOS-WSL host and its rootless Podman/Compose runtime are retired.
**Migration**: Install native Docker Desktop through the repository's self-updating machine-scope declaration after employer licensing confirmation and owner-approved UAC; Intune supplies updates, not initial installation. Retain Mac Colima/Nix clients and preserve owner-required old volumes/data in the private WSL backup before unregistering NixOS.

## ADDED Requirements

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
