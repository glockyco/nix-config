## Approved scope and historical work

On 2026-09-08, the user approved the unmodified vendor package and explicit cancellation instead of the downstream client-lease patch. The user also cancelled custom CI caching and its cold/warm acceptance requirements. The on-demand source pin remains required.

Historical completed tasks 1.2 and 1.3 verified the independent input through the patched package. Historical tasks 2.1 and 2.3 verified cache configuration. Historical task 3.4 verified the earlier update procedure and documentation. Their results remain in `evidence.md`; they do not verify the final stock selection or require the removed cache. The former cache tasks 2.2, 3.2, and 3.3 are cancelled, not passed.

## 1. Explicit stock-package selection

- [x] 1.1 Add the commit-qualified `plannotator-packages` input at the verified vendor revision. Verify its source identity and initial Plannotator version against existing evidence.
- [x] 1.2 Select the unmodified vendor package directly in both wrapper compositions. Verify each host matches its vendor package, with no local override and no unrelated tool changes.
- [x] 1.3 Run `nix flake update` in a disposable checkout of the final stock selection. Verify Plannotator's declared revision, locked vendor graph, version, and package identity remain unchanged while eligible unrelated inputs can advance. Remove the disposable checkout.

## 2. Remove superseded mechanisms

- [x] 2.1 Remove the local client-lease patch and package override. Remove custom CI cache actions, keys, output roots, and retention logic. Preserve the original native checks and Darwin guard.

## 3. Verification and documentation

- [ ] 3.1 Run ordered repository checks on both native systems against the final stock selection. Run the Darwin build-plan and system-build gates. Verify the existing wrapper and annotation contracts remain intact.
- [x] 3.2 Update the existing dependency runbook for explicit revision-and-lock updates and stock-package selection. Remove patch maintenance and custom cache instructions. Document build caveats and explicit cancellation after tab closure. Verify the update commands in a disposable checkout, then remove it.
- [ ] 3.3 Record final stock-package evidence and run strict validation of this change. Archive only after all active tasks pass. Preserve the separate visual-feedback change's unverified native acceptance gates.
