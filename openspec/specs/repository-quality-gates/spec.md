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

### Requirement: Darwin gates run from the Linux host

The Linux host SHALL be able to build every `aarch64-darwin` check of the repository through the declared Darwin remote builder. The result SHALL be the same derivation that the Darwin host builds locally. A gate that reads the Darwin store, such as the build-plan inspection, SHALL run on the Darwin host through the tailnet SSH endpoint.

#### Scenario: Run all checks from one host

- **WHEN** the operator runs `nix flake check --all-systems` on the Linux host while the Darwin host is connected
- **THEN** every `x86_64-linux` check builds locally, every `aarch64-darwin` check builds on the Darwin host, and the command exits 0

#### Scenario: Compare with the Darwin host's own gate

- **WHEN** the same revision is checked on the Darwin host with `nix flake check`
- **THEN** each `aarch64-darwin` check resolves to the same derivation path as the one built from the Linux host

#### Scenario: Inspect build plans from the Linux host

- **WHEN** the operator runs the documented build-plan inspection command from the Linux host
- **THEN** the inspection executes on the Darwin host over the tailnet SSH endpoint and reports its result to the Linux host
- **AND** the SSH client's exit status equals the remote command's exit status

#### Scenario: A remote gate fails

- **WHEN** a gate on the Darwin host exits nonzero
- **THEN** the Linux caller receives that nonzero status without a parsing wrapper or success fallback

### Requirement: OpenSpec package consistency

The workstation checks SHALL verify that the OpenSpec executable reports the version declared by its Nix package. They SHALL NOT require a hard-coded historical version after a reviewed update.

#### Scenario: Package and executable disagree

- **WHEN** the packaged executable reports a version different from its Nix package metadata
- **THEN** the workstation release gate fails

### Requirement: Generated OpenSpec adapter freshness

The workstation checks SHALL verify that tracked OpenSpec commands and skills match the selected generator. An OpenSpec update SHALL require review of generated changes before merge.

#### Scenario: Generator output changes

- **WHEN** the selected OpenSpec package would rewrite a tracked adapter
- **THEN** the release gate fails until the generated difference is reviewed and committed

### Requirement: Archived change completeness

The workstation checks SHALL reject an archived OpenSpec change that contains an incomplete task. Strict validation SHALL also retain scenario and task-numbering checks for active contracts.

#### Scenario: An incomplete change is archived

- **WHEN** an archived change contains an unchecked task
- **THEN** the workstation release gate fails

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

### Requirement: Platform baselines contain no host role

A platform baseline SHALL contain only configuration required by every host of that platform. A host SHALL select its optional machine roles explicitly. A role SHALL live under the platform that can run it, and shared modules SHALL contain no platform branch.

#### Scenario: Add a second Darwin host

- **WHEN** a maintainer declares a Darwin host without desktop, database, container-client, or Air-client roles
- **THEN** the host receives the Darwin baseline
- **AND** it receives no Homebrew application set, Dock application list, PostgreSQL service, Colima profile, or Air endpoint

#### Scenario: Select a role

- **WHEN** a host imports one role
- **THEN** the role's system and user modules apply together
- **AND** no platform baseline imports that role implicitly

#### Scenario: Inspect shared modules

- **WHEN** repository validation inspects a shared module
- **THEN** the module contains no Darwin, NixOS, WSL, or Windows condition

#### Scenario: Remove the temporary Air integration

- **WHEN** the Air role, its package directory, Air check and output wiring, and `macbook-air` peer entry are removed
- **THEN** the host still evaluates with every durable role and release gate, including the desktop SSH configuration check
- **AND** no generated package, check, launchd agent, SSH alias, Home Manager file, policy entry, or credential reference names the Air

### Requirement: One declaration owns each host fact

Each host-specific fact SHALL have one typed source: its name is the host directory key, and its other facts are in `hosts/<name>/host.nix`. Every module, generated file, and check that uses a fact SHALL derive it from `config.host` or the typed `config.fleet.hosts` registry. A check SHALL NOT repeat a machine name, user name, durable path, application, or resource value. The temporary Air integration SHALL remain role-owned until its removal under issue #17; it SHALL NOT gain a durable host endpoint declaration.

