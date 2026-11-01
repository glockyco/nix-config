# Proposal

## Why

Only Korolev had a Git clone of the notes vault, so sessions on the Mac could not commit what they changed, and their edits waited until a session on Korolev happened to include them. The Mac now gets its own clone in `~/notes`, and its commits need the vault's pre-commit secret scan, which runs `gitleaks` through `lefthook`.

## What Changes

- Install `gitleaks` and `lefthook` as Mac user packages.
- Describe both vault clones and how to turn a synced folder into a clone in `docs/operations/obsidian.md`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `notes-application`: the Mac installs the vault's commit tools.

## Impact

The next `darwin-switch` puts both on PATH. Nothing else in the Mac's configuration changes.
