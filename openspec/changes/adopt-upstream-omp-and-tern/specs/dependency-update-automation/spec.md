## MODIFIED Requirements

### Requirement: Explicit update ownership

The central dependency automation control plane SHALL own Nix inputs. Renovate SHALL own GitHub Actions and supported ecosystem dependencies outside Nix. Nix SHALL supply ordinary OpenSpec, Plannotator, and host-appropriate language tools, not OMP, its runtime personal plugin, Herdr, or a source updater. The official installer SHALL own initial standalone OMP delivery; `omp update` SHALL own executable updates; OMP's plugin manager SHALL own personal-plugin installation/upgrades using the commands defined by `publish-plugin-through-omp-plugin-manager`. Plannotator source advancement SHALL remain explicitly requested and commit-pinned. Renovate's beta Nix manager SHALL remain disabled. The target repository SHALL NOT store the updater App private key or run a competing Nix scheduler.

#### Scenario: Inspect updater configuration

- **WHEN** a maintainer reads the dependency operations document, target automation files, and central registry
- **THEN** every dependency class has exactly one declared update owner and one source of version truth
- **AND** official OMP and plugin-manager operations remain outside Nix activation
- **AND** the target repository contains no App credential or scheduled Nix update workflow

### Requirement: Manual activation boundary

Merging an update pull request SHALL NOT activate a host or mutate OMP-owned state. The operator SHALL authorize each Nix activation and inspect local verification; an agent MAY run the authorized command in a terminal while the owner enters required credentials. Official OMP installation/updates and personal-plugin manager operations SHALL remain explicit operations outside Nix activation.

#### Scenario: Merge a dependency update

- **WHEN** all required checks pass and a maintainer merges the pull request
- **THEN** each active host remains unchanged until deliberate activation
- **AND** each installed OMP/plugin version remains unchanged until its explicit upstream operation

#### Scenario: Update OMP

- **WHEN** the operator runs `omp update` on a supported host
- **THEN** upstream OMP manages its official executable installation
- **AND** the operation does not change the repository or a Nix generation
- **AND** the operator verifies the observed installation and a fresh Tern session

### Requirement: Retained rollback

The update procedure SHALL retain the previous Nix generation until activation verification and required real-session smoke pass. Migration SHALL also retain old source generations while running sessions use them and until the replacement gates pass. The procedure SHALL state that the official OMP executable and plugin-manager runtime selection are outside Nix-generation rollback. Recorded accepted official releases MAY be restored explicitly with the supported binary installer; the procedure SHALL not promise an upstream rollback subcommand or retain `omp-dev-update --rollback` as a supported path.

#### Scenario: New generation fails acceptance

- **WHEN** activation verification or the release smoke fails after a Nix change
- **THEN** the maintainer can restore the previous Nix generation without replacing mutable OMP state
- **AND** the rollback does not claim to change the official OMP/plugin version

#### Scenario: OMP update fails acceptance

- **WHEN** the installed OMP release fails direct verification or the real-session smoke
- **THEN** the operator reports the failure and follows an authorized supported official-installer recovery to a recorded accepted release when available
- **AND** it does not direct the operator to roll back a Nix generation as an OMP version rollback
- **AND** unavailable recovery prerequisites are reported rather than fabricated

### Requirement: Discoverable operations

The repository SHALL contain one concise agent entry point and one canonical dependency-update runbook for remaining package maintenance and release smoke. AGENTS.md and README SHALL identify official OMP installer/update commands, plugin-manager install/upgrade commands, update ownership, schedule, required checks, activation, smoke, and recovery boundaries. The obsolete OMP source-update/patch-repair/recovery runbook and repository OMP update skill SHALL be removed. No new updater or scheduler SHALL replace them.

#### Scenario: Resume in a new session

- **WHEN** an agent receives an update question in the repository
- **THEN** repository guidance points directly to the declared Nix, `omp update`, and published plugin-manager commands
- **AND** it does not refer the agent to a removed wrapper, verifier, source updater, or Herdr integration
