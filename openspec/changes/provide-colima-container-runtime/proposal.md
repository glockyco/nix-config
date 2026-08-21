## Why

The workstation cannot run the repository's Docker Compose verification workflows because it has no local Linux container runtime. A Docker-compatible Colima runtime preserves the project's established interface while keeping executable installation declarative, open source, and independent of Docker Desktop.

## What Changes

- Install Colima, the Docker client, and Docker Compose through the pinned Nixpkgs input.
- Expose the Compose plugin through the `docker compose` interface used by project repositories.
- Define a Colima profile for Apple Virtualization.framework with Rosetta support for `linux/amd64` workloads on Apple Silicon.
- Keep VM creation, startup, images, volumes, and container data outside Nix activation and under Colima's mutable runtime state.
- Add focused checks for native and `linux/amd64` execution, Compose service health, arbitrary Compose project names, and explicit runtime shutdown.
- Document the runtime boundary and operator lifecycle without introducing Docker Desktop, a global Docker socket link, or automatic startup.

## Capabilities

### New Capabilities

- `container-runtime`: Provides a declaratively installed Docker-compatible container interface backed by a user-managed Colima virtual machine.

### Modified Capabilities

None.

## Impact

- Adds pinned workstation dependencies from Nixpkgs.
- Adds a Home Manager or Darwin module for container clients and Colima profile defaults.
- Adds checks that exercise Docker CLI plugin discovery and the real Apple Silicon runtime boundary.
- Adds operator guidance for startup, status, shutdown, storage, upgrades, and recovery.
- Creates mutable Colima VM and Docker state only when the user starts the runtime.
