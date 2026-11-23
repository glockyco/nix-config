# Proposal

## Why

The personal OMP plugin's research skill in release 0.11.17 stops acquiring papers when `UNPAYWALL_EMAIL` is unset, because agents must no longer type the contact address into commands. Korolev's manual `setx` setting is not reproducible from this repository, and the Mac has no declaration.

## What Changes

- Declare one shared non-secret Unpaywall contact address, `johann.glock@scch.at`, for both managed hosts.
- Export `UNPAYWALL_EMAIL` from the Mac's managed zsh environment.
- Declare the persistent current-user variable on Windows as an ordinary registry setting of the workstation engine, with a test that keeps its value equal to the shared address.
- Verify inheritance in programs started by OMP in fresh Tern sessions on both hosts.
- Remove no existing configuration, application, environment value or runtime state.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `user-configuration`: Require the shared Unpaywall contact in the managed user environment and real OMP child-process inheritance on both hosts.
- `windows-workstation-layer`: Require the persistent current-user variable as a declared registry setting whose value a test keeps equal to the shared address.

## Impact

The shared chezmoi data, the Mac environment template with its render check, and the Windows declaration with one declaration test. No engine code, OMP installation, plugin cache, Tern configuration, account or credential changes.
