## ADDED Requirements

### Requirement: Hosts declared by directory

The repository SHALL have one directory per managed host under `hosts/`. Each directory SHALL contain `host.nix` and `default.nix`. The flake SHALL evaluate each standalone `host.nix` against the shared host option definitions, with the directory name as `host.name`. The resulting read-only `fleet.hosts` registry SHALL key hosts by name. Supported systems and host configurations SHALL derive from that registry. Adding a host on an existing system SHALL require no new flake output branch.

#### Scenario: Add a second host on an existing system

- **WHEN** a maintainer adds a complete host directory for a second host on an existing system
- **THEN** the flake exposes a configuration under the new host name
- **AND** the supported systems remain unchanged
- **AND** every generic host gate exists for the new host

#### Scenario: A host directory is incomplete

- **WHEN** a host directory lacks `host.nix` or `default.nix`
- **THEN** `fleetSurface` fails and names that directory and its missing file

#### Scenario: A host declares an unknown kind

- **WHEN** a host's standalone declaration sets a kind other than `darwin` or `nixos`
- **THEN** evaluation fails with a type error that names `host.kind` and the permitted kinds

#### Scenario: A host declares a mismatched system

- **WHEN** a generated host configuration evaluates with a system different from its registry declaration
- **THEN** `fleetSurface` fails for that host

### Requirement: Host gates generated per host

Every check that reads one host configuration SHALL be generated from `fleet.hosts` for each host on the system. Its name SHALL start with the host name. Such a check SHALL read host and user values from that host's typed declaration, not from literals. A kind-specific check SHALL exist for every host of that kind. Every system gate SHALL read `config.system.build.toplevel`.

#### Scenario: Rename a host

- **WHEN** a maintainer renames a host directory
- **THEN** every gate for that host exists under its new name
- **AND** no gate under its old name remains
- **AND** no host-specific lookup outside that directory needs an edit

#### Scenario: Compare Darwin and NixOS system gates

- **WHEN** a maintainer compares the system gates for a Darwin host and a NixOS host
- **THEN** both read the generated host's `config.system.build.toplevel`

#### Scenario: Rename a user's account

- **WHEN** a host changes the interactive username in its standalone declaration
- **THEN** each gate that reads its Home Manager configuration reads the new user
- **AND** the gate definition needs no edit

### Requirement: Peer facts come from the registry

A module SHALL read other managed hosts' name, system, user, builder capacity, and tailnet facts from its typed `config.fleet.hosts` registry. It SHALL NOT evaluate another host's Darwin or NixOS configuration to obtain those facts. Remote builders SHALL derive from other registry hosts with non-null `build.logicalCores`. The tailnet renderer SHALL derive its port-22 deny targets from registry hosts with `tailnet.reachable = false`.

#### Scenario: A builder host changes its system or name

- **WHEN** a remote builder's standalone declaration changes its system or directory name
- **THEN** a consuming host's builder settings use the new registry facts
- **AND** its root SSH builder key path derives from the new builder name
- **AND** no consuming module evaluates the builder's system configuration

#### Scenario: An unreachable host is added

- **WHEN** a new managed host declares `tailnet.reachable = false`
- **THEN** the rendered policy denies port 22 to its tailnet tag from every reachable source
- **AND** no renderer edit is required

### Requirement: Program checks exercise the program

A packaged program's check SHALL execute the packaged program against controlled fixtures and stub executables. It SHALL assert observable exit status, output, and calls rather than script source text. A host wrapper check SHALL assert that the wrapper, updater, and verifier derivations under test are the derivations installed by that host.

#### Scenario: A selected OMP source generation exists

- **WHEN** a check runs the installed wrapper with a selected executable source generation
- **THEN** the executable receives the extension and plugin-directory flags before the caller's arguments
- **AND** the check fails if either flag is absent or reordered

#### Scenario: The selected generation is missing or unusable

- **WHEN** the check runs the wrapper without a selected generation or with an unusable launcher
- **THEN** the wrapper exits with a failure that identifies the source-generation path and `omp-dev-update`

#### Scenario: Program source changes without behavior changing

- **WHEN** a program's source text changes but its observable behavior remains the same
- **THEN** its behavior check passes

## MODIFIED Requirements

### Requirement: One typed host declaration per host

Each host SHALL describe its identity through one standalone `hosts/<name>/host.nix` declaration validated by the module system. The directory name SHALL set the host name. The declaration SHALL set the interactive user name, system, kind, builder capacity, and tailnet facts. The flake SHALL evaluate that declaration alone and expose the result through the read-only `fleet.hosts` registry. Each configuration SHALL receive the same facts through a typed `fleet.hosts` option. A module that needs a fact about its own host SHALL read `config.host`; a module that needs a fact about a peer SHALL read `config.fleet.hosts`. No host fact SHALL travel to a module as an untyped argument.

#### Scenario: A host omits a required value

- **WHEN** a standalone declaration omits `host.username`, `host.system`, or `host.kind`
- **THEN** registry evaluation fails with an error that names the missing option
- **AND** the failure occurs before any host configuration consumes the value

#### Scenario: A host misstates its kind

- **WHEN** a declaration gives `host.kind` a value outside the permitted kinds
- **THEN** registry evaluation fails with a type error that names `host.kind`

#### Scenario: A module reads a host value

- **WHEN** a system or user-scope module needs its host name or interactive user name
- **THEN** it reads the declaration of the host that manages it
- **AND** the host passes that fact through no additional argument

#### Scenario: A peer-scope module reads a builder fact

- **WHEN** a module needs a builder's name, system, or logical core count
- **THEN** it reads the typed registry entry for that builder
- **AND** it does not force the builder's evaluated host configuration

### Requirement: One package-set instance per system

The repository SHALL instantiate one Nixpkgs package set per supported system. Host configurations and flake outputs for that system SHALL consume that instance. A host SHALL NOT instantiate a second package set. The overlay SHALL derive each local package attribute from a matching `packages/<name>/package.nix` directory, with package-set-only arguments. It SHALL explicitly re-export pinned external packages and apply the NixOS options override. Modules SHALL consume repository packages from that package set. A host package check SHALL assert the derivation that the host installs. Package outputs and program checks SHALL use `meta.platforms` rather than a host-kind branch to select supported systems.

#### Scenario: Compare a shared artifact

- **WHEN** an artifact appears both as a flake output and in a host's declared scope
- **THEN** both resolve to the same derivation
- **AND** the host package check fails if its declared packages contain a different derivation

#### Scenario: A host declares its own package-set options

- **WHEN** a host module declares package-set options that the supplied instance already fixes
- **THEN** evaluation fails rather than silently ignoring those options

#### Scenario: A package argument changes

- **WHEN** a maintainer changes an argument supplied by the shared package set
- **THEN** both the host-installed derivation and its program check change together
- **AND** no second package call can retain the old argument

#### Scenario: A package is unavailable on one platform

- **WHEN** a repository package declares platforms that exclude the current system
- **THEN** its package output and program check are absent on that system
- **AND** no output reads a host kind to make that package decision
