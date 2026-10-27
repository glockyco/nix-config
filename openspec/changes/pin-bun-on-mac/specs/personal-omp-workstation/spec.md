## ADDED Requirements

### Requirement: Bun for the personal plugin repository on the Mac

The Mac SHALL provide `bun` in managed login shells at the version that the Windows application declaration pins for omp-agent-setup's `.bun-version`. The package SHALL come from Bun's official release archive with a fixed hash and SHALL NOT replace the Bun that other packages build with.

#### Scenario: Run the plugin repository's hooks

- **WHEN** a fresh login shell or an OMP session on the Mac runs `bun --version`
- **THEN** it prints the version pinned in `windows/workstation.json`

#### Scenario: Pins drift apart

- **WHEN** the Bun version in `windows/workstation.json` differs from the Mac package's version
- **THEN** the flake checks fail and name both versions
