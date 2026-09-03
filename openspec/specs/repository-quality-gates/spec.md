# repository-quality-gates Specification

## Purpose

Define how this repository enforces formatting before a commit and in continuous integration, so that the local gate and the remote gate read one configuration and cannot disagree.

## Requirements

### Requirement: One formatting configuration for both gates

The commit gate and the continuous integration gate SHALL derive from the same formatting configuration. Neither gate SHALL carry its own list of formatters, file patterns, or exclusions.

#### Scenario: Unformatted file reaches a commit

- **WHEN** a maintainer commits a file that the formatting configuration would rewrite
- **THEN** the commit is rejected

#### Scenario: Unformatted file reaches continuous integration

- **WHEN** the branch contains a file that the formatting configuration would rewrite
- **THEN** the continuous integration job fails

#### Scenario: A formatter is added

- **WHEN** a formatter is added to the formatting configuration
- **THEN** both gates apply it without a second edit

### Requirement: The commit hook is installed from the development shell

Entering the development shell SHALL install the commit hook into the working tree. The hook SHALL run from the pinned tools of that shell and SHALL NOT depend on a tool that happens to be on `PATH`.

#### Scenario: First entry into the shell

- **WHEN** a maintainer enters the development shell in a working tree with no installed hook
- **THEN** the hook is installed
- **AND** a following commit runs the formatting gate

#### Scenario: Commit from an environment without the shell

- **WHEN** a Git client outside the development shell triggers the hook
- **THEN** the hook either runs with the pinned tools or fails with a message that names the missing environment
- **AND** it does not silently skip the gate

### Requirement: Retiring a hook runner removes its hook

Replacing the hook runner SHALL leave no hook file from the previous runner in the working tree.

#### Scenario: Working tree carries the previous hook

- **WHEN** the hook runner is replaced in a working tree that already has the previous runner's hook installed
- **THEN** the previous hook file is removed or overwritten
- **AND** committing runs the new gate exactly once

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
