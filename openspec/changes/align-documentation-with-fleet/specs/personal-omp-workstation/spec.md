## Superseded proposal

This delta remains unimplemented. [simplify-repository-documentation](../../../archive/2026-09-05-simplify-repository-documentation/proposal.md) replaces the cleanup approach, not the accepted behavioral contract. Do not merge or archive this delta as accepted. References below describe the historical proposal.

## MODIFIED Requirements

### Requirement: Pinned executable and plugin inputs

The workstation SHALL resolve the personal plugin from an independently locked flake input. The personal plugin input SHALL provide a valid OMP plugin directory and SHALL remain in the `omp-agent-setup` repository rather than being copied into `nix-config`. The OMP executable SHALL be mutable platform-owned state: the official Homebrew formula on Darwin and the official prebuilt user-local binary in NixOS/WSL. No supported host SHALL retain a Nix-packaged OMP executable or fallback.

#### Scenario: Build the workstation package

- **WHEN** the workstation OMP wrapper is built for a supported host system
- **THEN** its personal plugin directory comes from a locked Nix store path
- **AND** the wrapper targets the platform-owned OMP executable
- **AND** the wrapper closure contains no Nix-packaged OMP executable

### Requirement: Representative language-server matrix

The workstation SHALL provide one primary server for C#, Python, TypeScript and JavaScript, Svelte, Nix, Markdown, and LaTeX and BibTeX. The personal plugin SHALL override OMP defaults only where required to select that primary server or correct root detection. The repository checks SHALL prove that every primary server resolves in the wrapper environment. The documented language smoke SHALL be a live procedure that the operator runs after a language-server change.

#### Scenario: Resolve every server

- **WHEN** the repository checks build the wrapper for a supported host system
- **THEN** each primary server executable resolves in the wrapper environment
- **AND** a missing server fails the check instead of being reported as a warning

#### Scenario: Exercise the matrix

- **WHEN** the operator runs the documented language smoke in a wrapped session against fixed representative projects
- **THEN** each server starts through the workstation environment
- **AND** diagnostics are requested for every language
- **AND** definition, references, and rename are exercised for each language where the server supports the operation
- **AND** a failed or missing server fails the smoke instead of being reported as a warning

### Requirement: Container runtime on the WSL host

The WSL host SHALL provide a rootless container runtime that accepts Docker commands. The runtime SHALL run inside the WSL distribution. The workstation SHALL NOT require a Windows container product, and SHALL NOT require nested virtualization. The repository checks SHALL prove the declared runtime shape without running a container. The documented provisioning procedure SHALL include a live container smoke.

#### Scenario: Declare the runtime

- **WHEN** the repository checks evaluate the WSL host configuration
- **THEN** the configuration declares a rootless runtime that serves the Docker command name
- **AND** it declares no Docker daemon, no container socket service, and no virtual-machine service

#### Scenario: Run a container

- **WHEN** the user runs the documented container smoke on the WSL host after activation
- **THEN** the container starts and exits with its own status
- **AND** the runtime requires no root privileges and no separate virtual machine

#### Scenario: Use the Docker command name

- **WHEN** a project command invokes the Docker command name
- **THEN** the declared runtime serves that command

#### Scenario: Preserve the boundary

- **WHEN** the host configuration is reviewed
- **THEN** it declares no Windows container product
- **AND** it declares no listening container service that another host can reach

## REMOVED Requirements

### Requirement: Generated OpenSpec adapter freshness

**Reason**: This repository tracks no OpenSpec adapter. The adapters are plugin content that `omp-agent-setup` generates and ships, and the accepted architecture forbids `openspec init` in a consuming repository. The scenario "the selected OpenSpec package would rewrite a tracked adapter" has no subject here, and the only assertion behind it tests that the pinned plugin ships the adapter commands.

**Migration**: `omp-agent-setup` owns adapter generation and its review before a plugin release. The workstation package-shape check keeps asserting that the pinned plugin ships the adapter commands, under the requirement "Pinned executable and plugin inputs". The OpenSpec version gate stays under "OpenSpec package consistency".
