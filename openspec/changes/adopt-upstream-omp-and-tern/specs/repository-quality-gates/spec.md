## MODIFIED Requirements

### Requirement: OpenSpec package consistency

The workstation checks SHALL verify that the ordinary host-installed OpenSpec executable reports the version declared by its Nix package and is the same derivation exposed by the shared package set. They SHALL NOT require a hard-coded historical version after a reviewed update or depend on an OMP wrapper/runtime plugin package.

#### Scenario: Package and executable disagree

- **WHEN** the packaged executable reports a version different from its Nix package metadata
- **THEN** the workstation release gate fails

### Requirement: Generated OpenSpec adapter freshness

The workstation checks SHALL verify that the personal plugin's tracked OpenSpec commands and skills match the selected generator independently of its runtime installation. The independently pinned build-time `lib.openspecCheck` and required generator tooling SHALL remain available after removal of plugin runtime package exports. An OpenSpec update SHALL require review of generated changes in `omp-agent-setup` before publication and review of the check-tool pin here before merge. Published marketplace commands SHALL use `/personal:opsx-*` without compatibility aliases; this repository SHALL NOT run `openspec init` or duplicate generated adapters.

#### Scenario: Generator output changes

- **WHEN** the selected OpenSpec package would rewrite a tracked adapter
- **THEN** the release gate fails until the generated difference is reviewed and committed in its owning plugin repository

## ADDED Requirements

### Requirement: Packaged program behavior checks

A packaged program's check SHALL execute the packaged program against controlled fixtures and stub executables. It SHALL assert observable exit status, output, and calls rather than script source text.

#### Scenario: Program source changes without behavior changing

- **WHEN** a program's source text changes but its observable behavior remains the same
- **THEN** its behavior check passes

## REMOVED Requirements

### Requirement: Program checks exercise the program

**Reason**: Its wrapper-specific selection/flag/error scenarios are obsolete with wrapper/updater/verifier deletion.
**Migration**: Preserve the generic program execution, fixtures, observable output/status/calls and source-refactor scenario verbatim under Packaged program behavior checks.
