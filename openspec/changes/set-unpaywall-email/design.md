# Design

## Context

See [proposal.md](proposal.md). `home/dot_zshenv.tmpl` exports the Mac's environment for every zsh kind. The Windows engine converges typed registry settings below `HKCU` from `windows/workstation.json`, and `HKCU:\Environment` is not a prohibited surface. A fresh Tern session on Korolev picked up a user variable from the registry on 2026-11-23.

## Goals / Non-Goals

**Goals:**

- Both hosts provide `UNPAYWALL_EMAIL` to programs that OMP starts.
- The address is checked to be the same on both hosts.

**Non-Goals:**

- A new resource type, a TOML reader in the engine or a general environment mechanism.
- A change to the PowerShell profile, to Tern or to OMP.

## Decisions

1. Keep the address in `home/.chezmoidata/portable.toml` as `portable.research.unpaywallEmail`, and export it in the Darwin branch of `.zshenv`. It is one contact address for both hosts and no secret.
1. On Windows, declare one ordinary registry setting for `HKCU:\Environment` in `windows/workstation.json`. The engine already compares, writes and verifies such settings and reports drift in its dry run.
1. The Windows declaration repeats the address, because the engine reads only its JSON. A declaration test fails when the two values differ. The first design resolved the shared TOML from the engine through chezmoi, with a new resource type, a hashed hook input and fixtures. That is a lot of machinery for one address, and a test gives the same guarantee.
1. The setting sends no environment-change notification. Processes started by Explorer see the value after the next sign-in, and a new Tern session sees it at once. Korolev already holds the value from a manual `setx`, which the engine adopts as matching state.

## Risks / Trade-offs

- A changed address has to be edited in two files. The test names the mismatch.
- A running Tern daemon can hold an older environment. A fresh session after a sign-in settles that.
