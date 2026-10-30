# Design

## Context

See proposal.md for motivation. The Mac user CLI inventory is owned by `modules/shared/user-packages.nix`. Korolev uses `windows/workstation.json` and validates stable application roles in `windows/Workstation.Validation.ps1`.

## Goals / Non-Goals

Make the official CLI available in fresh native shells without another package manager. Do not configure vault state or implement secret-use procedures here. The personal OMP plugin owns vault profiles, server selection, authentication, caching, approvals, delivery and scrubbing.

## Decisions

### Use existing package owners

Add nixpkgs `bitwarden-cli` to the ordinary user package inventory, so its version follows the locked package set. Leave the desktop cask unchanged.

Declare `Bitwarden.CLI` as `package bitwarden cli`, with role `vault-cli`, user scope and present policy. Register the role owner and test missing, reassigned and machine-scoped declarations. Reuse the engine's generic installation and command-resolution behavior rather than adding a Bitwarden exception.

The WinGet manifest uses a zip with portable `bw.exe`. Declare that executable and installer type so the existing portable-package resolver can repair the package directory's user PATH without assuming WinGet Links exists.

### Verify Mac cache availability before accepting delivery

Evaluate the locked `aarch64-darwin` package on the Mac. Query its full output closure from the configured binary cache independently of the warm local store. Require no source builds, then run the README Nix checks serially without activation. The existing forbidden-toolchain guard alone does not prove Bitwarden cache availability.

### Keep vault use in the plugin

Add a short note to the README Secrets section linking the personal plugin. Do not create directories, configure servers, supply wrappers or manage OMP runtime settings, because those would split vault lifecycle ownership across repositories.

## Risks / Trade-offs

- A cache miss can trigger a large source build. Require explicit closure cache evidence and leave acceptance open if any dependency is unavailable.
- Static checks do not prove live shell resolution. Keep activation, apply and fresh-shell checks as explicit operator gates.

## Acceptance and rollback

Run strict OpenSpec validation, README Windows checks and the Windows engine dry run. Transfer an unpublished snapshot to the Mac when batch SSH works and run Nix checks serially. Never activate, apply chezmoi or run Administrator scripts in this change execution.

After review, activate the Mac and apply Korolev interactively, then verify `bw --version` in fresh native shells. Keep the previous Mac generation. Rollback uses that generation and the previous declarations. Windows package removal remains an explicit operator action. Leave plugin-owned vault state untouched.

## Execution evidence (2026-10-30)

- Strict validation passed for this change, all 20 active items and all 56 archived changes.
- Korolev engine dry run exited 1 with only `drift: package bitwarden cli`. Every other resource was desired. No apply ran.
- The upstream WinGet installer manifest for 2026.10.1 declares a zip containing portable `bw.exe`, consistent with standard-user delivery.
- Batch SSH to the Mac succeeded. SFTP was unavailable, so legacy SCP transferred an unpublished repository snapshot to `~/src/bitwarden-cli-check-20261030`. No branch or tag was pushed.
- The Mac user package evaluation includes `bitwarden-cli-2026.4.2`. Its locked output is `/nix/store/6j1aclr617rq8gizsqlyc805f31nl8yg-bitwarden-cli-2026.4.2`.
- `nix path-info --store https://cache.nixos.org --recursive --json /nix/store/6j1aclr617rq8gizsqlyc805f31nl8yg-bitwarden-cli-2026.4.2` exited 0 and returned the full closure's signed cache records directly from the cache, independently of local store contents. `https://cache.nixos.org/` is a configured substituter.
- All README Mac checks passed on the snapshot: formatting (534 files, zero changes), active and archived OpenSpec validation, flake check, build-plan guard (63 outputs, none reaching a forbidden source build) and the system build. Bitwarden was copied from `cache.nixos.org`. No activation ran. One supplementary package-list evaluation overlapped the main check and reported an ignored busy evaluation-cache database, then succeeded. The README check commands themselves ran serially.
- Operator acceptance remains open intentionally. Run `ssh -t macbook-pro 'cd ~/.config/nix-darwin && darwin-switch'` from a reviewed checkout containing these commits, then `ssh macbook-pro-batch 'chezmoi verify'`. In a fresh Mac shell run `command -v bw` and `bw --version`.
- On Korolev, from the reviewed checkout run `chezmoi apply`, `pwsh -NoProfile -File .\windows\workstation.ps1 -DryRun` and `chezmoi verify --exclude=scripts`. In a fresh PowerShell session run `Get-Command bw` and `bw --version`. No Administrator script is needed for this change.
- README Windows bootstrap, engine dependency setup, format check and CI exited 0 under PowerShell 7.6.6. Pester passed 124 tests with zero failures, skips or inconclusive results. Formatting, bootstrap, hook, chezmoi, archive and real native-tool smoke fixtures passed. A final formatter check after adding portable executable metadata also passed.
