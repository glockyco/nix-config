## MODIFIED Requirements

### Requirement: Declared Apple Silicon runtime profile

The workstation SHALL provide reviewed Colima profile defaults that use Apple Virtualization.framework and Rosetta for `linux/amd64` execution. The host declaration SHALL own the profile's CPU, memory, disk, and mount values. The profile architecture SHALL derive from the host platform. The profile SHALL declare its runtime rather than rely on changing upstream defaults.

#### Scenario: Native container execution

- **WHEN** the declared profile is running and the user starts a `linux/arm64` smoke container
- **THEN** the container exits successfully and reports the ARM64 architecture

#### Scenario: Intel container execution

- **WHEN** the declared profile is running and the user starts a `linux/amd64` smoke container
- **THEN** the container exits successfully under Rosetta and reports the AMD64 architecture

#### Scenario: Change a reviewed resource value

- **WHEN** the host changes one declared CPU, memory, disk, or mount value
- **THEN** the generated Colima profile carries the new value
- **AND** the module and its check need no matching literal change

#### Scenario: Evaluate for Apple Silicon

- **WHEN** the Darwin host evaluates on `aarch64-darwin`
- **THEN** the profile architecture derives from the package set's host platform
- **AND** no module repeats the architecture string
