## 1. Resolve Current Ownership

- [x] 1.1 Check whether `separate-platform-baseline-from-roles` changed the WSL user owner before editing; select the one current NixOS/WSL role or module and verify no shared or obsolete owner also installs `open`.

## 2. Add the WSL Command

- [x] 2.1 Add the Nix `writeShellApplication` command to the current NixOS/WSL user owner with the design's target classification, `wslpath -aw` translation, direct `explorer.exe` execution, and explicit boundary errors; evaluate Korolev and confirm its user package set contains `open` while the macOS package set does not.
- [x] 2.2 Add a behavior check that uses disposable `wslpath` and `explorer.exe` doubles; verify the default target, a path with spaces and shell metacharacters, an absolute URI, excess arguments, an invalid target, and each missing interoperation command through captured arguments, statuses, and errors.
- [x] 2.3 Register the WSL behavior check with the repository gates and run it through its flake check attribute; temporarily break path conversion and confirm the relevant case fails before restoring it.
- [x] 2.4 Activate the reviewed Korolev generation, start a fresh login shell, and visually confirm that `open`, `open <directory>`, `open <file>`, and `open https://example.com` reach the expected Windows desktop targets without a Linux graphical process.
- [x] 2.5 Keep the README unchanged because the command needs no permanent operator guidance; stage only the WSL unit, inspect its staged diff, and create an atomic commit with a causal body.

## 3. Verify and Finish

- [x] 3.1 Run `nix fmt -- --fail-on-change`, `nix flake check --all-systems --print-build-logs`, and `openspec validate add-cross-platform-open-command --strict`; resolve every change-owned failure.
- [x] 3.2 Remove the out-of-scope native Windows implementation and evidence; rerun the focused Windows and WSL checks and inspect the resulting artifacts.
- [x] 3.3 Record the final Korolev-only acceptance evidence, inspect the staged diff, and create the final atomic commit without pushing.