#### Scenario: Change a screenshot directory

- **WHEN** a host changes its declared screenshot directory
- **THEN** the system default and Home Manager directory preparation use the new path
- **AND** neither consumer needs an edit

#### Scenario: Change an application record

- **WHEN** a maintainer changes a declared Homebrew application's cask, application path, or Dock position
- **THEN** the generated Homebrew cask set and Dock layout change together
- **AND** no second application list exists

#### Scenario: Change a container resource

- **WHEN** a maintainer changes one declared Colima capacity or mount value
- **THEN** the generated profile and its configuration check use the new value
- **AND** no second resource literal needs an edit

#### Scenario: Keep the temporary endpoint removable

- **WHEN** the Air role is selected
- **THEN** its current SSH aliases, batch command, SMB agent, link, and checks are available
- **AND** durable host declarations and platform baselines contain no Air endpoint value

### Requirement: Nix policy uses supported platform interfaces

The host configurations SHALL share one pinned registry, disabled legacy channel policy, and maintenance intent. NixOS SHALL schedule native weekly garbage collection and store optimisation. Darwin SHALL use Determinate Nix's automatic garbage collection without setting `auto-optimise-store` or adding an independent maintenance job; its pinned Determinate module has no scheduled store optimiser.

#### Scenario: Evaluate each native adapter

- **WHEN** the Darwin and NixOS hosts evaluate their Nix settings
- **THEN** both use the pinned registry and disable legacy channel lookup
- **AND** Korolev has weekly native GC and optimisation timers
- **AND** Darwin retains its trusted SSH builder user and uses Determinate's automatic GC
- **AND** Darwin does not enable automatic store optimisation

### Requirement: Secret files contain only encrypted data scalars

Every scalar value in the YAML data outside the top-level `sops` metadata mapping of a tracked file under `secrets/` SHALL be a SOPS encrypted value. Repository validation SHALL inspect parsed YAML data and reject any plaintext scalar, independent of its key name.

#### Scenario: Add a secret with a new key name

- **WHEN** a maintainer adds an `api_key` or nested scalar that the SOPS creation rule leaves in plaintext
- **THEN** repository validation fails
- **AND** the failure names the file and scalar path

#### Scenario: Commit a plaintext scalar

- **WHEN** a tracked secret file contains a data scalar that does not start with `ENC[`
- **THEN** repository validation fails
- **AND** the failure names the file and scalar path

#### Scenario: Prove the detector

- **WHEN** the secret-encryption check runs against fixtures with nested plaintext mappings and list entries
- **THEN** each plaintext fixture is rejected with its scalar path
- **AND** an equivalent fully encrypted fixture passes

#### Scenario: Preserve SOPS metadata

- **WHEN** the repository check examines a SOPS-encrypted YAML file
- **THEN** it excludes only the top-level `sops` metadata mapping from the data-scalar rule
- **AND** it checks every scalar in all other top-level keys

### Requirement: Installed and activation programs are packages with behavior checks

Each repository-owned user or activation program introduced by this change SHALL be a package under `packages/<name>/package.nix`, with `meta.description`, `meta.mainProgram`, and `meta.platforms`. Each SHALL have `packages/<name>/tests.nix` that runs the built program against doubles or fixtures and asserts observable behavior. Python programs SHALL also run their stdlib unit tests during package builds. A module SHALL NOT interpolate a source script path into an activation command.

#### Scenario: Inspect a program a host installs

- **WHEN** a maintainer lists the repository-owned user and activation programs introduced by this change
- **THEN** each resolves to `packages/<name>/package.nix`
- **AND** each has a sibling `tests.nix` that exercises its behavior

#### Scenario: A program regresses

- **WHEN** a change makes a packaged program write where the current state already matches, or exit zero on an error it does not document
- **THEN** the program's check fails

#### Scenario: A Python program is imported by its test

- **WHEN** a test imports a packaged Python program
- **THEN** the import performs no subprocess call, reads no command-line argument, and exits nothing
- **AND** the program exposes `main(argv: Sequence[str] | None = None) -> int`, which owns `argparse`, parses `sys.argv[1:]` when `argv` is `None`, and returns the console script's exit status
