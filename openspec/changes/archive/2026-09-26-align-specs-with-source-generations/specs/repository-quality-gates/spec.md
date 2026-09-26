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

### Requirement: One typed host declaration per host

Each host SHALL declare its host name and interactive user name through one declaration validated by the module system. A module that needs a host value SHALL read it from that typed declaration. No host value SHALL travel to a module as an untyped argument.

#### Scenario: A host omits a required value

- **WHEN** a host declaration omits the host name or interactive user name
- **THEN** evaluation fails with an error that names the missing option
- **AND** the failure occurs before any consumer of the value evaluates

#### Scenario: A module reads a host value

- **WHEN** a system or user-scope module needs the host name or interactive user name
- **THEN** it reads the value from the managing system's typed host declaration
- **AND** the host passes the value through no additional untyped argument

## REMOVED Requirements

### Requirement: Obsolete typed host declaration

**Reason**: The old declaration assigns OMP executable location and installation to nonexistent host options.

**Migration**: Use `One typed host declaration per host` with only host and user names.

## RENAMED Requirements

- FROM: `### Requirement: One typed host declaration per host`
- TO: `### Requirement: Obsolete typed host declaration`
