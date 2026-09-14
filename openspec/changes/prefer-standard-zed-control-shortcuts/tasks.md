## 1. Declare the Zed keymap

- [x] 1.1 Add the Windows-first control bindings and removed Vim-only controls to `modules/windows/files.nix`; render `zed-keymap.json` and inspect it as valid JSON with the intended `Editor && mode == full` contexts.
- [x] 1.2 Add a complete-file Zed keymap resource for `%APPDATA%\Zed\keymap.json`; render the WinGet document and confirm that the resource depends on the Zed package and replaces drift instead of merging it.

## 2. Extend repository verification

- [x] 2.1 Add `zed-keymap.json` to the Windows review-file contract and assert the exact key, action, context, and ownership policy in `packages/windows-configuration-check.py`; run the focused Windows configuration check.
- [x] 2.2 Update the Windows integration procedure with the managed-keymap boundary and the live shortcut checks; review the rendered procedure for account, WSL, and terminal-context accuracy.

## 3. Validate and review

- [x] 3.1 Run `openspec validate prefer-standard-zed-control-shortcuts --strict`, `nix fmt -- --fail-on-change`, and the platform-applicable flake check; resolve every failure.
- [ ] 3.2 Inspect and commit only the change-owned implementation, specification, procedure, and verification files as one atomic configuration change with a causal commit body.

## 4. Apply and prove Windows behavior

- [ ] 4.1 After review, test and apply the rendered Windows configuration as the standard Windows user; require the first test to report keymap drift and the post-apply test to report the desired state.
- [ ] 4.2 In Windows Zed, verify `Ctrl+C`, `Ctrl+V`, `Ctrl+A`, `Ctrl+Z`, `Ctrl+F`, `Ctrl+W`, and a `Ctrl+K` chord in a full editor across normal, visual, and insert modes; verify an unmodified Vim edit and `Escape` still work.
- [ ] 4.3 In Zed's integrated terminal, verify that `Ctrl+C` still reaches the terminal process; record the commands, observed results, Zed version, and applied artifact revision in `evidence.md`.
