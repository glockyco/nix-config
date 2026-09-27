## ADDED Requirements

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

Every scalar value in the YAML data outside the top-level `sops` metadata mapping of a tracked file under `secrets/` SHALL be a SOPS encrypted value. The SOPS creation rule SHALL encrypt data independent of its key name. Every secret file SHALL be encrypted for the Mac recipient and the owner-supplied offline recovery recipient. Repository validation SHALL inspect parsed YAML data and reject any plaintext scalar.

#### Scenario: Add a secret with a new key name

- **WHEN** a maintainer adds an `api_key` or nested scalar and encrypts the file with SOPS
- **THEN** the committed data scalar starts with `ENC[`
- **AND** both declared recipients can decrypt it

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
