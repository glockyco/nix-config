## Why

The workstation runtime is reproducible, but its weekly update pull request does not start required CI automatically and the repository has no merge protection. Update ownership and operating instructions are also split across workflows, remote settings, and architecture notes.

## What Changes

- Use a least-privilege GitHub App installation token for scheduled flake update pull requests.
- Keep the official Determinate flake updater as the sole owner of `flake.lock` updates.
- Add Renovate for GitHub Actions and explicitly disable its beta Nix manager.
- Require the real Darwin and Linux CI jobs before any main-branch merge, including administrator merges.
- Verify that the packaged OpenSpec executable matches its Nix package version, generated adapters are current, and archived tasks are complete.
- Add concise repository guidance and one dependency-update operations runbook.
- Classify and track the existing `docs/plans/` files so the worktree has no ambiguous permanent state.
- Preserve manual workstation activation, activation verification, the real OMP release smoke, and Nix-generation rollback.

## Capabilities

### New Capabilities

- `dependency-update-automation`: Defines dependency ownership, weekly update pull requests, required CI, manual activation, rollback, and repository-policy enforcement.

### Modified Capabilities

- `personal-omp-workstation`: Adds OpenSpec package consistency and generated-adapter freshness to the immutable workstation checks without changing OMP-owned mutable state.

## Impact

- Affected files: `.github/workflows/`, `renovate.json`, flake checks, repository guidance, operations documentation, OpenSpec adapters, and planning documents.
- External state: one least-privilege GitHub App installation, Actions credentials, and main-branch protection.
- Update pull requests remain review-only. No workflow merges, activates, or changes mutable OMP state automatically.
