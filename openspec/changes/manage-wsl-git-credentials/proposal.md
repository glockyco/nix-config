## Why

Fork runs NixOS Git through `wslgit`, but the WSL host has no persistent, secure HTTPS credential store. The temporary Git cache expires after one hour; installing Git for Windows outside the declared workstation configuration violated the centrally managed application boundary.

## What Changes

- Provide a Nix-managed Git credential helper and encrypted Secret Service storage on Korolev.
- Keep credential contents in mutable user state, outside the Nix store and repository.
- Document first-time enrollment and unlock behavior for the WSL graphical session.
- Remove the temporary per-repository cache override after the managed helper works.
- Do not install or declare the centrally managed Windows `Git.Git` package.

## Capabilities

### New Capabilities

- `wsl-git-credentials`: Persist HTTPS Git credentials securely across WSL restarts without an unmanaged Windows application.

### Modified Capabilities

None.

## Impact

Korolev gains a user-scoped Git helper and a Secret Service provider. GitLab SSH remains unchanged. Fork's `wslgit` bridge uses the same WSL Git configuration as terminal Git. Activation does not create, unlock, or copy credentials; the operator supplies the Overleaf token to the keyring once.
