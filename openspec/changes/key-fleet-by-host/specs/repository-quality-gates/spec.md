## ADDED Requirements

### Requirement: Hosts declared by name

The repository SHALL declare its hosts in one table keyed by host name. Each row SHALL name the system the host runs on and the kind of system configuration it is. The supported systems SHALL be the set of systems that the rows name. The host configuration outputs SHALL be generated from the rows. A second host on a system that already carries one SHALL be one additional row and one additional host directory.

#### Scenario: Add a second host on an existing system

- **WHEN** a maintainer adds a row for a new host whose system already carries a host, and adds the matching host directory
- **THEN** the flake exposes a host configuration under that name
- **AND** the supported systems are unchanged
- **AND** every host gate exists for the new host without a further edit

#### Scenario: A host directory has no row

- **WHEN** a directory exists under the hosts directory that no table row names
- **THEN** a repository check fails and names the directory

#### Scenario: A row names an unknown kind

- **WHEN** a row names a kind that no generator handles
- **THEN** evaluation fails with an error that names the option and the permitted kinds

### Requirement: Host gates generated per host

Every check that reads one host configuration SHALL be generated from the host table for each host on the system, under a name that starts with the host name. Every such check SHALL read the host name, the user name, and every other host value from the host's typed declaration. No check SHALL name a host or a user as a literal. A check that asserts a property of one kind of host SHALL exist for every host of that kind. The system check of every host SHALL read the same option path.

#### Scenario: Rename a host

- **WHEN** a maintainer renames a host in the table and its directory
- **THEN** every gate for that host exists under the new name
- **AND** no gate under the old name remains
- **AND** no other file changes

#### Scenario: Compare the system gates of two hosts

- **WHEN** a maintainer compares how the system check of a Darwin host and of a NixOS host is built
- **THEN** both read the host's system build output through the same option path

#### Scenario: A user-scope check on a renamed user

- **WHEN** a host changes its interactive user name in its declaration
- **THEN** every check that reads that user's Home Manager configuration reads the new user
- **AND** the check itself is unchanged

### Requirement: Program checks exercise the program

A check for a program that the repository packages SHALL run the program against stub executables and fixtures, and SHALL assert the program's observable behavior: its exit status, its output, and the calls it makes. A check SHALL NOT assert the text of the program's source. A check that reads a host's wrapper SHALL read the derivation that the host installs.

#### Scenario: The wrapper delegates to the platform executable

- **WHEN** the check runs a host's wrapper with a stub in the place of the platform executable
- **THEN** the stub records the extension and plugin-directory flags followed by the caller's arguments
- **AND** the check fails when either flag is absent or reordered

#### Scenario: The platform executable is absent

- **WHEN** the check runs a host's wrapper without an executable at the declared location
- **THEN** the wrapper exits with a failure whose message names the declared location and the declared installation command

#### Scenario: A home-relative location resolves under the caller's home

- **WHEN** the check runs a wrapper declared with a home-relative location under a temporary home directory that holds a stub at that relative path
- **THEN** the wrapper runs that stub

#### Scenario: A source-text change without a behavior change

- **WHEN** the wrapper's script text changes and its behavior does not
- **THEN** the check passes

## MODIFIED Requirements

### Requirement: One package-set instance per system

The repository SHALL instantiate one Nixpkgs package set per supported system, and both the host configurations and the flake outputs for that system SHALL consume that instance. A host SHALL NOT instantiate a second package set, and the flake outputs SHALL NOT instantiate a package set that the host does not use. Each package that the repository defines SHALL be an attribute of that package set through one overlay. A module SHALL consume such a package from the package set. A check that asserts a package a host installs SHALL assert the derivation that appears in the host's declared packages.

#### Scenario: Compare a shared artifact

- **WHEN** an artifact appears both as a flake output and in a host's declared scope
- **THEN** both are the same derivation
- **AND** the check that asserts the artifact fails when the host's declared packages hold a different derivation

#### Scenario: A host declares its own package-set options

- **WHEN** a host module declares package-set options that the supplied instance already fixes
- **THEN** evaluation fails rather than silently ignoring those options

#### Scenario: A package argument changes

- **WHEN** a maintainer changes an argument of a repository package in the one place that supplies it
- **THEN** the derivation the host installs and the derivation the check exercises change together
- **AND** no second call site exists that could keep the old argument

#### Scenario: A package that one platform cannot build

- **WHEN** a repository package declares platforms that exclude the current system
- **THEN** the package and its program check are absent from that system's outputs
- **AND** no output reads a host kind to decide that
