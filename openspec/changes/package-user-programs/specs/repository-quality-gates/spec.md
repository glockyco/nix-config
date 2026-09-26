## ADDED Requirements

### Requirement: Installed and activation programs are packages with behavior checks

Each repository-owned user or activation program introduced by this change SHALL be a package under `packages/<name>/package.nix`, with `meta.description`, `meta.mainProgram`, and `meta.platforms`. Each SHALL have `packages/<name>/tests.nix` that runs the built program against doubles or fixtures and asserts observable behavior. Python programs SHALL also run their stdlib unit tests during package builds. A module SHALL NOT interpolate a source script path into an activation command.

#### Scenario: Inspect a program a host installs

- **WHEN** a maintainer lists the repository-owned user and activation programs introduced by this change
- **THEN** each resolves to `packages/<name>/package.nix`
- **AND** each has a sibling `tests.nix` that exercises its behavior

#### Scenario: A program regresses

- **WHEN** a change makes a packaged program write where the current state already matches, or exit zero on an error it does not document
- **THEN** the program's check fails

#### Scenario: A Python program is imported by its test

- **WHEN** a test imports a packaged Python program
- **THEN** the import performs no subprocess call, reads no command-line argument, and exits nothing
- **AND** the program exposes `main(argv: Sequence[str] | None = None) -> int`, which owns `argparse`, parses `sys.argv[1:]` when `argv` is `None`, and returns the console script's exit status
