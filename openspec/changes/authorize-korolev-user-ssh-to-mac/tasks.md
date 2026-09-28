## 1. Declare the access

- [x] 1.1 In `modules/roles/darwin/desktop/tailscale.nix`, render the authorization file from a labeled builder line (`restrict`) and a Korolev user line without `restrict`. Build the Darwin system and inspect the rendered file.
- [x] 1.2 In `modules/roles/nixos/wsl-workstation/programs.nix`, scope the builder settings to `Match originalhost macbook-pro localuser root`. Add `Match originalhost macbook-pro,macbook-pro-batch !localuser root` for the user key with strict host checking, and a non-root batch block matching the desktop batch transport. Verify with `ssh -G macbook-pro` as `user` and as root.
- [x] 1.3 Add a Korolev SSH configuration check that asserts the user, the single identity, strict host checking, and the transport for both user endpoints and for the root builder branch. Register it in `flake-modules/checks.nix`, build it, and confirm that it fails when root is not excluded from the user block.
- [x] 1.4 Document the Mac endpoints in README's network section. Review the text against the declaration.

## 2. Validate and activate

- [x] 2.1 Run `openspec validate authorize-korolev-user-ssh-to-mac --strict`, `nix fmt -- --fail-on-change`, and `nix flake check`. Commit the change atomically.
- [ ] 2.2 After merge, activate Korolev and the Mac. As `user`, confirm that `ssh macbook-pro` receives a terminal, that `ssh macbook-pro-batch 'exit 23'` returns 23, and that port forwarding is refused. Confirm that the Darwin remote builder check still passes.
- [ ] 2.3 Record the commands and observed results in `evidence.md`, then archive the change.
