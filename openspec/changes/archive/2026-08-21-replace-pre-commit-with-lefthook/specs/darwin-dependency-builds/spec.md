## ADDED Requirements

### Requirement: Source-free Darwin build plans

Every output this repository asks Nix to build on Darwin SHALL have a build plan that contains no source-built .NET package and no Swift compiler. This covers each check, each package, and the development shell, not one selected package.

Nixpkgs publishes no `aarch64-darwin` binary for the source-built .NET SDK or for Swift, so any build plan that reaches one compiles both toolchains. A test-only dependency is enough to reach them.

#### Scenario: A repository output gains a source-built toolchain

- **WHEN** a change adds a dependency whose Darwin build plan reaches a source-built .NET package or a Swift compiler
- **THEN** the repository checks fail
- **AND** the failure names the output and the dependency path that reaches the toolchain

#### Scenario: Every output is covered

- **WHEN** the verification runs
- **THEN** it reads the current set of repository outputs rather than a hand-written list
- **AND** an output added later is verified without editing the verification

#### Scenario: Clean Darwin CI run

- **WHEN** the Darwin continuous integration job runs against a warm public cache
- **THEN** it completes without compiling a .NET SDK or a Swift toolchain from source

## MODIFIED Requirements

### Requirement: Minimal managed language-server toolchain

The wrapped OMP package SHALL provide Marksman and Roslyn without requiring source builds of .NET packages or Swift on Darwin. The selected package scope SHALL use fixed-output .NET runtime and SDK binaries from Nixpkgs and SHALL preserve both existing executables.

#### Scenario: Inspect the managed language-server build plan

- **WHEN** the repository checks run against a clean Darwin build of the wrapped OMP package
- **THEN** the build plan contains the selected Marksman and Roslyn language servers
- **AND** it does not contain a Swift compiler or source-built .NET package
- **AND** the result comes from an automated check, not from reading the plan by hand

#### Scenario: Run the wrapped OMP command

- **WHEN** the wrapped OMP command starts with its managed language servers
- **THEN** the Marksman and Roslyn executables remain available on `PATH`
