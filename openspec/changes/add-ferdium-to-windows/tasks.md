## 1. Declare the Native Windows Application

- [x] 1.1 Add the user-scoped, self-updating `Ferdium.Ferdium` entry with role `communication-client` to `modules/windows/applications.nix`; add that role to the renderer's required role set, build the Windows artifact, and confirm that its package resource has `useLatest: true`, no exact version, and no elevation metadata.
- [x] 1.2 Extend `packages/windows-configuration-check.py` so `communication-client` requires `Ferdium.Ferdium`, user scope, and the self-updating policy; add rejection coverage for a wrong identifier, exact version, elevation, duplicate role, and centrally managed collision, then run the focused packaged Windows configuration check.
- [x] 1.3 Update `docs/operations/wsl-omp-bootstrap.md` to list Ferdium with the self-updating applications and to state its application-owned settings boundary; compare the procedure with the rendered document and application declaration.

## 2. Validate and Commit the Reviewed Change

- [x] 2.1 Run `openspec validate add-ferdium-to-windows --strict`, `nix fmt -- --fail-on-change`, and `nix flake check --print-build-logs`; resolve every failure and inspect the built review files for the declared Ferdium package and absence of Ferdium settings or startup resources.
- [x] 2.2 Review and commit only the Ferdium implementation, specification, procedure, and focused verification changes as one atomic change with a causal commit body.

## 3. Apply and Prove Native Windows Behavior

- [ ] 3.1 Build a fresh reviewed Windows artifact. Before apply, record whether Ferdium, its user profile, and a Ferdium startup entry exist; record the WinGet catalog version and run `winget configure test` plus both Administrator-script tests in their required account contexts.
- [ ] 3.2 Apply the complete document as the standard Windows user. Confirm that Ferdium requests no elevation, installs under the interactive user's profile, reports an installed version equal to or newer than the WinGet catalog version, and that all three post-apply tests report desired.
- [ ] 3.3 Launch Ferdium as a native Windows application without authenticating or adding a service. Verify in the actual application UI that a fresh profile enables automatic updates and disables launch at sign-in; confirm that the running executable is the installed Windows package, not a WSLg process.
- [ ] 3.4 Close Ferdium, preserve a checksum of its generated settings, reapply and retest the Windows document, and confirm that the settings remain byte-identical and Ferdium does not launch. Sign out and in, then confirm that a fresh profile does not start Ferdium automatically.
- [ ] 3.5 Record the initial state, catalog and installed versions, installer scope, executable path, update and startup UI observations, settings checksum, test results, applied revision, and sign-in result in `evidence.md`.
- [ ] 3.6 Sync the completed delta to `openspec/specs/windows-workstation-layer/spec.md` and archive the change only after every implementation and live acceptance task passes.
