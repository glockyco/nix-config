## MODIFIED Requirements

### Requirement: Explicit update ownership

The central dependency automation control plane SHALL own Nix inputs. Renovate SHALL own GitHub Actions and supported ecosystem dependencies outside Nix. Platform-native installers SHALL own OMP executable updates: Homebrew on Darwin and the official prebuilt binary installer in NixOS/WSL. Renovate's beta Nix manager SHALL remain disabled. The target repository SHALL NOT store the updater App private key or run a competing Nix scheduler.

#### Scenario: Inspect updater configuration

- **WHEN** a maintainer reads the dependency operations document, target automation files, and central registry
- **THEN** every dependency class has exactly one updater and one source of version truth
- **AND** OMP executable updates use the documented platform-native installer instead of a Nix input
- **AND** the target repository contains no App credential or scheduled Nix update workflow

### Requirement: Manual activation boundary

Merging an update pull request SHALL NOT activate a host or mutate OMP-owned state. A human SHALL build and activate each Nix generation and inspect local verification. An OMP executable update SHALL remain an explicit operation outside Nix activation.

#### Scenario: Merge a dependency update

- **WHEN** all required checks pass and a maintainer merges the pull request
- **THEN** each active host remains unchanged until deliberate activation
- **AND** each installed OMP version remains unchanged until an explicit platform-native update

#### Scenario: Update OMP

- **WHEN** the operator runs the documented platform-native OMP update command
- **THEN** the owning installer updates OMP without changing the repository or a Nix generation
- **AND** the operator can run deterministic local verification against the updated executable

### Requirement: Retained rollback

The update procedure SHALL retain the previous Nix generation until activation verification and any required real-session smoke pass. It SHALL state that the platform-owned OMP executable is outside Nix-generation rollback and provide an explicit OMP version-recovery path for each host.

#### Scenario: New generation fails acceptance

- **WHEN** activation verification or the release smoke fails after a Nix change
- **THEN** the maintainer can restore the previous immutable Nix generation without replacing mutable OMP state
- **AND** the rollback does not claim to change the platform-owned OMP version

#### Scenario: OMP update fails acceptance

- **WHEN** an updated OMP executable fails deterministic verification or the real-session smoke
- **THEN** the documented recovery procedure uses the platform installer with an explicit previous release
- **AND** it does not direct the operator to roll back a Nix generation as an OMP version rollback
