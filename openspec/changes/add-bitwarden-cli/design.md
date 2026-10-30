# Design

## Context

See proposal.md for motivation. The Mac user CLI inventory is owned by `modules/shared/user-packages.nix`. Korolev uses `windows/workstation.json` and validates stable application roles in `windows/Workstation.Validation.ps1`.

## Goals / Non-Goals

Make the official CLI available in fresh native shells without another package manager. Do not configure vault state or implement secret-use procedures here. The personal OMP plugin owns vault profiles, server selection, authentication, caching, approvals, delivery and scrubbing.

## Decisions

### Use existing package owners

Add nixpkgs `bitwarden-cli` to the ordinary user package inventory, so its version follows the locked package set. Leave the desktop cask unchanged.

Declare `Bitwarden.CLI` as `package bitwarden cli`, with role `vault-cli`, user scope and present policy. Register the role owner and test missing, reassigned and machine-scoped declarations. Reuse the engine's generic installation and command-resolution behavior rather than adding a Bitwarden exception.

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
