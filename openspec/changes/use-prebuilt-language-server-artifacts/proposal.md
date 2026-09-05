## Why

Darwin CI still compiles the Markdown and C# language servers from source, which makes the routine workstation check take about 14 minutes. Marksman's current official Linux artifact crashes before starting, while Markdown Oxide and Roslyn publish current, working platform artifacts, so a clean server replacement can preserve the language-server matrix without avoidable application builds.

## What Changes

- Replace Marksman with Markdown Oxide as the primary Markdown language server.
- Add a Markdown Oxide override to the independently pinned personal plugin, publish that plugin revision, and advance the workstation pin.
- Package Markdown Oxide from its official platform release executables on supported systems.
- Package Roslyn from its official platform-specific NuGet tool packages while retaining the binary .NET runtime required to launch it.
- Remove Marksman completely; do not retain its executable or server definition as an alias or fallback.
- Extend Darwin build-plan verification to reject source-built Markdown Oxide and Roslyn applications in addition to source-built .NET and Swift toolchains.
- Preserve the Markdown and C# language-server smoke coverage and activation boundary.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `darwin-dependency-builds`: Require official fixed-output language-server artifacts and detect application-level source builds in every Darwin output.

## Impact

- Affects the personal plugin's LSP overrides in `glockyco/omp-agent-setup`, the `personal-omp-plugin` lock in this repository, the Nix packages selected by `packages/personal-omp.nix`, the Darwin build-plan guard, and their focused checks.
- Adds repository-owned fixed-output package definitions for Markdown Oxide and Roslyn.
- Updates Roslyn to an official platform-package version that includes whole-document synchronization support required by the wrapped editing workflow.
- Reconciles the overlapping `align-documentation-with-fleet` delta so its later archive cannot restore the weaker source-build contract.
- Changes the primary Markdown server command from `marksman` to `markdown-oxide`; the OMP executable, wrapper interface, and mutable runtime state remain unchanged.
