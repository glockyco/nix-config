## Superseded proposal

This delta remains unimplemented. [simplify-repository-documentation](../../../archive/2026-09-05-simplify-repository-documentation/proposal.md) replaces the cleanup approach. The issue migration, planning-policy check, and agent-owned gate statement below are historical proposals, not current requirements. Do not merge or archive this delta as accepted.

## ADDED Requirements

### Requirement: OpenSpec is the sole planning home

The repository SHALL keep current change plans under `openspec/changes/` and accepted behavior under `openspec/specs/`. Confirmed work without a scheduled change SHALL live as an issue in the owning repository. Current guidance and documentation SHALL NOT name another planning location in this repository. Repository validation SHALL reject a tracked file under `docs/plans/` and a current Markdown reference to that path, and SHALL prove its reach against a known conflicting fixture.

#### Scenario: A reader locates current work

- **WHEN** a reader follows repository guidance to find active implementation work
- **THEN** the guidance directs the reader to `openspec/changes/`
- **AND** it does not direct the reader to `docs/plans/` or a planning index

#### Scenario: Confirmed work is not scheduled

- **WHEN** confirmed work has no active OpenSpec change
- **THEN** an issue in the owning repository holds its intent and acceptance boundary
- **AND** no tracked file in this repository carries a separate status for it

#### Scenario: A second planning tree is added

- **WHEN** a tracked file is added under `docs/plans/`
- **OR** a Markdown file outside `openspec/changes/` refers to `docs/plans/`
- **THEN** repository validation fails and reports the path

#### Scenario: The detector proves its reach

- **WHEN** the planning-home check runs
- **THEN** it rejects a fixture tree that contains a planning record and a fixture tree that refers to the retired path
- **AND** it accepts a fixture tree whose only reference to the retired path is under `openspec/changes/`

### Requirement: One statement of the release gates

The agent entry point SHALL be the only document that lists the release-gate commands. It SHALL name the system on which each gate runs and the remote-builder path that lets the Linux host build the Darwin checks. Every other document that requires the gates SHALL link to that statement and SHALL NOT repeat a gate command.

#### Scenario: A maintainer reads the gates

- **WHEN** a maintainer opens the agent entry point
- **THEN** it lists every gate command with the system that runs it
- **AND** it states how the Linux host runs the Darwin checks

#### Scenario: A runbook requires the gates

- **WHEN** a runbook or the README reaches the point where the gates run
- **THEN** it links to the agent entry point
- **AND** it repeats no gate command
