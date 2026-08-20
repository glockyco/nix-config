## Purpose

Defines one planning authority for the workstation repository while preserving intended work, delivered behavior, and architecture in separate owners.

## ADDED Requirements

### Requirement: OpenSpec is the sole repository planning home

The repository SHALL keep current change plans under `openspec/changes/` and accepted behavior under `openspec/specs/`. Current guidance and documentation SHALL NOT declare another repository planning location.

#### Scenario: A reader locates current work

- **WHEN** a reader follows repository guidance to find active implementation work
- **THEN** the guidance directs the reader to `openspec/changes/`
- **AND** it does not direct the reader to `docs/plans/` or a planning index

### Requirement: Confirmed independent work has focused owners

Each operator-confirmed independent workstream SHALL have its own OpenSpec change before its legacy record is removed. The repository SHALL NOT combine unrelated deferred or draft work into an umbrella backlog.

#### Scenario: Migrate the five confirmed workstreams

- **WHEN** the legacy planning home is retired
- **THEN** PDF toolset evaluation, email migration, family continuity, knowledge management, and multi-host fleet design each have a named OpenSpec owner
- **AND** no owner implements another workstream

#### Scenario: A workstream is not yet scheduled

- **WHEN** a confirmed workstream has no implementation date
- **THEN** its OpenSpec artifacts preserve the intent and acceptance boundary
- **AND** no shared index carries separate status for it

### Requirement: Delivered and superseded records receive verified disposition

Before removing a completed or superseded record, the repository SHALL verify its claims against current configuration, accepted specs, current documentation, and observed behavior. Unique current content SHALL move to one authoritative owner. Content with no current value SHALL remain available only through Git history.

#### Scenario: A completed record describes delivered behavior

- **WHEN** delivered behavior still depends on a unique statement from the record
- **THEN** that statement exists in an accepted spec or operational document before removal

#### Scenario: A superseded OMP record conflicts with accepted architecture

- **WHEN** a legacy OMP record describes mutable deployment or retired commands
- **THEN** accepted `personal-omp-workstation` behavior and the canonical architecture remain authoritative
- **AND** the conflicting record is removed

### Requirement: Architecture does not own implementation tasks

The canonical architecture MAY own system boundaries, current state, dependency ordering, experiment protocols, and acceptance constraints. It SHALL NOT own repository implementation tasks, deferred backlogs, or resumable task sequences.

#### Scenario: Architecture describes future repository work

- **WHEN** a future action belongs to an owning repository
- **THEN** the architecture links to that repository's named OpenSpec change
- **AND** the architecture does not duplicate the change's tasks

#### Scenario: No owner exists for a future statement

- **WHEN** a future statement has no confirmed OpenSpec owner
- **THEN** the architecture does not present it as active implementation work

### Requirement: Repository validation guards the sole home

The normal repository validation path SHALL reject a restored `docs/plans/` tree, a current reference to the retired path, or guidance that declares a second planning home. The detector SHALL prove its reach with a known conflicting fixture.

#### Scenario: A second planning tree is added

- **WHEN** a tracked file is added under `docs/plans/`
- **THEN** repository validation fails and reports the path

#### Scenario: The repository follows the planning contract

- **WHEN** current planning is owned by OpenSpec and current architecture contains no task backlog
- **THEN** repository validation passes
