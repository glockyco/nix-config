## 1. Resolve Current Ownership

- [x] 1.1 Check whether `separate-platform-baseline-from-roles` changed the WSL user owner before editing; select the one current NixOS/WSL role or module and verify no shared or obsolete owner also installs `open`.
- [x] 1.2 Check whether `derive-windows-check-from-declaration` moved the Windows renderer and check before editing; select their current paths and verify the old and new paths do not coexist.

## 2. Add the WSL Command

- [x] 2.1 Add the Nix `writeShellApplication` command to the current NixOS/WSL user owner with the design's target classification, `wslpath -aw` translation, direct `explorer.exe` execution, and explicit boundary errors; evaluate Korolev and confirm its user package set contains `open` while the macOS package set does not.
- [x] 2.2 Add a behavior check that uses disposable `wslpath` and `explorer.exe` doubles; verify the default target, a path with spaces and shell metacharacters, an absolute URI, excess arguments, an invalid target, and each missing interoperation command through captured arguments, statuses, and errors.
- [x] 2.3 Register the WSL behavior check with the repository gates and run it through its flake check attribute; temporarily break path conversion and confirm the relevant case fails before restoring it.
- [ ] 2.4 Activate the reviewed Korolev generation, start a fresh login shell, and visually confirm that `open`, `open <directory>`, `open <file>`, and `open https://example.com` reach the expected Windows desktop targets without a Linux graphical process.
- [ ] 2.5 Document the common command and WSL failure boundary in the README-owned host guidance, then stage only the WSL unit, inspect its staged diff, and create an atomic commit with a causal body.

## 3. Add the Native Windows Command

- [ ] 3.1 Render exact `OpenTarget.psm1` and `OpenTarget.psd1` files that export `Open-Target` and the `open` alias; parse and import the rendered module with PowerShell and verify an invalid target raises a terminating error before `Start-Process` runs.
- [ ] 3.2 Add one user-scoped Windows configuration resource that resolves the PowerShell 7 user module directory and converges only the `OpenTarget` files; verify its test and set scripts contain no profile path, elevation request, command interpreter, WSL launcher, graphical dispatch, or fallback opener.
- [ ] 3.3 Extend the declaration-derived Windows check at its current owner to verify the resource scope, exact review files, manifest exports, module syntax, profile exclusion, and forbidden fallback dependencies; temporarily violate each boundary and confirm the check reports the module or resource before restoring it.
- [ ] 3.4 Build the complete Windows configuration output and run its repository check; inspect the rendered document and module files and confirm the only new Windows surface is the declared user-scoped module resource and its review files.
- [ ] 3.5 Apply the rendered document from a standard Windows PowerShell session, start a fresh PowerShell 7 process, and confirm `Get-Command open` reports the `OpenTarget` module. Visually verify the default directory, a path with spaces, a file, and an absolute URI, then confirm both profile paths remain absent or byte-identical.
- [ ] 3.6 Add Windows apply, verification, and removal recovery steps to `docs/operations/wsl-omp-bootstrap.md`; stage only the Windows unit, inspect its staged diff, and create an atomic commit with a causal body.

## 4. Verify Integrated Behavior

- [ ] 4.1 On the Mac, start a fresh login shell and confirm `open` resolves to `/usr/bin/open`; visually exercise a disposable directory, file, and URI and confirm no Nix compatibility wrapper shadows it.
- [ ] 4.2 Run `nix fmt -- --fail-on-change` and `nix flake check --all-systems --print-build-logs` from Korolev, then run `nix run .#check-darwin-build-plans` and `nix build .#darwinConfigurations.macbook-pro.system` on the Mac; resolve every change-owned failure.
- [ ] 4.3 Run `openspec validate add-cross-platform-open-command --strict` and confirm every new scenario has implementation or live-smoke evidence.
- [ ] 4.4 Record the exact static-gate results, command provenance, visual observations, activation result, and both rollback paths in the change evidence; verify no `wslu`, WSLg opener, shell alias, PowerShell profile edit, command interpreter, executable fallback, or activation-time Windows write remains.
- [ ] 4.5 Stage only the final documentation, evidence, and completed task-state changes, inspect the staged diff, and create the final atomic commit without pushing.
