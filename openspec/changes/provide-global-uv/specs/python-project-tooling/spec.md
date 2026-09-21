## Purpose

Provides managed hosts with the bootstrap command required to create reproducible, project-local Python environments from repository lockfiles.

## ADDED Requirements

### Requirement: Managed login shells provide uv

Every managed host SHALL make a Nix-managed `uv` executable available in the configured user's fresh login shell.

#### Scenario: User opens a fresh login shell

- **WHEN** the host configuration has been activated and the user opens a new login shell
- **THEN** `uv --version` completes successfully without an ad hoc Nix shell or imperative installation

#### Scenario: Shared package configuration is evaluated

- **WHEN** either managed host evaluates its Home Manager configuration
- **THEN** the evaluated user package set contains the Nixpkgs `uv` package

### Requirement: Python dependencies remain project-local

The global tool installation SHALL NOT install or prescribe project Python dependencies outside each repository's environment and lockfile.

#### Scenario: User synchronizes a locked Python project

- **WHEN** the user runs `uv sync` in a repository with `pyproject.toml` and `uv.lock`
- **THEN** `uv` creates or updates that repository's local environment from its declared dependencies
