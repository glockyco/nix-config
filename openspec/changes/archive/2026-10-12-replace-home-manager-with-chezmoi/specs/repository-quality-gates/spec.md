# Spec Delta

## MODIFIED Requirements

### Requirement: One typed host declaration per host

Each host SHALL describe its identity through one standalone `hosts/<name>/host.nix` declaration validated by the module system, importing facts shared with user templates from home/.chezmoidata/\*.toml rather than duplicating them. The directory name SHALL set the host name. The declaration SHALL set the interactive user name, system, kind, builder capacity, and tailnet facts. The flake SHALL evaluate that declaration alone and expose the result through the read-only `fleet.hosts` registry. Each configuration SHALL receive the same facts through a typed `fleet.hosts` option. A module that needs a fact about its own host SHALL read `config.host`; a module that needs a fact about a peer SHALL read `config.fleet.hosts`. No host fact SHALL travel to a Nix module as an untyped argument; chezmoi SHALL read the same shared TOML facts directly.

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
- **THEN** each gate that renders its chezmoi configuration or reads its system-declared user packages reads the new user
- **AND** the gate definition needs no edit

### Requirement: Platform baselines contain no host role

A platform baseline SHALL contain only configuration required by every host of that platform. A host SHALL select its optional machine roles explicitly. A role SHALL live under the platform that can run it, and shared modules SHALL contain no platform branch.

#### Scenario: Add a second Darwin host

- **WHEN** a maintainer declares a Darwin host without desktop, database, container-client, or Air-client roles
- **THEN** the host receives the Darwin baseline
- **AND** it receives no Homebrew application set, Dock application list, PostgreSQL service, Colima profile, or Air endpoint

#### Scenario: Select a role

- **WHEN** a host imports one role
- **THEN** the role's system settings and matching chezmoi user configuration apply together
- **AND** no platform baseline imports that role implicitly

#### Scenario: Inspect shared modules

- **WHEN** repository validation inspects a shared module
- **THEN** the module contains no Darwin, NixOS, WSL, or Windows condition

#### Scenario: Remove the temporary Air integration

- **WHEN** the Air role, its package directory, Air check and output wiring, and `macbook-air` peer entry are removed
- **THEN** the host still evaluates with every durable role and release gate, including the desktop SSH configuration check
- **AND** no generated package, check, launchd agent, SSH alias, chezmoi file, policy entry, or credential reference names the Air

### Requirement: One declaration owns each host fact

Each host-specific fact SHALL have one declaration: name is the host directory key; facts shared with user configuration live in home/.chezmoidata/\*.toml and remaining system facts in hosts/<name>/host.nix. Nix SHALL validate them through config.host and config.fleet.hosts; chezmoi SHALL read the same shared TOML. Every generated file and check SHALL derive values from that owner. A check SHALL NOT repeat a machine name, user name, durable path, application, or resource value. The temporary Air integration SHALL remain role-owned until its removal under issue #17; it SHALL NOT gain a durable host endpoint declaration.

#### Scenario: Change a screenshot directory

- **WHEN** a host changes its declared screenshot directory
- **THEN** the system default and chezmoi directory preparation use the new path
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

### Requirement: Installed and activation programs are packages with behavior checks

Each reusable repository-owned user, setup or modify-filter program SHALL be a package under `packages/<name>/package.nix`, with `meta.description`, `meta.mainProgram`, and `meta.platforms`. Each SHALL have `packages/<name>/tests.nix` that runs the built program against doubles or fixtures and asserts observable behavior. Python programs SHALL also run their stdlib unit tests during package builds. A module SHALL NOT interpolate a source script path into activation. Thin chezmoi scripts SHALL invoke installed packaged helpers; a modify filter SHALL change only declared keys and preserve unrelated app state.

#### Scenario: Inspect a program a host installs

- **WHEN** a maintainer lists the repository-owned user and activation programs used by the configuration
- **THEN** each resolves to `packages/<name>/package.nix`
- **AND** each has a sibling `tests.nix` that exercises its behavior
- **AND** the tested helper, modify-filter and switch-wrapper derivations match those installed in the host's system-declared user package set

#### Scenario: A program regresses

- **WHEN** a change makes a packaged program write where the current state already matches, or exit zero on an error it does not document
- **THEN** the program's check fails

