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

### Requirement: One typed host declaration per host

Each host SHALL describe its identity through one declaration that the module system validates: the host name, the interactive user name, the platform-owned OMP executable location, and the command that installs that executable. The executable location SHALL state whether it is an absolute path or a path relative to the user's home directory. A module that needs a host value SHALL read it from that declaration. No host value SHALL travel to a module as an untyped argument.

#### Scenario: A host omits a required value

- **WHEN** a host declaration omits the user name or the OMP executable location
- **THEN** evaluation fails with an error that names the missing option
- **AND** the failure occurs before any consumer of the value evaluates

#### Scenario: A host misstates the executable location

- **WHEN** a host declaration gives the OMP executable location without stating whether it is absolute or home-relative
- **THEN** evaluation fails with a type error that names the option

#### Scenario: The wrapper expands a home-relative location

- **WHEN** a host declares the OMP executable at a path relative to the user's home directory
- **THEN** the wrapped `omp` command resolves that path under the user's home directory at run time
- **AND** the absence message names the same location and the declared installation command

#### Scenario: The wrapper uses an absolute location

- **WHEN** a host declares the OMP executable at an absolute path
- **THEN** the wrapped `omp` command invokes exactly that path
- **AND** no home-directory expansion applies

#### Scenario: A user-scope module reads a host value

- **WHEN** a portable user-scope module needs the OMP executable location or the installation command
- **THEN** it reads the host declaration of the system that manages it
- **AND** the host passes the value through no additional argument

### Requirement: One declaration for each fact that both platforms share

A fact that both platform scopes consume SHALL have one declaration. The Darwin scope, the NixOS scope, and every repository check that asserts the fact SHALL read that declaration. The binary cache substituter and its public key are such a fact. The Home Manager wiring that both platforms share is such a fact.

#### Scenario: Rotate the binary cache key

- **WHEN** a maintainer changes the binary cache public key in its declaration
- **THEN** both host configurations carry the new key
- **AND** the check that asserts the WSL host's Nix settings passes without a second edit

#### Scenario: Compare the Home Manager wiring of both hosts

- **WHEN** a maintainer compares how each host enables Home Manager, selects the package set, installs user packages, and handles conflicting files
- **THEN** both hosts read those settings from one declaration
- **AND** each platform module adds only the platform's Home Manager module and the module lists that differ

#### Scenario: Check each host against the declaration

- **WHEN** the repository checks for a system run
- **THEN** a check asserts that the host on that system carries the declared substituter and the declared public key in its Nix settings
- **AND** the check reads the expected values from the declaration rather than from a literal
