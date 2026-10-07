# Spec Delta

## MODIFIED Requirements

### Requirement: Managed login shells provide uv

Every managed host SHALL make a Nix-managed `uv` executable available in the configured user's fresh login shell.

#### Scenario: User opens a fresh login shell

- **WHEN** the host configuration has been activated and the user opens a new login shell
- **THEN** `uv --version` completes successfully without an ad hoc Nix shell or imperative installation

#### Scenario: Shared package configuration is evaluated

- **WHEN** either managed host evaluates its system configuration
- **THEN** the evaluated users.users.<name>.packages set contains the Nixpkgs `uv` package
