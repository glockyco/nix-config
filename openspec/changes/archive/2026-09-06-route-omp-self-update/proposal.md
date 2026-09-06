## Why

`omp update` mistakes the Nix wrapper for the platform-owned executable and refuses to update. Both supported platforms should expose one command while retaining their existing installer ownership.

## What Changes

- Route the leading `update` subcommand through an update-only `PATH` adjustment on both platforms.
- Select the fixed standalone executable on WSL and the official Homebrew formula on Darwin.
- Preserve normal wrapped sessions and immutable plugin loading.
- Document `omp update` for routine updates; retain platform installer commands for bootstrap and pinned recovery.
- Verify real update ownership and the existing release smoke on both platforms before acceptance.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: distinguish normal wrapped sessions from explicit platform-owned updates.

## Impact

The implementation affects `packages/personal-omp.nix`, relevant checks in `flake.nix`, and platform update documentation. It adds no dependency, updater script, scheduler, executable fallback, or OMP source patch. One reviewed wrapper activation is required before the short command works from the default shell.
