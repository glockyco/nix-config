## ADDED Requirements

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
