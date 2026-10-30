# Tasks

## 1. Delivery

- [x] 1.1 Add the Mac user CLI package through the existing owner.
- [x] 1.2 Declare the Windows user-scoped CLI with present policy, register its role and cover valid, missing, reassigned and machine-scoped cases.
- [x] 1.3 Add the short plugin ownership note to the existing Secrets documentation without a separate vault procedure.

## 2. Checks

- [x] 2.1 Validate this change and all current and archived OpenSpec artifacts strictly.
- [x] 2.2 Run the README Windows bootstrap, engine dependencies, formatter check and CI checks.
- [x] 2.3 Run the Windows engine dry run and record its CLI drift.
- [x] 2.4 Verify the locked Mac CLI and full dependency closure are available from binary cache independently of the warm local store.
- [x] 2.5 Run all README macOS checks serially on an unpublished snapshot without activation.

## 3. Operator acceptance

- [ ] 3.1 Activate the Mac interactively, retain the previous generation and verify chezmoi state.
- [ ] 3.2 Apply Korolev interactively as the standard account, then verify engine convergence and chezmoi state.
- [ ] 3.3 Verify platform-owned executable paths and `bw --version` in fresh native shells on both hosts after installation.
