## Why

Routine `llm-agents` updates can advance Plannotator even when its new features are not needed. Fresh CI runners also rebuild our uncached downstream package, repeating work already completed on the hosts.

## What Changes

- Select Plannotator from a separate instance of the existing `llm-agents.nix` input, with an explicit commit in its declared URL.
- Advance that selection only for an explicit Plannotator update. Keep the central complete-flake updater unchanged; it cannot change the declared commit.
- Preserve the existing recipe, checked-in client-lease patch, wrapper ownership, and native acceptance requirements.
- Reuse verified Nix store outputs across Linux and Darwin CI runs through GitHub Actions cache, without another service, account, or scheduler.
- Key the package cache by architecture and evaluated derivation identity. Preserve normal build and verification behavior on misses or eviction.
- Document that version stability does not prevent rebuilds after toolchain changes. The CI cache is not a host binary substituter.

## Capabilities

### New Capabilities

- `plannotator-maintenance`: Explicit version advancement and safe reuse of verified CI package outputs.

### Modified Capabilities

None. The central updater still runs a complete lock update. Existing release checks, network boundaries, and annotation behavior remain required.

## Impact

- `flake.nix`, `flake.lock`, `modules/home/omp.nix`: independent package selection while reusing `packages/plannotator.nix`.
- `.github/workflows/check.yml`: architecture-specific Nix cache restore and successful-build save.
- Existing dependency operations documentation: explicit update commands, cache limitations, and cold/hot verification.
- No controller repository edits, new secrets, host cache trust changes, or Plannotator upstream submission.
- Implement separately from the already-running visual-feedback release. Do not change that release candidate or claim its native acceptance from this proposal.
