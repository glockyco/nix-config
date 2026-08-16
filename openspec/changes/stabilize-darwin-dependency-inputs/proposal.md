## Why

Routine Darwin checks currently depend on an unreliable Git clone and can compile Swift plus three .NET SDKs only to provide the Roslyn language server. These incidental dependencies make review-only updates slow or non-deterministic without changing workstation behavior.

## What Changes

- Build the Neo keyboard bundle from the official macOS release resources with fixed hashes instead of cloning the full upstream repository.
- Remove the obsolete Neo flake input and its lock entry.
- Build Roslyn with Nixpkgs' fixed-output binary .NET SDK packages instead of source-built SDK packages on Darwin.
- Preserve the selected language servers, keyboard layouts, duplicate-layout validation, and normal Darwin and Linux checks.

## Capabilities

### New Capabilities

- `darwin-dependency-builds`: Defines stable, minimal source contracts for Darwin keyboard layouts and managed language-server toolchains.

### Modified Capabilities

- `dependency-update-automation`: Requires routine update checks to use dependency sources that are reproducible and suitable for unattended cross-system CI.

## Impact

Affected code includes `flake.nix`, `flake.lock`, `packages/neo-keyboard-layouts.nix`, and `packages/personal-omp.nix`. The change removes one flake input, replaces its Git source with fixed-output release resources, and changes Roslyn's .NET SDK composition without changing the wrapped OMP interface.
