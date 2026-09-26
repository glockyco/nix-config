## MODIFIED Requirements

### Requirement: Explicit update ownership

The central dependency automation control plane SHALL own Nix inputs. Renovate SHALL own GitHub Actions and supported ecosystem dependencies outside Nix. Nix SHALL supply the OMP wrapper, updater, personal plugin, and language tools. `omp-dev-update` SHALL prepare and select host-local patched OMP source generations on each supported host; no platform-native installer SHALL own those generations. Renovate's beta Nix manager SHALL remain disabled. The target repository SHALL NOT store the updater App private key or run a competing Nix scheduler.

#### Scenario: Inspect updater configuration

- **WHEN** a maintainer reads the dependency operations document, target automation files, and central registry
- **THEN** every dependency class has exactly one declared update owner and one source of version truth
- **AND** `omp-dev-update` selects patched OMP source generations outside Nix activation
- **AND** the target repository contains no App credential or scheduled Nix update workflow

### Requirement: Manual activation boundary

Merging an update pull request SHALL NOT activate a host or mutate OMP-owned state. A human SHALL build and activate each Nix generation and inspect local verification. Preparing or selecting an OMP source generation with `omp-dev-update` SHALL remain an explicit operation outside Nix activation.

#### Scenario: Merge a dependency update

- **WHEN** all required checks pass and a maintainer merges the pull request
- **THEN** each active host remains unchanged until deliberate activation
- **AND** each selected OMP version remains unchanged until an explicit `omp-dev-update` operation

#### Scenario: Update OMP

- **WHEN** the operator runs `omp-dev-update` on a supported host
- **THEN** the updater prepares and checks a host-native patched source generation before selecting it
- **AND** the operation does not change the repository or a Nix generation
- **AND** the operator can run deterministic local verification against the selected generation

### Requirement: Retained rollback

The update procedure SHALL retain the previous Nix generation until activation verification and any required real-session smoke pass. It SHALL state that the selected OMP source generation is outside Nix-generation rollback. It SHALL provide `omp-dev-update --rollback` as the OMP version-recovery path on both supported hosts.

#### Scenario: New generation fails acceptance

- **WHEN** activation verification or the release smoke fails after a Nix change
- **THEN** the maintainer can restore the previous immutable Nix generation without replacing mutable OMP state
- **AND** the rollback does not claim to change the selected OMP version

#### Scenario: OMP update fails acceptance

- **WHEN** a selected OMP source generation fails deterministic verification or the real-session smoke
- **THEN** the documented recovery procedure selects the previous verified generation with `omp-dev-update --rollback`
- **AND** it does not direct the operator to roll back a Nix generation as an OMP version rollback

### Requirement: Discoverable operations

The repository SHALL contain one concise agent entry point and one canonical dependency-update runbook. They SHALL identify ownership, schedule, manual commands, required checks, activation, smoke, and rollback. They SHALL identify `omp-dev-update` as the only declared OMP source updater and SHALL NOT introduce another updater or scheduler.

#### Scenario: Resume in a new session

- **WHEN** an agent receives an update question in the repository
- **THEN** repository guidance points directly to the runbook and the declared Nix and `omp-dev-update` commands
