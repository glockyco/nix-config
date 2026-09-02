## 1. Record the Acceptance Baseline

- [x] 1.1 Evaluate and record both baseline store paths in this change: the revision-pinned Darwin system and the Home Manager activation package.
- [x] 1.2 Confirm that the worktree is clean and that `flake.lock` stays unchanged for the whole change.

## 2. Create the Platform Boundary

- [ ] 2.1 Create `modules/home/darwin/` and move `apple-terminal.nix`, `apple-terminal.py`, `brave.nix`, and `container-runtime.nix` with `git mv`.
- [ ] 2.2 Move `darwin-switch.nix`, `default-apps.nix`, `fastmail.nix`, and `ghostty.nix` with `git mv`.
- [ ] 2.3 Move `karabiner.nix`, `keyboard-shortcuts.nix`, `network-shares.nix`, and `neo2.nix` with `git mv`.
- [ ] 2.4 Move `screenshots.nix`, `secrets.nix`, and `ssh.nix` with `git mv`.
- [ ] 2.5 Fix every relative path that the moved modules use to reach `packages/`, `modules/`, and their own data files.
- [ ] 2.6 Create `modules/home/darwin/default.nix` that imports the 14 moved modules.
- [ ] 2.7 Reduce `modules/home/default.nix` to the 10 portable modules, `catppuccin.nix`, `zed.nix`, and `home.stateVersion`.
- [ ] 2.8 Import `modules/home/darwin` from the Darwin path only.

## 3. Move Host-Specific Values

- [ ] 3.1 Remove `user.name` and `user.email` from `modules/home/git.nix` and keep all other Git settings.
- [ ] 3.2 Set `user.name` and `user.email` for the Mac in `hosts/macbook-pro/`, using the current GitHub no-reply address.
- [ ] 3.3 Replace the hard-coded `editor` in `modules/home/gh.nix` with a read of `EDITOR`.
- [ ] 3.4 Set `EDITOR` for the Mac in host scope, preserving the current `zed --wait` value.
- [ ] 3.5 Confirm that no portable module names an application, a macOS path, or an identity.

## 4. Extend the Import Check

- [ ] 4.1 Extend the `moduleImports` check in `flake.nix` to nested module directories.
- [ ] 4.2 Add a rejected fixture that proves the check fails for an unimported module inside a nested directory.
- [ ] 4.3 Add an allowed fixture that proves a correctly imported nested module passes.

## 5. Verify the Refactor

- [ ] 5.1 Evaluate both store paths again and confirm that each equals its recorded value from task 1.1.
- [ ] 5.2 Run `nix fmt -- --fail-on-change`.
- [ ] 5.3 Run `nix flake check --print-build-logs` on `x86_64-linux` and inspect the `moduleImports` output.
- [ ] 5.4 On the Mac, run `nix flake check --print-build-logs` and `nix run .#check-darwin-build-plans`, because both realize Darwin-only outputs.
- [ ] 5.5 Build the portable module set as a standalone Home Manager generation for `x86_64-linux` and confirm success.
- [ ] 5.6 Update the `modules/home/` layout description in `README.md`.
- [ ] 5.7 Review the final diff and confirm that it contains only moves, import lists, host values, and the check.
