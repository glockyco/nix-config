## MODIFIED Requirements

### Requirement: Source-free Darwin build plans

Every output this repository asks Nix to build on Darwin SHALL have a build plan that contains no source-built .NET package, Swift compiler, Markdown Oxide application, or Roslyn language server. This covers each check, each package, and the development shell, not one selected package.

Nixpkgs publishes no `aarch64-darwin` binary for these builds, so any build plan that reaches one compiles it in CI. A test-only dependency is enough to reach them.

#### Scenario: A repository output gains a source-built toolchain

- **WHEN** a change adds a dependency whose Darwin build plan reaches a source-built .NET package, Swift compiler, Markdown Oxide application, or Roslyn language server
- **THEN** the Darwin CI build-plan guard fails before CI builds the repository checks
- **AND** the failure names the output and the dependency path that reaches the source build

#### Scenario: Every output is covered

- **WHEN** the verification runs
- **THEN** it reads the current set of repository outputs rather than a hand-written list
- **AND** an output added later is verified without editing the verification

#### Scenario: Clean Darwin CI run

- **WHEN** the Darwin continuous integration job runs against a warm public cache
- **THEN** it completes without compiling a .NET SDK, Swift toolchain, Markdown Oxide application, or Roslyn language server from source

### Requirement: Minimal managed language-server toolchain

The wrapped OMP package SHALL provide Markdown Oxide and Roslyn from official, fixed-output platform artifacts on every supported system. Roslyn SHALL use a binary .NET runtime to launch its downloaded language-server payload. The wrapper SHALL provide `markdown-oxide` and `Microsoft.CodeAnalysis.LanguageServer` without compiling either application from source, and SHALL NOT provide Marksman as an alias or fallback.

#### Scenario: Inspect the managed language-server build plan

- **WHEN** the repository checks run against a clean Darwin build of the wrapped OMP package
- **THEN** the build plan contains the selected fixed-output Markdown Oxide and Roslyn artifacts
- **AND** it does not contain a Swift compiler, source-built .NET package, source-built Markdown Oxide application, or source-built Roslyn language server
- **AND** the result comes from an automated check, not from reading the plan by hand

#### Scenario: Run the wrapped OMP command

- **WHEN** the wrapped OMP command starts with its managed language servers
- **THEN** the `markdown-oxide` and `Microsoft.CodeAnalysis.LanguageServer` executables are available on `PATH`
- **AND** `marksman` is absent
