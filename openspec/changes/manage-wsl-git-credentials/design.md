## Context

Korolev runs systemd and a user D-Bus session under WSLg. `wslgit` runs Korolev's Git rather than a Windows Git executable. The pinned nixpkgs contains Git Credential Manager and GNOME Keyring. No Secret Service provider is currently active. `Git.Git` is explicitly excluded from the declared Windows application set because another authority manages it.

## Goals / Non-Goals

**Goals:** Keep the Overleaf token encrypted across WSL restarts. Make the same Git configuration work in Fork and a WSL terminal. Preserve the Windows package boundary.

**Non-Goals:** Synchronize credentials between Windows and WSL, prepopulate a token during activation, or remove an existing keyring without operator consent.

## Decisions

- Install the Linux Git Credential Manager through Korolev's Home Manager module. Set its store to `secretservice` and its Git helper there, not in a project-local Git configuration. This keeps the helper in the Nix closure and confines the setting to Korolev.
- Declare Overleaf's generic provider in the Nix-owned Git configuration. GCM otherwise tries to remember its detection by writing to Home Manager's read-only config.
- Enable GNOME Keyring as Korolev's Secret Service provider through the NixOS system module. WSLg supplies graphical prompts to create or unlock the login collection. Its encrypted collection lives in mutable user state, not the Nix store.
- Keep an explicit first-use step for setting a keyring password and supplying the Overleaf token. Use the existing in-memory cache to avoid exposing the token to the assistant or to process arguments. If the cache has expired, Git requests the token interactively.
- Remove the paper submodule's local `credential.helper` override only after the managed helper is active; a local helper masks the global helper.

## Risks / Trade-offs

- WSL has no PAM graphical login that unlocks a collection automatically. A user may need to unlock the keyring after restarting WSL, but does not need to regenerate or re-enter the token. An empty keyring password would forfeit at-rest protection; do not use one.
- Fork's Windows process depends on WSLg forwarding the keyring unlock prompt. First enroll and verify from a WSL terminal; then verify Fork uses the same credential.
- A system switch must follow repository release gates and review. Keep the previous generation until the Git authentication smoke test passes.
