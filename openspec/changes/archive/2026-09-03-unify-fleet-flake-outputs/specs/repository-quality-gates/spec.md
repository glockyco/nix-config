## ADDED Requirements

### Requirement: A development shell on every supported system

The repository SHALL provide a development shell for every system it declares as supported. Every supported host SHALL be able to enter that shell and install the commit hook. The shell SHALL carry the repository tools that any host needs, and it SHALL carry a host-specific tool only for the system whose host can complete that tool's workflow.

#### Scenario: Clone on a supported host

- **WHEN** a maintainer enters the repository on any supported host
- **THEN** the development shell for that system resolves
- **AND** the commit hook is installed in that working tree

#### Scenario: A supported system gains no shell

- **WHEN** the repository declares a supported system without a development shell for it
- **THEN** a repository check fails

#### Scenario: Host-specific tool outside its host

- **WHEN** a maintainer enters the development shell on a host that cannot complete a host-specific tool's workflow
- **THEN** that tool is absent from the shell rather than present and unusable

### Requirement: Each gate runs its host's Nix implementation

The continuous-integration leg for a system SHALL run the Nix implementation that the host for that system runs. A leg SHALL NOT rely on a different implementation's tolerance of an output that the host's implementation rejects.

#### Scenario: An output evaluates on one implementation only

- **WHEN** a flake output evaluates under the runner's default Nix and fails under the Nix its host declares
- **THEN** the continuous-integration leg for that system fails

#### Scenario: Inspect gate equivalence

- **WHEN** a maintainer compares the gate command of a system's continuous-integration leg with the gate command on that system's host
- **THEN** both run the same Nix implementation and the same check set

### Requirement: One package-set instance per system

The repository SHALL instantiate one Nixpkgs package set per supported system, and both the host configuration and the flake outputs for that system SHALL consume that instance. A host SHALL NOT instantiate a second package set, and the flake outputs SHALL NOT instantiate a package set that the host does not use.

#### Scenario: Compare a shared artifact

- **WHEN** an artifact appears both as a flake output and in a host's declared scope
- **THEN** both resolve to the same derivation

#### Scenario: A host declares its own package-set options

- **WHEN** a host module declares package-set options that the supplied instance already fixes
- **THEN** evaluation fails rather than silently ignoring those options
