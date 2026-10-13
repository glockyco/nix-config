# Plannotator Maintenance Specification

## Purpose

Keep Plannotator advancement explicit through a commit-pinned vendor input without weakening workstation release checks.

## Requirements

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

Both supported hosts SHALL use unmodified vendor Plannotator with explicit platform provenance: the Mac's commit-pinned vendor Nix package and native Windows' reviewed official release owned by make-korolev-windows-native. They SHALL not append a downstream lease patch or maintain a second package recipe. An identical Nix package source/version on Windows SHALL not be required.

#### Scenario: Evaluate the final host compositions

- **WHEN** each host resolves its annotation executable
- **THEN** the Mac selects its unmodified plannotator-packages output and Windows its accepted official native release
- **AND** each selection's source/release/version is recorded
- **AND** other tool selections remain unchanged

### Requirement: Preserve existing verification and runtime contracts

Explicit platform source/release selection SHALL preserve required native gates and the annotation-only adapter contract. Maintenance SHALL introduce no custom CI caching, approval controls, automatic activation, mutable source checkout or Linux fallback. Windows SHALL retain its existing explicit official installer rather than gain another installer. Documentation SHALL distinguish pins from guaranteed build reuse. Tab closure SHALL not imply cancellation.

#### Scenario: Verify the final stock selection

- **WHEN** maintenance is submitted for acceptance
- **THEN** evidence verifies the updater behavior and both native vendor selections
- **AND** ordered native checks and Mac build-plan/system-build gates pass where applicable
- **AND** visual-feedback release retains browser, activation, network, cancellation and recovery gates

#### Scenario: Recover a pending review

- **WHEN** a browser tab closes while its review remains pending
- **THEN** /plannotator-cancel remains available to stop the owned review
- **AND** no automatic tab-close settlement, approval mode, new timeout or fallback is promised
