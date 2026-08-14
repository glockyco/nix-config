## ADDED Requirements

### Requirement: OpenSpec package consistency

The workstation checks SHALL verify that the OpenSpec executable reports the version declared by its Nix package. They SHALL NOT require a hard-coded historical version after a reviewed update.

#### Scenario: Package and executable disagree

- **WHEN** the packaged executable reports a version different from its Nix package metadata
- **THEN** the workstation release gate fails

### Requirement: Generated OpenSpec adapter freshness

The workstation checks SHALL verify that tracked OpenSpec commands and skills match the selected generator. An OpenSpec update SHALL require review of generated changes before merge.

#### Scenario: Generator output changes

- **WHEN** the selected OpenSpec package would rewrite a tracked adapter
- **THEN** the release gate fails until the generated difference is reviewed and committed

### Requirement: Archived change completeness

The workstation checks SHALL reject an archived OpenSpec change that contains an incomplete task. Strict validation SHALL also retain scenario and task-numbering checks for active contracts.

#### Scenario: An incomplete change is archived

- **WHEN** an archived change contains an unchecked task
- **THEN** the workstation release gate fails

### Requirement: Preserved runtime acceptance

Dependency automation SHALL retain wrapper-shape checks, Herdr reconciliation tests, activation verification, and the conditional real wrapped-session smoke.

#### Scenario: Automation implementation changes

- **WHEN** repository automation changes without changing OMP runtime behavior
- **THEN** deterministic checks pass without a model call and the existing runtime acceptance path remains available
