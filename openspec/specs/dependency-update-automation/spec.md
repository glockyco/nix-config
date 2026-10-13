# dependency-update-automation Specification

## Purpose

Define a reviewable and enforced path from weekly dependency discovery through cross-system CI, deliberate workstation activation, and generation rollback.

## Requirements

### Requirement: Explicit update ownership

Central automation SHALL own Nix inputs; Renovate SHALL own Actions/non-Nix dependencies with its beta Nix manager disabled. Mac Nix SHALL supply ordinary host tools, never OMP/plugin runtime. Mac OMP SHALL use official installer/update; Korolev OMP SHALL be Tern-managed and its native tools retain C3's owners. Plugin managers SHALL own runtime upgrades. Plannotator advancement SHALL remain explicit. No target App private key or competing Nix scheduler SHALL exist.

#### Scenario: Inspect updater configuration

- **WHEN** dependency operations, automation and central registry are inspected
- **THEN** each dependency class has one update owner/version authority
- **AND** platform OMP/plugin operations remain outside Nix activation
- **AND** nix-config declares Docker Desktop's self-updating machine-scope initial install without a version pin or downgrade, while Intune's update-only package keeps it current after owner/employer licensing confirmation
- **AND** Mac Colima remains Nix/user-owned and Windows TeX Live/tlmgr yearly lifecycle remains C3-owned
- **AND** no App credential or scheduled Nix-update workflow exists in this repository

### Requirement: Authenticated weekly pull request

A weekly and manually dispatchable central workflow SHALL run a complete flake lock update and open or refresh a review-only pull request. It SHALL use a short-lived GitHub App token scoped to this repository and SHALL NOT merge the pull request.

#### Scenario: Locked inputs change

- **WHEN** the central workflow produces a different `flake.lock`
- **THEN** it creates a pull request whose head commit starts the normal Darwin and Linux checks automatically

#### Scenario: Locked inputs do not change

- **WHEN** the locked inputs are current
- **THEN** the workflow exits successfully without an empty commit or pull request

### Requirement: Required merge checks

Main SHALL require current Darwin Nix, Linux-generic CI, native Windows, portable OpenSpec and applicable live policy jobs for humans/automation including administrators. It SHALL require linear history, rejecting force-push/deletion, but SHALL NOT require a PR branch to be up to date with main before merging. Checks SHALL not build the removed Korolev host or depend on its builder.

#### Scenario: A required check fails

- **WHEN** any required platform/OpenSpec/policy check fails
- **THEN** main rejects the merge for human and automated actors, including administrators
- **AND** no removed-host check or Linux-only success satisfies protection

### Requirement: Manual activation boundary

Merges SHALL not activate workstations or mutate OMP state. Nix build/activation SHALL run only on Mac and applicable CI; Windows user apply and platform runtime/plugin updates SHALL remain explicit authorized operations. Agents MAY run authorized commands in an actual terminal while owners type sudo/UAC credentials. Neither publication nor a plan SHALL imply activation authorization.

#### Scenario: Merge a dependency update

- **WHEN** required checks pass and an authorized maintainer merges the PR
- **THEN** active workstations and OMP/plugin selections remain unchanged until explicit platform operations

#### Scenario: Update OMP

- **WHEN** the owner updates the Mac via omp update or Windows via Tern's Check for omp updates
- **THEN** only that platform-owned upstream installation changes
- **AND** no repository/Nix generation changes implicitly
- **AND** evidence records observed installation and a fresh Tern session

### Requirement: Retained rollback

Mac updates SHALL retain the previous Nix generation through activation/session acceptance; Nix rollback SHALL not claim OMP/plugin recovery. Native Windows recovery SHALL use accepted tool/source backups, Tern OMP recovery and supported corrective plugin releases. WSL retirement SHALL require a private retained export; its recovery SHALL be an explicitly authorized import, not a continuing supported environment or state conversion.

#### Scenario: New generation fails acceptance

- **WHEN** Mac activation or release smoke fails
- **THEN** the owner can restore the retained Nix generation without replacing mutable OMP state
- **AND** rollback claims no OMP/plugin-version change

#### Scenario: OMP update fails acceptance

- **WHEN** installed OMP fails direct verification or session smoke
- **THEN** the owner follows supported Mac official-installer or Windows Tern recovery with recorded accepted releases where available
- **AND** no Nix rollback is represented as executable recovery
- **AND** missing recovery prerequisites are reported, not fabricated

### Requirement: Discoverable operations

AGENTS.md, README and the dependency runbook SHALL identify Nix maintenance on Mac/CI, native Windows hooks/apply, portable OpenSpec commands/workflow, platform OMP/plugin ownership and explicit activation/recovery boundaries. Retained-WSL, GPG/pass and daemon-builder instructions SHALL be removed. No substitute scheduler, updater shim or Linux delegation SHALL be introduced.

#### Scenario: Resume in a new session

- **WHEN** an agent receives a maintenance question
- **THEN** guidance points to applicable Mac Nix, Windows native/Tern and plugin-manager operations
- **AND** it references no deleted WSL wrapper/builder/update workflow
- **AND** the Korolev migration/export runbook is discoverable without copying historical WSL instructions into active procedures

### Requirement: CI-reachable dependency sources

Dependencies exercised by required update checks SHALL use reproducible sources that can complete unattended on every required platform. A platform-specific artifact SHALL use the smallest official fixed-output source that preserves the accepted behavior when the authoritative repository transport is unreliable.

#### Scenario: Repository transport is unreliable

- **WHEN** repeated required checks fail or stall while fetching an authoritative repository
- **THEN** the package uses an official fixed-output release source when one provides the required artifact
- **AND** the obsolete repository input is removed completely

#### Scenario: Required source is not cacheable

- **WHEN** a routine update check evaluates its Darwin build plan
- **THEN** incidental compiler source builds are absent when Nixpkgs provides hash-pinned binary packages for the same supported toolchain
