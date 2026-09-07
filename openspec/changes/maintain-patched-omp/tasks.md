## 1. Shared patch source

- [ ] 1.1 After explicit publication permission, push the five reviewed commits to the existing personal fork and record the upstream base and patch-tip identities; verify both hosts can fetch that exact range independently.

## 2. Source updater

- [ ] 2.1 Package `omp-dev-update` with declared dependencies and pinned patch inputs; verify stable-release selection, input ancestry, and first-run initialization against temporary Git repositories.
- [ ] 2.2 Prepare detached candidates at permanent generation paths with retained upstream development profiles, frozen dependency installation, and host-native builds; verify failures cannot modify the selected generation or create global Bun links.
- [ ] 2.3 Add candidate package checks, patch regressions, native loading, and plugin-aware launch verification before promotion; demonstrate that each failed preparation phase prevents promotion.
- [ ] 2.4 Implement locking, atomic selection, unchanged-input no-op, and offline rollback; verify concurrent attempts, interruption, first-install rollback rejection, and previous-generation retention with deterministic behavioral tests.

## 3. Workstation integration

- [ ] 3.1 Update `packages/personal-omp.nix` and `modules/home/omp.nix` to expose the updater and launch the selected generation; verify argument and working-directory preservation, plugin injection, missing-generation errors, and rejection of `omp update`.
- [ ] 3.2 Replace obsolete runtime declarations in `modules/fleet/host.nix` and both host configurations; update `flake.nix` routing, shape, and verifier checks and prove both system outputs expose the shared commands without activation-time preparation.
- [ ] 3.3 Update README commands, dependency recovery, WSL bootstrap, and conflicting repository guidance with concise source-update instructions; verify that no active instruction still directs the patched installation through official executable updates.

## 4. Cross-platform acceptance

- [ ] 4.1 Run strict OpenSpec validation and the README's applicable Nix gates for both configured systems; retain exact results with this change and leave unrelated scheduled changes untouched.
- [ ] 4.2 On korolev, prepare a real generation, activate the reviewed wrapper, and exercise launch, successful update, failed-update preservation, and offline rollback; verify native loading, `verify-personal-omp`, the real wrapped-session smoke, and `omp acp` startup.
- [ ] 4.3 On macbook-pro, independently prepare a real generation and repeat activation, launch, update, failure preservation, rollback, native loading, and the wrapped-session smoke; verify operation in Herdr without relying on Korolev or the borrowed Air.
- [ ] 4.4 After both host acceptance gates pass, remove the temporary Korolev launcher and obsolete default routing without deleting developer checkout or installer-owned data; verify fresh shells resolve only the supported wrapper and retain the previous working generations.
