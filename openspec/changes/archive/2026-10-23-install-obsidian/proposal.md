# Proposal

## Why

Work and personal notes are moving into one Obsidian vault that Obsidian Sync keeps on the Mac, Korolev and a phone, with a Git backup on Korolev. Neither workstation declares Obsidian, so it would be installed by hand, and agents could not rely on its command-line client being on PATH or on Sync running while no window was opened by hand.

## What Changes

- Declare Obsidian on the Mac as a Homebrew cask and on Korolev as the user-scope `Obsidian.Obsidian` WinGet package. Obsidian's own updater keeps both current.
- Start Obsidian when the user signs in: on the Mac through a launchd user agent derived from a new `startAtLogin` field of the application record, and on Korolev through a current-user Run value.
- Put Obsidian's command-line client on PATH as `obsidian`: on the Mac through the command the cask links into Homebrew's `bin`, and on Korolev by adding the installation directory, which holds the `Obsidian.com` terminal redirector, to the user PATH. Neither depends on Obsidian's own command registration.
- Declare gitleaks on Korolev as the user-scope `Gitleaks.Gitleaks` WinGet package, for the commit hook of the vault's Git backup.
- Document the owner steps that stay manual: turning on Obsidian's command-line interface on each machine.
- Mark the original knowledge-management plan superseded, because this setup replaces its desktop-only vault without a sync layer.

## Capabilities

### New Capabilities

- `notes-application`: Obsidian and its supporting tools on both workstations: installation, start at sign-in, the command-line client on PATH, the boundary to Obsidian-owned state, and secret scanning for the vault's Git backup.

### Modified Capabilities

- `repository-quality-gates`: the application record also owns the login start, so changing it changes the cask set, the Dock layout and the login agents together.

## Impact

Targets `home/.chezmoidata/hosts.toml`, `modules/fleet/host.nix`, a new module under `modules/roles/darwin/desktop/`, `flake-modules/checks.nix`, `windows/workstation.json`, `windows/Workstation.Validation.ps1`, a new `docs/operations/obsidian.md`, `docs/operations/korolev-windows.md`, the README and the legacy plans.

Korolev applies as the standard user without elevation. The Mac needs a `darwin-switch` with the owner's password. Obsidian's vaults, account, Sync connection, settings and plugins stay owned by Obsidian. The vault itself, its Git repository and its commit hook live outside this repository.
