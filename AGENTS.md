# Repository guidance

[README](README.md) owns host commands and release gates. [Dependency operations](docs/operations/dependency-updates.md) covers updates, external authorization, and release recovery. Read declarations for configuration facts, not historical plans.

## Changes

Use OpenSpec for permanent behavior changes. Read all artifacts of the selected change before editing implementation files. Validate with `openspec validate <change> --strict`; archive only after every acceptance gate passes. Accepted contracts live in `openspec/specs/`.

Retained exploratory and legacy plans remain discoverable through [their index](docs/plans/INDEX.md). Preserve each original until a separately reviewed migration verifies its complete replacement.

An unchecked task or CLI `in-progress` status does not authorize deferred work. Respect each change's scheduling notice. Keep verification evidence with its change, not in a current-state manual.

The personal plugin owns the generated OpenSpec adapters. Do not run `openspec init` here; regenerate adapters in `glockyco/omp-agent-setup` and update its pinned input.

## Boundaries

- Preserve the README's separation between immutable Nix paths, platform-owned OMP executables, and mutable OMP state. Only Herdr's supported integration command manages its generated extension. Do not patch OMP, rewrite its configuration, or add executable fallbacks.
- Keep project SDKs, builds, deployment, and domain skills in their owning repositories. Add workstation LSP overrides only after representative project verification proves them necessary.
- Do not install Nix inside CrossOver bottles. Activation may install CrossOver and create an empty bottle, but must not authenticate Steam, update games, install loaders, deploy mods, launch games, or delete bottle data.
- Preserve Korolev's no-inbound boundary and the Mac's tailnet-only SSH listener. The builder private key stays root-owned outside the repository and Nix store; enrollment and credential rotation are explicit operations. Retain local Mac recovery access for networking changes.
- Do not execute Windows resources from Nix activation. Keep Windows application policy and administrator operations within the documented manual boundaries.
- The borrowed Air is temporary, not a durable builder, storage, authentication, or release dependency. [Issue #17](https://github.com/glockyco/nix-config/issues/17) owns result preservation, revocation before return, and complete removal.

Use the README gates before release and inspect activation output after review and merge. OMP or plugin behavior changes also require the real wrapped-session smoke. Keep previous generations until applicable checks pass. Do not add an update wrapper or competing scheduler; updates remain review-only.
