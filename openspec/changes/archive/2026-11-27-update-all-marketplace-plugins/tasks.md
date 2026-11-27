# Tasks

## 1. Declaration

- [x] 1.1 Add `home/.chezmoidata/omp.toml` with the four plugins, their marketplaces and GitHub sources, and a Windows-only chezmoi template that renders them to `%LOCALAPPDATA%\WindowsConfiguration\omp-plugins.json`. Verify with the chezmoi render fixtures in `windows/dev/ci.ps1` and `checks/chezmoi-render-check.py`.

## 2. Mac runner

- [x] 2.1 Generate the runner in `modules/roles/darwin/desktop/personal-plugin-updates.nix` from the declaration: sign-in check per source, source check against `omp plugin marketplace list`, refresh and upgrade per plugin with failures isolated, five-minute `timeout`, `GIT_TERMINAL_PROMPT=0` and `GIT_SSH_COMMAND="ssh -o BatchMode=yes"`. Verify with `nix build .#darwinConfigurations.macbook-pro.system`.
- [x] 2.2 Extend the `personal-plugin-updates` check in `flake-modules/checks.nix` with a fake `omp` and `git`: all four plugins in order, one failed refresh that skips only its upgrade and exits nonzero, a timed-out command, a failed sign-in check and an SSH-registered marketplace that logs the fix commands. Verify with `nix flake check --print-build-logs`.

## 3. Windows runner

- [x] 3.1 Rewrite `windows/personal-plugin-upgrade.ps1` to read `omp-plugins.json` and apply the same sequence, with EPERM retries per marketplace and a process wait that kills the tree after five minutes. Raise the task's `ExecutionTimeLimit` to `PT50M` in `windows/Workstation.PluginUpdates.ps1`. Verify with `windows/tests/Workstation.PluginUpdates.Tests.ps1` updated for the same cases as 2.2, run through `pwsh -NoProfile -File .\windows\dev\ci.ps1`.

## 4. Documentation

- [x] 4.1 Update the OMP block and the plugin update paragraphs of `README.md`, `docs/operations/korolev-windows.md` and `docs/operations/dependency-updates.md`: point to `omp.toml` for the kept plugins, install each with its GitHub source, and name `gh auth login -h github.com --web` as the fix the log asks for. Verify that `rg "remain manual" README.md docs` finds nothing.

## 5. Rollout

- [x] 5.1 Fix the Mac by hand in a Tern session: re-register `glockyco-booking` and `glockyco-workbench` with their GitHub sources and upgrade both plugins. Verify that `omp plugin list` shows booking 0.9.0 and workbench 0.19.7 on the Mac.
- [x] 5.2 Run the macOS and Windows checks from the README, `darwin-switch` on the Mac, and the engine's dry run and `chezmoi apply` on Korolev from the branch. Verify that both logs show one successful run over all four plugins and that a fresh Tern session lists every plugin once.

## Workflow follow-up

- Archive the change after the pull request is merged and 5.2 passes.
