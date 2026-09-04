## ADDED Requirements

### Requirement: Installed and activation programs are packages with behavior checks

Every program that a host installs for the user or runs at activation SHALL be a package under `packages/` with `meta.description`, `meta.mainProgram`, and `meta.platforms`. Each such package SHALL have a repository check that runs the built program against doubles or fixtures and asserts its observable behavior. A module SHALL NOT interpolate a script file by path into a shell string.

#### Scenario: Inspect a program a host installs

- **WHEN** a maintainer lists the programs that a host installs or runs at activation
- **THEN** each resolves to a package under `packages/`
- **AND** each package has a check that exercises its behavior

#### Scenario: A program regresses

- **WHEN** a change makes a packaged program write where the current state already matches, or exit zero on an error it does not document
- **THEN** the program's check fails

#### Scenario: A Python program is imported by its test

- **WHEN** a test imports a packaged Python program
- **THEN** the import performs no subprocess call, reads no command-line argument, and exits nothing
- **AND** the program's behavior is reachable through a `main` function
