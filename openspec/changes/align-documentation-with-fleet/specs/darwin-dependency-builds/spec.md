## Superseded proposal

This delta remains unimplemented. [simplify-repository-documentation](../../../archive/2026-09-05-simplify-repository-documentation/proposal.md) replaces the cleanup approach, not the accepted behavioral contract. Do not merge or archive this delta as accepted.

## MODIFIED Requirements

### Requirement: Source-free Darwin build plans

Every output this repository asks Nix to build on Darwin SHALL have a build plan that contains no source-built .NET package, Swift compiler, Markdown Oxide application, or Roslyn language server. This covers each check, each package, and the development shell, not one selected package. The build-plan inspection SHALL be a release gate that runs on the Darwin host, separate from `nix flake check`, because a check derivation cannot read the store.

Nixpkgs publishes no `aarch64-darwin` binary for these builds, so any build plan that reaches one compiles an application or its toolchain. A test-only dependency is enough to reach them.

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
