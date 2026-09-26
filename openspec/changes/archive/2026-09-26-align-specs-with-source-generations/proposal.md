## Why

Accepted specs still assign OMP updates to installers that the managed hosts do not use. They also mix WSL host and repository gate requirements into the OMP workstation capability. These contracts must match the current source-generation model before dependent changes add deltas.

## What Changes

- State that Nix supplies the OMP wrapper, updater, plugin, and language tools. `omp-dev-update` alone prepares, selects, and rolls back host-local patched source generations.
- Limit the typed host identity requirement to the host name and interactive user name.
- Move WSL host requirements into the new `wsl-host` capability, the WSL container requirement into `container-runtime`, and OpenSpec gate requirements into `repository-quality-gates`.
- Correct the WSL prerequisite and managed-browser update scenarios to use the source-generation updater, not an official installer.
- Sync and archive the spec-only change before the next planned change.

## Capabilities

### New Capabilities

- `wsl-host`: Defines the NixOS/WSL host, its provisioning boundary, local runtime state, interoperability, and acceptance.

### Modified Capabilities

- `dependency-update-automation`: Assigns OMP update and recovery to host-local patched source generations.
- `repository-quality-gates`: Removes obsolete OMP host options and owns the three OpenSpec gate requirements.
- `personal-omp-workstation`: Removes requirements that belong to WSL, container runtime, or repository gates.
- `container-runtime`: Adds the rootless Docker-compatible WSL runtime requirement.

## Impact

This change edits only OpenSpec artifacts. Existing host declarations, wrapper behavior, updater commands, and release procedures remain unchanged. The corrected capability layout becomes the baseline for later deltas.

## Scheduling — 2026-09-26

The owner scheduled this change after plan review. It is change 0 and precedes `key-fleet-by-host`; it has no predecessor.
