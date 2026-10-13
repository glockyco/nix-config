# python-project-tooling Specification

## Purpose

Provides managed hosts with the bootstrap command required to create reproducible, project-local Python environments from repository lockfiles.

## Requirements

### Requirement: Managed login shells provide uv

The configured user's fresh shell SHALL resolve uv on macbook-pro and native Windows Korolev. The Mac SHALL retain its Nix-managed package; Windows SHALL use the native uv provisioning owned by make-korolev-windows-native, without Nix or WSL delegation. Project environments and lockfiles SHALL remain project-owned.

#### Scenario: User opens a fresh login shell

- **WHEN** the host's configuration has been applied and the user opens a new shell
- **THEN** uv --version completes successfully without an ad hoc Nix shell or a Linux launcher

#### Scenario: Shared package configuration is evaluated

- **WHEN** macbook-pro evaluates its system configuration
- **THEN** its evaluated users.users.<name>.packages set contains the Nixpkgs uv package
- **AND** Windows uv ownership remains native and independent of that system package set

### Requirement: Python dependencies remain project-local

The global tool installation SHALL NOT install or prescribe project Python dependencies outside each repository's environment and lockfile.

#### Scenario: User synchronizes a locked Python project

- **WHEN** the user runs `uv sync` in a repository with `pyproject.toml` and `uv.lock`
- **THEN** `uv` creates or updates that repository's local environment from its declared dependencies
