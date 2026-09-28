## 1. Updater behavior

- [ ] 1.1 Add the `herdr` executable path to the updater configuration in `packages/omp-dev-update/package.nix` and to `load_config` validation. Verify that the package builds and that a configuration without `herdr` is rejected.
- [ ] 1.2 Implement superseded-session discovery from `herdr agent list` and `herdr pane process-info`. Include only `idle` or `done` agents whose argv names a non-selected generation, and exclude `HERDR_PANE_ID`. Cover each skip reason with unit tests against recorded Herdr JSON.
- [ ] 1.3 Implement the restart: re-check the status, send `/exit` with `herdr agent prompt`, wait for the generation process to leave the pane, then `herdr pane run` the wrapped `omp --resume <session-file>` with the preserved operator arguments. Unit-test argument reconstruction and timeout reporting.
- [ ] 1.4 Verify what OMP does with `/exit` when the editor holds a draft. If the draft would be submitted, skip such panes and test that skip.
- [ ] 1.5 Implement retention and `--prune` under the update lock, removing unused non-current, non-previous generations and pruning worktrees. Test in-use detection, preservation of current and previous, and that `--prune` leaves the selection unchanged.
- [ ] 1.6 Call restarts and then retention after `update()` and `rollback()` promotion only. Test that an unchanged update and a failed update do neither.

## 2. Documentation and gates

- [ ] 2.1 Update `docs/operations/dependency-updates.md` and README's update section. Remove the manual session-restart and cleanup steps, and describe skipped-session reporting and `--prune`.
- [ ] 2.2 Run `openspec validate restart-sessions-and-prune-omp-generations --strict`, `nix fmt -- --fail-on-change`, and `nix flake check`. Commit.

## 3. Live acceptance

- [ ] 3.1 After merge and activation on Korolev, open two idle Herdr OMP sessions and one working session on the previous generation. Run `omp-dev-update --rollback` from a third pane, then `omp-dev-update` again. Confirm that the idle sessions resume the same session files on the selected generation, the working one is listed, and only current, previous, and in-use generations remain.
- [ ] 3.2 Repeat `omp-dev-update --prune` on the Mac and confirm the same retention there. Record the results in `evidence.md` and archive.
