## Scheduling — 2026-09-26

The owner scheduled this change after plan review. It runs at position 3, after `derive-windows-check-from-declaration` and the preceding Mac gates.

## Why

The Darwin platform list imports desktop applications, power settings, and PostgreSQL; the NixOS list imports WSL and containers (`modules/darwin/default.nix:2-15`, `modules/nixos/default.nix:5-13`). A second host would inherit machine roles it did not select. Host-specific names, screenshot paths, Git identities, Dock applications, Colima resources, and Nix settings remain split among host and platform modules (`modules/darwin/system.nix:24-42`, `modules/darwin/defaults.nix:76-104,121-126`, `hosts/korolev/default.nix:34-61`, `modules/home/darwin/container-runtime.nix:10-24`).

The borrowed Air has SSH aliases, a batch command and check, an SMB mount agent, and a `~/Air` link in several files (`modules/home/darwin/ssh.nix:12-16,38-39,76-92`, `packages/air-batch-config-check.nix:21-28`, `modules/home/darwin/network-shares.nix:9-45`). Issue #17 removes the integration after the research results are preserved. Isolate the existing behavior for deletion; do not improve its endpoint, mount, or Docker-path contracts.

## What Changes

- Keep `modules/darwin/` and `modules/nixos/` as platform baselines. Select desktop, PostgreSQL, container-client, Air-client, and WSL-workstation roles from the host modules.
- Extend `modules/fleet/host.nix` with typed identity, locale, Git, path, application, and container-profile options. Put facts in `hosts/<name>/host.nix`. Roles read `config.host`; cross-host consumers use `config.fleet.hosts`.
- Generate the Darwin cask list and Dock application entries from one typed inventory. Keep platform policy and role-specific choices outside host facts.
- Keep Air artifacts in `modules/roles/darwin/air-client/`, `packages/air-batch-check/`, the Air-only `checks/air-batch-config-check.nix`, their flake wiring, and the `macbook-air` peer entry. Split the current combined SSH check so `checks/desktop-batch-config-check.nix` survives Air removal. Issue #17 removes only the Air units.
- Keep the Air's current SSH destinations, `AIR_BATCH_DOCKER` contract, Finder-selected SMB path, and `~/Air` link. Do not add `host.remote.air`, a stable mount point, or a Docker-path derivation.
- Put PostgreSQL in its Darwin role without changing `/var/lib/postgresql/17` or the idempotent directory-creation activation (`modules/darwin/postgresql.nix:4-11,38-39`).
- Apply the shared Nix registry, channel, garbage-collection, and store-optimisation policy through platform adapters. Evaluate both hosts and explain Korolev derivation differences with `nix-diff`.
- Move the macOS-only Zen policy and nix-homebrew path adjustment out of shared modules. Preserve the byte baseline recorded by the preceding Windows change.
- Derive Colima architecture from the host platform and its capacity from typed host data. Unify the two Cloudflare direnv helpers and use `xdg.configFile`.
- Keep the Mac SOPS recipient and current `encrypted_regex`. Add a repository check for plaintext YAML data scalars. Offline recovery, a second recipient, and removal of `encrypted_regex` belong to a later change.
- Update the README and operations documentation affected by these role, Nix-policy, Air, and SOPS changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `repository-quality-gates`: separates baselines from roles, gives each machine fact one source, and rejects plaintext secret data.
- `wsl-host`: extends declared host defaults with typed identity, locale, paths, and explicit roles after change 0 moves this requirement.
- `container-runtime`: derives the reviewed Apple Silicon Colima profile from typed host capacity and the platform.

## Impact

The change affects host declarations, platform and Home Manager modules, role modules, SOPS checks, packages and checks in the position-1 layout, and the relevant README and operations pages. `key-fleet-by-host` supplies `hosts/<name>/host.nix`, `config.fleet.hosts`, `packages/<name>/`, `checks/`, and `flake-modules/` before this change starts.

The pinned-revision system derivation gate covers behavior-preserving moves. Intentional differences are NixOS maintenance settings and the removal of a Darwin-only shell fragment from Korolev. `nix-diff` explains the Korolev derivation changes. Record the completed position-2 Windows output before editing; the Zen cutover must preserve those bytes. Air and PostgreSQL behavior remain unchanged. Mac gates and both CI platform jobs verify the repository changes.
