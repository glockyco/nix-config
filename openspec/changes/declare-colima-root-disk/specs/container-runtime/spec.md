# Spec Delta

## MODIFIED Requirements

### Requirement: Declared Apple Silicon runtime profile

The workstation SHALL provide reviewed Colima profile defaults that use Apple Virtualization.framework and Rosetta for `linux/amd64` execution. Shared host TOML facts validated through `hosts/macbook-pro/host.nix` SHALL own the profile's positive CPU, memory, disk, root disk and mount values; chezmoi SHALL render the user profile. The system-owned `container-client` resource manifest SHALL derive profile architecture from `pkgs.stdenv.hostPlatform.qemuArch`. The role SHALL declare its runtime rather than rely on changing upstream defaults.

#### Scenario: Native container execution

- **WHEN** the declared profile is running and the user starts a `linux/arm64` smoke container
- **THEN** the container exits successfully and reports the ARM64 architecture

#### Scenario: Intel container execution

- **WHEN** the declared profile is running and the user starts a `linux/amd64` smoke container
- **THEN** the container exits successfully under Rosetta and reports the AMD64 architecture

#### Scenario: Change a reviewed resource value

- **WHEN** the host changes one declared CPU, memory, disk, root disk, or mount value
- **THEN** the generated Colima profile and its configuration check use the new value
- **AND** neither consumer needs a matching literal edit

#### Scenario: Evaluate for Apple Silicon

- **WHEN** the Darwin host evaluates on `aarch64-darwin`
- **THEN** the rendered chezmoi profile architecture derives from the package set's host platform through its resource manifest
- **AND** no module repeats the architecture string

#### Scenario: Start an existing virtual machine

- **WHEN** the user starts the profile's existing virtual machine after an apply
- **THEN** the rendered profile names the declared root disk size
- **AND** Colima does not try to shrink the root disk
