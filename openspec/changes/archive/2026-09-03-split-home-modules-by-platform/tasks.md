## 1. Record the Acceptance Baseline

- [x] 1.1 Record the baseline in this change: the parent system store path and the four evaluated invariants.
- [x] 1.2 Confirm that the worktree is clean and that `flake.lock` stays unchanged for the whole change.

## 2. Create the Platform Boundary

- [x] 2.1 Create `modules/home/darwin/` and move `apple-terminal.nix`, `apple-terminal.py`, `brave.nix`, and `container-runtime.nix` with `git mv`.
- [x] 2.2 Move `darwin-switch.nix`, `default-apps.nix`, `fastmail.nix`, `fastmail.py`, and `ghostty.nix` with `git mv`.
- [x] 2.3 Move `karabiner.nix`, `keyboard-shortcuts.nix`, `network-shares.nix`, and `neo2.nix` with `git mv`.
- [x] 2.4 Move `screenshots.nix`, `secrets.nix`, and `ssh.nix` with `git mv`.
- [x] 2.5 Fix every relative path that the moved modules use to reach `packages/`, `modules/`, and their own data files.
- [x] 2.6 Create `modules/home/darwin/default.nix` that imports the 14 moved modules.
- [x] 2.7 Reduce `modules/home/default.nix` to the 10 portable modules, `catppuccin.nix`, `zed.nix`, and `home.stateVersion`.
- [x] 2.8 Import `modules/home/darwin` from the Darwin path only.

## 3. Move Host-Specific Values

- [x] 3.1 Remove `user.name` and `user.email` from `modules/home/git.nix` and keep all other Git settings.
- [x] 3.2 Set `user.name` and `user.email` for the Mac in `hosts/macbook-pro/`, using the current GitHub no-reply address.
- [x] 3.3 Replace the hard-coded `editor` in `modules/home/gh.nix` with a read of `EDITOR`.
- [x] 3.4 Set `EDITOR` for the Mac in host scope, preserving the current `zed --wait` value.
- [x] 3.5 Confirm that no portable module names an application, a macOS path, or an identity.

## 4. Extend the Import Check

- [x] 4.1 Extend the `moduleImports` check to nested module directories, moving its logic into a package that takes the module root so fixtures can exercise it.
- [x] 4.2 Add a rejected fixture that proves the check fails for an unimported module inside a nested directory.
- [x] 4.3 Add an allowed fixture that proves a correctly imported nested module passes.

## 5. Verify the Refactor

- [x] 5.1 Confirm the four evaluated invariants against the parent commit, and record the post-refactor system store path.
- [x] 5.2 Run `nix fmt -- --fail-on-change`.
- [x] 5.3 Run `nix flake check --print-build-logs` on `x86_64-linux` and inspect the `moduleImports` output.
- [x] 5.4 On the Mac, run `nvd diff` between the parent system and this change's system, and confirm no added package, no removed package, and no version change.
- [x] 5.5 On the Mac, run `nix flake check --print-build-logs` and `nix run .#check-darwin-build-plans`, because both realize Darwin-only outputs.
- [x] 5.6 Build the portable module set as a standalone Home Manager generation for `x86_64-linux` and confirm success.
- [x] 5.7 Update the `modules/home/` layout description in `README.md`.
- [x] 5.8 Review the final diff and confirm that it contains only moves, import lists, host values, and the check.
