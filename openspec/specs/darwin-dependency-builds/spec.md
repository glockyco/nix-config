# darwin-dependency-builds Specification

## Purpose

Define reproducible and minimal dependency sources for Darwin-only workstation artifacts so routine builds remain reliable without changing installed behavior.

## Requirements

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

### Requirement: Minimal managed language-server toolchain

The wrapped OMP package SHALL provide Marksman and Roslyn without requiring source builds of .NET packages or Swift on Darwin. The selected package scope SHALL use fixed-output .NET runtime and SDK binaries from Nixpkgs and SHALL preserve both existing executables.

#### Scenario: Inspect the managed language-server build plan

- **WHEN** a maintainer evaluates a clean Darwin build of the wrapped OMP package
- **THEN** the build plan contains the selected Marksman and Roslyn language servers
- **AND** it does not contain a Swift compiler or source-built .NET package

#### Scenario: Run the wrapped OMP command

- **WHEN** the wrapped OMP command starts with its managed language servers
- **THEN** the Marksman and Roslyn executables remain available on `PATH`
