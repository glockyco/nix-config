## Why

Darwin CI still compiles Marksman and Roslyn from source even though their toolchains are binary, which makes the routine workstation check take about 14 minutes. Both projects publish official platform artifacts, so the workstation can preserve the language-server matrix while replacing avoidable application builds with fixed-output downloads.

## What Changes

- Package Marksman from its official platform release executables on supported systems.
- Package Roslyn from its official platform-specific NuGet tool packages while retaining the binary .NET runtime required to launch it.
- Keep `marksman` and `Microsoft.CodeAnalysis.LanguageServer` available under their current command names.
- Extend Darwin build-plan verification to reject source-built Marksman and Roslyn applications in addition to source-built .NET and Swift toolchains.
- Preserve the existing language-server smoke coverage and activation boundary.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `darwin-dependency-builds`: Require official fixed-output language-server artifacts and detect application-level source builds in every Darwin output.

## Impact

- Affects the Nix packages selected by `packages/personal-omp.nix`, the Darwin build-plan guard, and their focused checks.
- Adds repository-owned fixed-output package definitions for Marksman and Roslyn.
- Updates Roslyn to the nearest published platform-package version because the exact current source-built revision has no official NuGet tool package.
- Reconciles the overlapping `align-documentation-with-fleet` delta so its later archive cannot restore the weaker source-build contract.
- Does not change the OMP executable, plugin, wrapper interface, mutable runtime state, or language-server command names.
