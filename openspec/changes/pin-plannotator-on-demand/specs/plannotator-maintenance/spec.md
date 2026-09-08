## Purpose

Keep Plannotator release advancement explicit and reuse verified package outputs in native CI without weakening workstation release checks.

## ADDED Requirements

### Requirement: On-demand application advancement

Routine dependency automation SHALL NOT advance the selected Plannotator source revision or application version. An explicit Plannotator update SHALL review and change its declared source selection. Other tools SHALL retain their existing update ownership. Build-dependency or downstream-patch changes MAY rebuild the same application version.

#### Scenario: Routine complete lock update

- **WHEN** the central updater runs its complete flake lock update
- **THEN** the selected Plannotator source revision and application version remain unchanged
- **AND** other eligible inputs can advance without another scheduler or updater exception

#### Scenario: Explicit Plannotator update

- **WHEN** an operator requests a Plannotator update
- **THEN** its source selection changes through a reviewed repository change
- **AND** downstream patch review and both-platform behavior verification remain required

### Requirement: Shared package and annotation contracts

Both workstation hosts SHALL select the same Plannotator source and downstream patch. The package SHALL reuse the existing vendor recipe. Update-policy changes SHALL NOT add installers, approval controls, automatic activation, mutable source checkouts, or network access.

#### Scenario: Evaluate both host compositions

- **WHEN** each host resolves its annotation executable
- **THEN** both selections use the reviewed source and patch
- **AND** the existing annotation-only and activation boundaries remain unchanged

### Requirement: Native CI output reuse

Native CI SHALL restore previously verified package outputs for an identical evaluated derivation and system when an accessible cache exists. A cache hit SHALL NOT skip required release checks. Cache identities SHALL distinguish changes to package source, downstream patch, and build dependencies.

#### Scenario: Unrelated repository change

- **WHEN** a new native CI run selects the same package derivation as an accessible successful cache
- **THEN** it reuses the package output without rebuilding Plannotator from source
- **AND** every required check still executes

#### Scenario: Changed patch or toolchain

- **WHEN** a patch or build dependency changes the package derivation
- **THEN** an older cache cannot stand in for the newly selected output
- **AND** CI builds or obtains that exact output before reporting success

### Requirement: Cache failure and trust boundaries

Cache absence, eviction, or unavailability SHALL preserve the ordinary uncached build path. Only successful verification runs SHALL save new reusable caches. CI SHALL preserve platform and GitHub ref isolation, avoid new external credentials, and constrain retention. Workstation stores and trusted substituters SHALL remain unchanged.

#### Scenario: Cache miss or unavailable cache

- **WHEN** CI cannot restore a usable cache
- **THEN** the existing build and verification procedure remains available
- **AND** cache availability is not treated as application correctness

#### Scenario: Unsuccessful required check

- **WHEN** a required check fails
- **THEN** that run does not save a new cache as a verified result

#### Scenario: Pull-request cache isolation

- **WHEN** a pull request saves a cache
- **THEN** it retains GitHub's normal ref visibility and cannot replace a protected-branch cache through a custom promotion path
- **AND** no workstation receives a new cache trust configuration

### Requirement: Observable cache acceptance

Acceptance SHALL include cold and warm native CI runs on both architectures, actual cache size, derivation identity, and evidence that a warm run avoids the package source build. Documentation SHALL distinguish on-demand application updates, toolchain-triggered rebuilds, and best-effort CI cache retention.

#### Scenario: Report cache verification

- **WHEN** the cache change is submitted for acceptance
- **THEN** recorded results include successful cold builds, successful warm restores, and all required checks on both systems
- **AND** the report does not claim host downloads or guaranteed cache persistence
