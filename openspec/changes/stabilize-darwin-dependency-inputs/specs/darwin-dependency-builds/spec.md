## Purpose

Define reproducible and minimal dependency sources for Darwin-only workstation artifacts so routine builds remain reliable without changing installed behavior.

## ADDED Requirements

### Requirement: Fixed-output keyboard resources

The workstation SHALL build the Neo keyboard bundle from official macOS release resources with fixed cryptographic hashes. It SHALL NOT require a full upstream repository clone to evaluate or build the bundle.

#### Scenario: Build the keyboard bundle

- **WHEN** Nix builds the Neo keyboard package from a clean store
- **THEN** the result contains the Neo 2, NeoQwertz, and Bone layouts and their icons
- **AND** every downloaded resource is verified against its declared hash

#### Scenario: Upstream resource changes

- **WHEN** an official release resource no longer matches its declared hash
- **THEN** the build fails before installing a changed keyboard layout

### Requirement: Preserved layout validation

The Neo package SHALL reject duplicate keyboard layout identifiers before producing an installable bundle.

#### Scenario: Duplicate identifier appears

- **WHEN** two selected keyboard resources declare the same layout identifier
- **THEN** the package build fails and reports the duplicate identifier

### Requirement: Minimal Roslyn toolchain

The wrapped OMP package SHALL provide Roslyn without requiring source builds of .NET SDKs or Swift on Darwin. The selected package set SHALL use fixed-output .NET SDK binaries from Nixpkgs and SHALL preserve the existing Roslyn executable.

#### Scenario: Inspect the Roslyn build plan

- **WHEN** a maintainer evaluates a clean Darwin build of the wrapped OMP package
- **THEN** the build plan contains the selected Roslyn language server
- **AND** it does not contain a Swift compiler or source-built .NET SDK

#### Scenario: Run the wrapped OMP command

- **WHEN** the wrapped OMP command starts with its managed language servers
- **THEN** the Roslyn executable remains available on `PATH`
