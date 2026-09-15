## Why

Routine `llm-agents` updates can advance Plannotator even when its new features are not needed. An explicit source pin makes application updates deliberate.

## What Changes

- Select Plannotator from a separate instance of the existing `llm-agents.nix` input, with an explicit commit in its declared URL.
- Advance that selection only for an explicit Plannotator update. Keep the central complete-flake updater unchanged.
- Select the unmodified vendor package in both wrapper compositions. Retain vendor patches and dependencies, but remove the local client-lease override.
- Preserve the OMP annotation adapter, explicit cancellation, wrapper ownership, and native acceptance requirements.
- Use existing Nix build and substitution behavior without custom CI output caching.
- Document that a fixed application version does not guarantee an unchanged derivation or prevent required builds.

## Approved Scope Revision

On 2026-09-08, the user approved removal of the downstream client-lease patch and custom CI caching as disproportionate. This revision supersedes the original cache proposal and its cold/warm acceptance requirements. Historical implementation and verification evidence remains in `evidence.md`.

Closing a browser tab can leave a review pending. `/plannotator-cancel` is the supported recovery. The adapter also cancels on session navigation and shutdown. This change adds no automatic tab-close guarantee, approval mode, timeout, or fallback.

## Capabilities

### New Capabilities

- `plannotator-maintenance`: Explicit Plannotator advancement through a commit-pinned vendor input.

### Modified Capabilities

None. The central updater still runs a complete lock update. Existing release checks, network boundaries, and annotation behavior remain required.

## Impact

- `flake.nix`, `flake.lock`, `modules/home/omp.nix`: independent source selection and direct use of the unmodified vendor package.
- Local package override and CI cache additions: removal of the superseded patch and cache mechanisms.
- Existing dependency operations documentation: explicit update commands, stock-package selection, and build caveats.
- No controller repository edits, new secrets, host cache trust changes, or Plannotator upstream submission.
- The separate visual-feedback release retains its native browser, activation, network, and rollback gates. Earlier patched-package checks do not verify the final stock selection.
