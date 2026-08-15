## MODIFIED Requirements

### Requirement: Explicit update ownership

The central dependency automation control plane SHALL own Nix inputs. Renovate SHALL own GitHub Actions and any supported ecosystem dependencies outside Nix. Renovate's beta Nix manager SHALL remain disabled. The target repository SHALL NOT store the updater App private key or run a competing Nix scheduler.

#### Scenario: Inspect updater configuration

- **WHEN** a maintainer reads the dependency operations document, target automation files, and central registry
- **THEN** every dependency class has exactly one updater and one source of version truth
- **AND** the target repository contains no App credential or scheduled Nix update workflow

### Requirement: Authenticated weekly pull request

A weekly and manually dispatchable central workflow SHALL run a complete flake lock update and open or refresh a review-only pull request. It SHALL use a short-lived GitHub App token scoped to this repository and SHALL NOT merge the pull request.

#### Scenario: Locked inputs change

- **WHEN** the central workflow produces a different `flake.lock`
- **THEN** it creates a pull request whose head commit starts the normal Darwin and Linux checks automatically

#### Scenario: Locked inputs do not change

- **WHEN** the locked inputs are current
- **THEN** the workflow exits successfully without an empty commit or pull request
