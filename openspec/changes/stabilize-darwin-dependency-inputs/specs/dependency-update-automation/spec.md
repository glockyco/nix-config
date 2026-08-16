## ADDED Requirements

### Requirement: CI-reachable dependency sources

Dependencies exercised by required update checks SHALL use reproducible sources that can complete unattended on every required platform. A platform-specific artifact SHALL use the smallest official fixed-output source that preserves the accepted behavior when the authoritative repository transport is unreliable.

#### Scenario: Repository transport is unreliable

- **WHEN** repeated required checks fail or stall while fetching an authoritative repository
- **THEN** the package uses an official fixed-output release source when one provides the required artifact
- **AND** the obsolete repository input is removed completely

#### Scenario: Required source is not cacheable

- **WHEN** a routine update check evaluates its Darwin build plan
- **THEN** incidental compiler source builds are absent when Nixpkgs provides hash-pinned binary packages for the same supported toolchain
