## 1. Declare the host capability

- [x] 1.1 Replace GNOME Keyring with a NixOS GPG agent and curses pinentry; verify the evaluated agent configuration.
- [x] 1.2 Switch GCM to the GPG store and declare `gnupg` and `pass`; verify Home Manager settings and preserve GitHub's `gh` helper.
- [x] 1.3 Declare Overleaf's generic provider in the read-only Home Manager Git settings; verify the evaluated URL-specific setting.

## 2. Document enrollment

- [x] 2.1 Document GPG key creation, pass initialization, terminal unlock, and token recovery in the existing WSL operations guide; verify commands against configured paths.

## 3. Validate and activate

- [x] 3.1 Validate the OpenSpec change and run the repository's Nix formatting and flake gates; verify the rendered Windows application set is unchanged.
- [ ] 3.2 Review and commit the change; activate the committed Korolev configuration under the README release procedure, keeping the previous generation.
- [ ] 3.3 Initialize passphrase-protected GPG storage interactively; migrate the cached token through stdin and verify Overleaf access without the temporary cache.
