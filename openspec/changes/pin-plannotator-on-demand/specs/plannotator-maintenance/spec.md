## Purpose

Keep Plannotator advancement explicit through a commit-pinned vendor input without weakening workstation release checks.

## ADDED Requirements

### Requirement: On-demand application advancement

Routine dependency automation SHALL NOT advance the selected Plannotator source revision or application version. An explicit Plannotator update SHALL review and change its declared source selection. Other tools SHALL retain their existing update ownership. Build-dependency or vendor recipe changes MAY rebuild the same application version.

#### Scenario: Routine complete lock update

- **WHEN** the central updater runs its complete flake lock update
- **THEN** the selected Plannotator source revision and application version remain unchanged
- **AND** other eligible inputs can advance without another scheduler or updater exception

#### Scenario: Explicit Plannotator update

- **WHEN** an operator requests a Plannotator update
- **THEN** its source selection changes through a reviewed repository change
- **AND** vendor package review and applicable both-platform behavior verification remain required

### Requirement: Shared unmodified vendor package

Both workstation hosts SHALL select Plannotator from the same commit-pinned vendor input. Each host SHALL use its unmodified vendor package, including vendor packaging patches and dependencies. The workstation SHALL NOT append a downstream client-lease patch or maintain a separate package recipe.

#### Scenario: Evaluate the final host compositions

- **WHEN** each host resolves its annotation executable after removal of the local override
- **THEN** its selection equals the corresponding unmodified `plannotator-packages` vendor package
- **AND** both hosts use the declared vendor revision and application version
- **AND** other tool selections remain unchanged

### Requirement: Preserve existing verification and runtime contracts

The on-demand pin SHALL preserve required native checks and the annotation-only adapter contract. It SHALL NOT add custom CI caching, installers, approval controls, automatic activation, mutable source checkouts, or network access. Documentation SHALL distinguish source pinning from guaranteed build reuse. Closing a browser tab MAY leave a review pending until explicit cancellation, session navigation, or shutdown.

#### Scenario: Verify the final stock selection

- **WHEN** the maintenance change is submitted for acceptance
- **THEN** evidence verifies the complete updater command and both host selections against the final unmodified vendor package
- **AND** ordered native checks and the Darwin build-plan and system-build gates pass for that selection
- **AND** the separate visual-feedback release retains all unverified browser, activation, network, and rollback gates

#### Scenario: Recover a pending review

- **WHEN** a browser tab closes while its review remains pending
- **THEN** `/plannotator-cancel` remains available to stop the owned review
- **AND** the integration does not promise automatic tab-close settlement or substitute approval mode, a new timeout, or a fallback
