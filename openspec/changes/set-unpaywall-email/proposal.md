# Proposal

## Why

The personal OMP plugin's research skill in release 0.11.17 stops acquiring papers when `UNPAYWALL_EMAIL` is unset, because agents must no longer type the contact address into commands. Korolev's manual `setx` setting is not reproducible from this repository, and the Mac has no declaration.

## What Changes

- Declare one shared non-secret Unpaywall contact address, `johann.glock@scch.at`, for both managed hosts.
- Export `UNPAYWALL_EMAIL` from the Mac's managed zsh environment.
- Extend the Windows workstation engine to converge the persistent current-user environment value from shared source data, rather than add a PowerShell profile assignment.
- Verify inheritance in programs started by OMP in fresh Tern sessions on both hosts.
- Remove no existing configuration, application, environment value or runtime state.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `user-configuration`: Require the shared Unpaywall contact in the managed user environment and real OMP child-process inheritance on both hosts.
- `windows-workstation-layer`: Require persistent, idempotent current-user environment convergence with values resolved from shared data, preserving the existing preview and privilege boundaries.

## Impact

Implementation will touch shared chezmoi data, the Mac environment template, Windows engine declarations, schema, validation, environment notification and hashed invocation inputs, and their regression fixtures. Operational guidance will explain how to apply the change and start a fresh environment without repeating the address. No OMP installation, plugin cache, Tern configuration, account enrollment, credential or package change is required.