#### Scenario: A Python program is imported by its test

- **WHEN** a test imports a packaged Python program
- **THEN** the import performs no subprocess call, reads no command-line argument, and exits nothing
- **AND** the program exposes `main(argv: Sequence[str] | None = None) -> int`, which owns `argparse`, parses `sys.argv[1:]` when `argv` is `None`, and returns the console script's exit status

## ADDED Requirements

### Requirement: One declaration for each cross-platform fact

A fact that both platform scopes consume SHALL have one declaration. The Darwin scope, the NixOS scope, and every repository check that asserts the fact SHALL read that declaration. The binary cache substituter and its public key are such a fact. Shared chezmoi host data and portable user-package intent are such facts.

#### Scenario: Rotate the binary cache key

- **WHEN** a maintainer changes the binary cache public key in its declaration
- **THEN** both host configurations carry the new key
- **AND** the check that asserts the WSL host's Nix settings passes without a second edit

#### Scenario: Compare user-package and chezmoi wiring of both hosts

- **WHEN** a maintainer compares how each host selects the package set, installs user packages and renders user configuration
- **THEN** both hosts read those settings from one declaration
- **AND** platform modules add only platform package/program adapters and chezmoi templates add only necessary OS-specific behavior

#### Scenario: Check each host against the declaration

- **WHEN** the repository checks for a system run
- **THEN** a check asserts that the host on that system carries the declared substituter and the declared public key in its Nix settings
- **AND** the check reads the expected values from the declaration rather than from a literal

### Requirement: Encrypted source validation covers every managed secret

Repository checks SHALL require every declared managed secret to have a private encrypted chezmoi source with a valid age payload. Missing ciphertext, plaintext substitution or removal of its private/encrypted attributes SHALL fail without decrypting production data. Format validation SHALL not be reported as proof of recipient access.

#### Scenario: Add a secret with a new name

- **WHEN** a new managed credential is declared
- **THEN** its source is checked independent of the credential name
- **AND** missing, plaintext or nonprivate source state fails with the file path

#### Scenario: Commit plaintext instead of ciphertext

- **WHEN** a tracked managed secret contains plaintext or a malformed age payload
- **THEN** repository validation fails and names the source path without printing its contents

#### Scenario: Prove the detector

- **WHEN** positive encrypted fixtures and plaintext, truncated, missing and incorrectly attributed fixtures run
- **THEN** encrypted fixtures pass and every invalid fixture fails
- **AND** an isolated synthetic age round trip verifies private file permissions without a production identity

#### Scenario: Preserve encryption metadata

- **WHEN** repository validation examines a supported age encoding
- **THEN** it validates encryption framing rather than treating an age header alone as sufficient
- **AND** live recipient access remains a separate Mac acceptance gate

### Requirement: User configuration checks render the tracked source

Each host's user-configuration check SHALL render its actual chezmoi source in an isolated home using the same shared facts as the host configuration. It SHALL retain effective shell, SSH, package and container assertions formerly derived from Home Manager. Checks SHALL not access production secrets, live applications or remote services.

#### Scenario: A template regresses

- **WHEN** an SSH endpoint, shell hook or Colima profile template changes incorrectly
- **THEN** its host's rendered configuration check fails on the affected effective assertion

#### Scenario: Validate without host credentials

- **WHEN** checks run in CI without production keys or provider access
- **THEN** ordinary user configuration and synthetic-secret fixtures are verified
- **AND** no live user setup command, production decryption or remote connection runs

## REMOVED Requirements

### Requirement: Secret files contain only encrypted data scalars

**Reason**: Whole-file age ciphertext replaces SOPS YAML scalars and metadata; retaining the scalar rule would validate the wrong source format.
**Migration**: Replace the secret check with encrypted-source inventory, age payload and private-attribute validation plus positive/negative fixtures and isolated synthetic decryption tests. Keep original ciphertext until Mac live consumer verification passes.

### Requirement: One declaration for each fact that both platforms share

**Reason**: Its scenario names the Home Manager wiring that this change removes; the cross-platform fact rule continues under a name and scenarios that describe the chezmoi and system-package wiring.
**Migration**: See `One declaration for each cross-platform fact`, which keeps the binary-cache and host-check scenarios unchanged and replaces the Home Manager comparison with the user-package and chezmoi comparison.
