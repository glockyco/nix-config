## 1. Updater behavior

- [x] 1.1 Add the Herdr executable path to the updater configuration in `packages/omp-dev-update/package.nix` and to `load_config` validation. Verify that the package builds and that a configuration without `herdr` is rejected.
- [x] 1.2 Implement superseded-session discovery from `herdr agent list` and `herdr pane process-info`, including the invoking-pane, status, custom-argument, and missing-session-file exclusions. Cover each exclusion with unit tests against a fake Herdr.
- [x] 1.3 Implement the restart sequence: editor check from `herdr pane read`, `/exit`, exit wait, `omp --resume <session-file>`, and relaunch confirmation. Unit-test the draft, unrecognized-editor, exit-timeout, and relaunch-unconfirmed outcomes.
- [x] 1.4 Implement retention and `--prune` under the update lock. Test in-use detection, preservation of current and previous, removal of failed candidates, worktree pruning, and an unchanged selection after `--prune`.
- [x] 1.5 Run restarts and then retention after promotion in `update()` and `rollback()` only. Print the report schema from `design.md`. Test that an unchanged update prints metadata only, that a failed update leaves its candidate, and that `--status` is unchanged.

## 2. Guidance and gates

- [x] 2.1 Update `docs/operations/dependency-updates.md`, README's update section, and `.agents/skills/omp-update/SKILL.md`. Describe the automatic restarts, the report fields an agent must relay (`skipped` with reasons, `invoking`, `inUse`), `--prune`, and the removal of the manual restart step. Review the texts against the implementation.
- [x] 2.2 Run `openspec validate restart-sessions-and-prune-omp-generations --strict`, `nix fmt -- --fail-on-change`, and `nix flake check`. Commit.

## 3. Live acceptance

- [ ] 3.1 After merge and activation on Korolev, prepare disposable Herdr OMP sessions on a superseded generation: two idle, one with a draft, one working. Run `omp-dev-update --rollback` from another OMP pane, then run `omp-dev-update --rollback` again. Confirm that the idle sessions resumed their session files on the selected generation, that the draft, working, and invoking panes were reported and untouched, and that retention kept only current, previous, and in-use generations.
- [ ] 3.2 On the Mac, run `omp-dev-update --prune` and confirm the same retention and report. Record the results in `evidence.md` and archive.
