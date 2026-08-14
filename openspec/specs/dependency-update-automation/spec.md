# dependency-update-automation Specification

## Purpose

Define a reviewable and enforced path from weekly dependency discovery through cross-system CI, deliberate workstation activation, and generation rollback.

## Requirements

### Requirement: Explicit update ownership

The official flake-lock updater SHALL own Nix inputs. Renovate SHALL own GitHub Actions and any supported ecosystem dependencies outside Nix. Renovate's beta Nix manager SHALL remain disabled.

#### Scenario: Inspect updater configuration

- **WHEN** a maintainer reads the dependency operations document and automation files
- **THEN** every dependency class has exactly one updater and one source of version truth

### Requirement: Authenticated weekly pull request

A weekly and manually dispatchable workflow SHALL run a complete flake lock update and open or refresh a review-only pull request. It SHALL use a short-lived token from a GitHub App installed only on the owning repositories.

#### Scenario: Locked inputs change

- **WHEN** the weekly workflow produces a different `flake.lock`
- **THEN** it creates a pull request whose head commit starts the normal Darwin and Linux checks automatically

#### Scenario: Locked inputs do not change

- **WHEN** the locked inputs are current
- **THEN** the workflow exits successfully without an empty commit or pull request

### Requirement: Required merge checks

The main branch SHALL require current Darwin and Linux CI jobs for human and automated actors, including administrators. It SHALL require an up-to-date pull-request branch and linear history, and SHALL reject force-push and branch deletion.

#### Scenario: A required check fails

- **WHEN** either platform job fails or has not completed
- **THEN** GitHub prevents the pull request from merging

### Requirement: Manual activation boundary

Merging an update pull request SHALL NOT activate the workstation or mutate OMP-owned state. A human SHALL build and activate the generation, inspect local verification, and run the real OMP smoke when OMP or plugin behavior changed.

#### Scenario: Merge a dependency update

- **WHEN** all required checks pass and a maintainer merges the pull request
- **THEN** the active workstation remains unchanged until a deliberate `darwin-switch`

### Requirement: Retained rollback

The update procedure SHALL retain the previous Nix generation until activation verification and any required real-session smoke pass.

#### Scenario: New generation fails acceptance

- **WHEN** activation verification or the release smoke fails
- **THEN** the maintainer can restore the previous immutable generation without replacing mutable OMP state

### Requirement: Discoverable operations

The repository SHALL contain one concise agent entry point and one canonical dependency-update runbook. They SHALL identify ownership, schedule, manual commands, required checks, activation, smoke, and rollback without introducing a custom update wrapper.

#### Scenario: Resume in a new session

- **WHEN** an agent receives an update question in the repository
- **THEN** repository guidance points directly to the runbook and native commands
