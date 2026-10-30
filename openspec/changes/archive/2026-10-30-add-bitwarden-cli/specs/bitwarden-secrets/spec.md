# Spec Delta

## Purpose

Provide the official native Bitwarden CLI as a workstation prerequisite while leaving vault use to the personal OMP plugin.

## ADDED Requirements

### Requirement: Native Bitwarden CLI on both workstations

A fresh shell on macbook-pro and native Windows Korolev SHALL resolve `bw` from its platform-owned installation. Mac delivery SHALL use a cached package and dependency closure rather than source compilation. Korolev installation SHALL use standard-user scope without elevation and SHALL preserve an already installed newer version.

#### Scenario: Resolve the command after installation

- **WHEN** the reviewed configuration has been activated on the Mac and applied on Korolev
- **THEN** `bw --version` succeeds in a fresh Mac zsh and a fresh native PowerShell 7 session
- **AND** no competing installer or Administrator prompt is required for Bitwarden CLI

#### Scenario: Inspect Mac package delivery

- **WHEN** the locked Mac package is accepted
- **THEN** its complete dependency closure is available from configured binary caches
- **AND** acceptance fails if delivery requires source compilation

#### Scenario: Preserve a newer Windows installation

- **WHEN** Korolev already has a newer Bitwarden CLI installation
- **THEN** dry run accepts it and apply neither reinstalls nor downgrades it

### Requirement: Plugin-owned vault use

Workstation configuration SHALL install the CLI only. The personal OMP plugin SHALL own vault use. Workstation activation SHALL NOT create vault directories or manage server configuration, authentication, unlock caches, approvals, secret delivery or model-bound scrubbing.

#### Scenario: Reapply workstation configuration

- **WHEN** workstation configuration is reapplied
- **THEN** plugin-owned vault state remains untouched
- **AND** the Secrets documentation directs vault use to the personal OMP plugin
