## Context

See `proposal.md` for motivation. The central controller runs a complete `nix flake update`. There is no target-local update workflow. Other tools use the rolling `llm-agents` package set.

The initial implementation added an independent Plannotator input, retained the downstream client-lease patch, and added CI output caching. On 2026-09-08, the user approved removal of the patch and custom cache. `evidence.md` preserves the earlier observations as historical evidence, not final stock-package acceptance.

## Goals / Non-Goals

**Goals:** Make Plannotator advancement deliberate. Use the unmodified vendor package on both hosts. Preserve the existing adapter and required release gates.

**Non-Goals:** Custom CI caching, cold/warm performance acceptance, a second scheduler, an updater script, a maintained patch, or a frozen workstation toolchain. Automatic tab-close cancellation, approval mode, new timeouts, and browser fallbacks are also excluded.

## Decisions

### Declare an immutable package-source input

Use `plannotator-packages` as another instance of `github:numtide/llm-agents.nix`, with the reviewed full commit in the declared URL. Retain revision `b1c9a31450a814e50cddc3ab683b05c1dff7bb01`, which supplies Plannotator 0.27.12. Preserve the vendor's locked transitive inputs instead of following workstation `nixpkgs`.

Select only Plannotator from this package set in both wrapper compositions. Use the vendor package directly, without `packages/plannotator.nix` or the local client-lease patch. Vendor packaging patches remain part of the unmodified package. Other tools retain their existing `llm-agents` input.

An explicit Plannotator update changes the declared revision in `flake.nix`, then updates `plannotator-packages` in the lock. A complete automatic lock update cannot advance that declared commit. Its vendor toolchain stays locked too. Unrelated workstation inputs can still advance.

Verify the final stock selection with the actual central updater command in a disposable checkout. Compare both host selections with their vendor packages. Do not infer final selection correctness from earlier patched-output identities.

Do not add an updater exclusion or controller special case. A floating second input would not prevent advancement. A copied package recipe would introduce another maintenance owner.

### Remove the custom cache path

Remove the added cache action, derivation-key logic, explicit cache output root, retention policy, and restore/save steps. Preserve the original native CI checks and Darwin build-plan guard. Existing Nix substitution and ordinary builds remain the only package acquisition paths.

Cold/warm runs, cache sizes, restore failure experiments, and cache publication are no longer acceptance requirements. The historical cache review remains useful evidence of the superseded implementation, not a requirement to retain it.

### Preserve annotation and release boundaries

The adapter still invokes annotation-only JSON mode. Closing a tab can leave its review pending. `/plannotator-cancel` stops the owned review, and session navigation or shutdown also cancels it. No new timeout, approval mode, browser script, or fallback replaces the removed lease patch.

Native browser, explicit cancellation, session isolation, network, activation, and rollback checks remain required by `add-plannotator-visual-feedback`. The maintenance change verifies the on-demand pin and final package selection. It does not claim those separate release gates complete.

Run ordered native repository checks and the Darwin build-plan/system-build gates against the final stock selection. Earlier patched-package results remain historical and do not satisfy these gates.

## Risks / Trade-offs

- An unchanged application version can rebuild after a vendor dependency or package recipe change. A version label is not a derivation identity.
- Existing substitutes are not guaranteed to remain available. Normal source builds must remain possible.
- A closed tab can leave an owned process and snapshot pending until explicit cancellation, navigation, or shutdown.
- An explicit Plannotator update still requires package review and applicable native behavior checks.

## References

- [Central updater contract](https://github.com/glockyco/dependency-automation)
