## Why

`omp update` mistakes the Nix wrapper for the writable WSL executable and refuses to update. Routine updates should use that command instead of repeating the installation pipeline.

## What Changes

- Route the WSL wrapper's leading `update` subcommand to the configured standalone executable with an update-only `PATH` adjustment.
- Preserve normal wrapped sessions, immutable plugin loading, and Darwin's Homebrew update procedure.
- Document `omp update` for routine WSL updates; retain the official installer for bootstrap and pinned recovery.
- Verify a real update and the existing release smoke before acceptance.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: distinguish normal wrapped sessions from explicit standalone WSL updates.

## Impact

The implementation affects `packages/personal-omp.nix`, relevant checks in `flake.nix`, and WSL update documentation. It adds no dependency, updater script, scheduler, executable fallback, or OMP source patch. One reviewed wrapper activation is required before the short command works from the default shell.
