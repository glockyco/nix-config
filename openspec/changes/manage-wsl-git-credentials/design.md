## Context

`wslgit` runs Korolev's Git rather than a Windows Git executable. GNOME Keyring's first-use prompt appeared under WSLg but did not accept mouse or keyboard input. The pinned nixpkgs contains Git Credential Manager, GnuPG, `pass`, and a curses pinentry. `Git.Git` is excluded from the declared Windows application set because another authority manages it.

## Goals / Non-Goals

**Goals:** Keep the Overleaf token encrypted across WSL restarts. Make the same Git configuration work in Fork and a WSL terminal. Preserve the Windows package boundary.

**Non-Goals:** Synchronize credentials between Windows and WSL, prepopulate a token during activation, or remove an existing keyring without operator consent.

## Decisions

- Install Git Credential Manager, GnuPG, and `pass` through Korolev's Home Manager module. Set GCM's store to `gpg`; `pass` keeps encrypted credentials in mutable user state.
- Enable the NixOS GPG agent with curses pinentry. Export `GPG_TTY` in interactive Korolev shells so passphrase requests use the terminal rather than WSLg.
- Declare Overleaf's generic provider in the Nix-owned Git configuration. GCM otherwise tries to remember its detection by writing to Home Manager's read-only config.
- Generate a passphrase-protected GPG key and initialize `pass` interactively. Transfer the existing cached Overleaf token through credential-helper stdin only after `pass` works. No token or private key enters Nix derivations.
- The GPG agent caches the unlocked key for a bounded period. Fork reuses it while unlocked; after expiration or a WSL restart, unlock the key from a WSL terminal before using Fork.
- Keep the paper submodule's local cache override removed; a local helper would mask the managed helper.

## Risks / Trade-offs

- Fork has no usable terminal for curses pinentry. After GPG agent cache expiry or a WSL restart, the user must unlock the key in a WSL terminal before Fork can authenticate. The Overleaf token stays encrypted on disk and need not be re-entered.
- Loss of the GPG private key makes stored credentials unreadable. Keep a secure key backup or re-enroll a fresh Overleaf token after restoring the host; never export the private key to the repository.
- A system switch must follow repository release gates and review. Keep the previous generation until the Git authentication smoke test passes.
