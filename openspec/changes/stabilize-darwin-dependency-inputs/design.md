## Context

See `proposal.md` for motivation. The Neo package needs only three macOS layouts and icons, but its flake input clones a 160 MiB repository from an unreliable Gitea endpoint. The official download service publishes each required resource separately. The wrapped OMP package also includes `roslyn-ls`; its Nixpkgs definition combines .NET SDKs 8, 9, and 10, whose source-built Darwin variants pull Swift into the build plan.

## Goals / Non-Goals

**Goals:**

- Keep the installed Neo layouts and Roslyn executable unchanged.
- Make all external artifacts fixed-output Nix dependencies.
- Remove obsolete repository inputs and source-toolchain edges completely.
- Keep failures explicit when upstream bytes or layout identifiers change.

**Non-Goals:**

- Do not add a source mirror, binary cache, update wrapper, or compatibility path.
- Do not change OMP's language-server set.
- Do not activate a workstation generation from CI.

## Decisions

### Fetch the published Neo resources directly

`packages/neo-keyboard-layouts.nix` fetches the six files linked by the official Neo download service and assembles the standard macOS bundle. Each file has an independent SHA-256 hash. The package owns the small static `Info.plist` needed to name the three inputs.

This is preferable to cloning the repository because the build consumes only the published artifact surface. It is preferable to vendoring because upstream bytes remain external, attributable, and independently updateable. The stale GitHub mirror is not acceptable because its Bone and NeoQwertz layouts differ from the current release.

The `neo-layout` flake input and lock node are removed in the same cutover. No alias or fallback remains.

### Override the .NET package scope, not individual Roslyn fields

The Roslyn package receives a `dotnetCorePackages` scope whose SDK 8, 9, and 10 members select the corresponding `*-bin` packages. The implementation uses `overrideScope`, so helper functions such as `combinePackages` resolve the overridden members from the same package scope.

A shallow attribute-set merge was rejected. Nixpkgs scope helpers retained references to the original source-built packages, so the resulting Roslyn derivation still required Swift and source-built .NET 9.

The official binary SDK packages are already defined and hash-pinned by Nixpkgs. This change does not introduce an external installer or mutable global SDK.

### Verify dependency shape before runtime checks

A dry build plan for `personal-omp` must contain Roslyn and must not contain Swift or source-built .NET VMR derivations. Package and flake builds then verify the artifact and runtime contracts. This detects an upstream Nixpkgs scope change before CI spends time compiling the unwanted closure.

## Risks / Trade-offs

- [The Neo download URLs are not versioned] → Fixed hashes prevent silent changes; an upstream replacement requires a reviewed hash update.
- [The direct icons differ from repository copies] → Use the official release icons and verify that macOS accepts the generated bundle metadata.
- [Nixpkgs can change Roslyn's SDK composition] → Inspect the evaluated build plan and keep the scope override limited to the SDK members Roslyn declares.
- [Official Microsoft SDK binaries have a larger downloaded closure] → Prefer bounded cached downloads over repeated local compiler builds in required CI.

## Migration Plan

1. Replace the Neo repository input with fixed-output release resources and validate the built bundle.
2. Commit the Neo cutover as one atomic change.
3. Override Roslyn's .NET package scope and verify the clean build plan.
4. Commit the Roslyn closure change separately.
5. Run formatting, strict OpenSpec validation, flake checks, and the Darwin system build.
6. Push the commits to the existing update pull request and require both platform checks.

Rollback restores the two commits independently. The active workstation remains unchanged until a deliberate post-merge activation.
