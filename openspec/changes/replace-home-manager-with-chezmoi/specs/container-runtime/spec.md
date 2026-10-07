# Spec Delta

## MODIFIED Requirements

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

### Requirement: Mutable runtime state remains outside Nix activation

Colima virtual machine disks, images, containers, volumes, credentials, and logs SHALL remain mutable runtime state outside the Nix store. Rebuilding, system activation and chezmoi apply SHALL preserve that state; chezmoi SHALL own only the declared user profile and environment files.

#### Scenario: Workstation generation changes

- **WHEN** the user activates a new workstation generation without changing the runtime profile identity
- **THEN** existing Colima images, containers, and volumes remain available

#### Scenario: Explicit destructive cleanup

- **WHEN** the user invokes the documented profile deletion command
- **THEN** the command identifies the mutable state that it removes and does not modify Nix generations
