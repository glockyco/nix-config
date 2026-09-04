## ADDED Requirements

### Requirement: Platform baselines contain no host role

A platform baseline SHALL contain only configuration required by every host of that platform. A host SHALL select its optional machine roles explicitly. A role SHALL live under the platform that can run it, and shared modules SHALL contain no platform branch.

#### Scenario: Add a second Darwin host

- **WHEN** a maintainer declares a Darwin host without desktop, database, or container roles
- **THEN** the host receives the Darwin baseline
- **AND** it receives no Homebrew application set, Dock layout, PostgreSQL service, Colima profile, or Air endpoint

#### Scenario: Select a role

- **WHEN** a host imports one role
- **THEN** the role's system and user modules apply together
- **AND** no platform baseline imports that role implicitly

#### Scenario: Inspect shared modules

- **WHEN** repository validation inspects a shared module
- **THEN** the module contains no Darwin, NixOS, WSL, or Windows condition

#### Scenario: Remove a temporary role

- **WHEN** a host removes the temporary Air role and its nullable declaration
- **THEN** the host still evaluates with every durable role and release gate
- **AND** no package, check, launchd agent, SSH alias, Home Manager file, policy entry, or credential reference names the Air

### Requirement: One declaration owns each host fact

A host-specific fact SHALL have one typed declaration. Every module, generated file, and check that uses the fact SHALL derive it from that declaration. A check SHALL read its expected value from the evaluated configuration rather than repeat a machine name, user name, path, application, or resource value.

#### Scenario: Change a screenshot directory

- **WHEN** a host changes its declared screenshot directory
- **THEN** the system default and the Home Manager directory preparation use the new path
- **AND** neither consumer needs an edit

#### Scenario: Change an application record

- **WHEN** a maintainer changes a declared Homebrew application's cask, application path, or Dock position
- **THEN** the generated Homebrew cask set and Dock layout change together
- **AND** no second application list exists

#### Scenario: Check a remote endpoint

- **WHEN** a repository check validates an SSH endpoint and its remote executable
- **THEN** the expected host, user, and executable come from the evaluated endpoint declaration
- **AND** the check contains no copy of those values

### Requirement: Secret files contain only encrypted scalar values

Every scalar value in a tracked file under `secrets/` SHALL be a SOPS encrypted value. The SOPS creation rule SHALL encrypt every scalar independent of its key name. Every secret file SHALL be encrypted to the host recipient and an offline recovery recipient. Repository validation SHALL inspect the parsed YAML data and reject any plaintext scalar.

#### Scenario: Add a secret with a new key name

- **WHEN** a maintainer adds an `api_key` or nested scalar and encrypts the file with SOPS
- **THEN** the committed scalar starts with `ENC[`
- **AND** both declared recipients can decrypt it

#### Scenario: Commit a plaintext scalar

- **WHEN** a tracked secret file contains a scalar that does not start with `ENC[`
- **THEN** repository validation fails
- **AND** the failure names the file and the scalar path

#### Scenario: Prove the detector

- **WHEN** the secret-encryption check runs against a fixture with one nested plaintext scalar
- **THEN** the fixture is rejected
- **AND** an equivalent fully encrypted fixture passes
