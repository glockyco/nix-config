## 1. Explicit package selection

- [x] 1.1 Add the commit-qualified `plannotator-packages` input at the currently verified vendor revision; verify its source identity and initial Plannotator version match existing delivery evidence.
- [x] 1.2 Migrate both wrapper compositions to that input through the existing downstream override; evaluate both hosts and verify source, patch, and executable identities without changing other tool selections.
- [x] 1.3 Run the central complete-lock-update command in a disposable checkout; prove that Plannotator's source revision and version remain fixed while eligible unrelated inputs can advance. Remove the disposable checkout afterward.

## 2. Native CI cache

- [x] 2.1 Pin a reviewed compatible `cache-nix-action` revision and add native-system plus evaluated-derivation cache keys; verify unrelated changes preserve the key while a changed package input invalidates it.
- [ ] 2.2 Add restore, the existing Darwin guard, a job-local package output root, unchanged native checks, and successful-run save in that order; verify cache misses still execute the original build path and failed checks do not save verified results.
- [x] 2.3 Configure bounded CI-only retention and preserve GitHub ref isolation; inspect effective permissions and saved paths to verify no credentials, external cache service, host trust change, or competing scheduler is introduced.

## 3. Verification and documentation

- [ ] 3.1 Run ordered repository checks on both native systems and the Darwin build-plan and system-build gates; verify the new package selection preserves the existing wrapper and annotation contracts.
- [ ] 3.2 Exercise cold and warm GitHub CI runs on both architectures; record derivation identity, cache scope, restore result, cache size, timings, and proof that warm runs avoid the Plannotator source build while all checks still execute.
- [ ] 3.3 Verify an unavailable cache leaves the uncached build path available and a changed derivation cannot reuse an older output as the selected package; record actual results without suppressing build failures.
- [x] 3.4 Update the existing dependency runbook with explicit revision-and-lock update commands, patch review, cache scope, eviction, and toolchain rebuild caveats; verify the documented commands against a disposable checkout and remove owned temporary data.
- [ ] 3.5 Record verification evidence, validate this change strictly, and archive only after every task passes; preserve the separate visual-feedback change's outstanding native acceptance gates.
