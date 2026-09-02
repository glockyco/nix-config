## 1. Share Cross-Platform Settings

- [ ] 1.1 Create `modules/shared/default.nix` and confirm that the `moduleImports` check covers the new directory.
- [ ] 1.2 Move the Zed user settings into `modules/shared/zed-settings.nix` as platform-free data.
- [ ] 1.3 Make `modules/home/zed.nix` consume that expression, and confirm that the Darwin values stay identical.
- [ ] 1.4 Move the Zen enterprise policies into `modules/shared/zen-policies.nix` as platform-free data.
- [ ] 1.5 Make `modules/darwin/zen.nix` consume that expression, and confirm that the Darwin values stay identical.
- [ ] 1.6 Build `.#darwinConfigurations.macbook-pro.system` and confirm that only the intended values changed.

## 2. Render the Windows Document

- [ ] 2.1 Create `modules/windows/default.nix` that renders one WinGet Configuration document.
- [ ] 2.2 Render the document with a structured Nix format writer rather than string concatenation.
- [ ] 2.3 Expose the rendered document and its referenced files as a flake package for `x86_64-linux` and `aarch64-darwin`.
- [ ] 2.4 Record the reviewed set of centrally managed application identifiers as repository data, with its audit date.
- [ ] 2.5 Assert in the module that the document declares no machine-scope package, registry value, or Windows feature.

## 3. Declare the Application Set

- [ ] 3.1 Declare the editor, browser, and Git client with explicit pinned versions.
- [ ] 3.2 Declare the launcher bundle, the mouse window tool, and the Neo2 layout with explicit pinned versions.
- [ ] 3.3 Declare the terminal host and the terminal font with explicit pinned versions.
- [ ] 3.4 Confirm that every declared identifier is absent from the recorded centrally managed set.
- [ ] 3.5 Confirm that each confirmed role has exactly one declared application.

## 4. Declare Windows Settings

- [ ] 4.1 Declare the keyboard repeat delay and repeat rate by named registry values.
- [ ] 4.2 Declare the file-manager settings for file extensions, hidden files, view style, and folder sorting.
- [ ] 4.3 Declare the regional settings for 24-hour time, metric units, and Celsius.
- [ ] 4.4 Declare the window-snapping behavior and the screenshot folder location.
- [ ] 4.5 Declare the launcher bundle's enabled module, and declare every other module of that bundle as disabled.
- [ ] 4.6 Declare taskbar auto-hide with a resource that reads, sets, and tests that single flag.
- [ ] 4.7 Declare the browser enterprise policies from the shared expression.
- [ ] 4.8 Verify the browser policy path on Windows before you rely on it, and record the result.

## 5. Declare Application Configuration Files

- [ ] 5.1 Render the Windows Terminal settings, including the default profile for the NixOS distribution.
- [ ] 5.2 Declare the Windows Terminal settings as a converged file that preserves generated profile identifiers.
- [ ] 5.3 Render the Zed settings from the shared expression, and declare them as a converged file.
- [ ] 5.4 Resolve the Zed agent-server command for `omp acp` so that it reaches `omp` inside WSL, and record the value.
- [ ] 5.5 Render the mouse window tool configuration, and declare it as an enforced file with a checksum.
- [ ] 5.6 Declare the launcher bundle settings as a converged file.

## 6. Add Repository Validation

- [ ] 6.1 Add a pure flake check that validates the rendered document against the WinGet Configuration schema.
- [ ] 6.2 Extend the check to fail when any declared application has no explicit version.
- [ ] 6.3 Extend the check to fail when a declared application appears in the recorded centrally managed set.
- [ ] 6.4 Extend the check to fail when the document declares machine scope.
- [ ] 6.5 Add rejected fixtures for the unpinned, managed-collision, and machine-scope cases.
- [ ] 6.6 Add an allowed fixture that proves a correct document passes.

## 7. Apply and Prove on the Machine

- [ ] 7.1 Preview the document with the dry-run operation and inspect the reported changes.
- [ ] 7.2 Apply the document as the interactive user and confirm that no elevation prompt appears.
- [ ] 7.3 Confirm with the test operation that the applied state matches the document.
- [ ] 7.4 Confirm that every installed application and written file belongs to the interactive user's profile.
- [ ] 7.5 Re-apply the document and confirm that the second run reports no change.

## 8. Verify Each Role by Use

- [ ] 8.1 Open a WSL project in the editor and confirm that language servers run on the Linux side.
- [ ] 8.2 Confirm that the editor needs no SSH server on the WSL host.
- [ ] 8.3 Launch an application from the launcher, then switch to an already-open window with it.
- [ ] 8.4 Move and resize a window with the modifier and the mouse.
- [ ] 8.5 Type Neo2 layers in an ordinary window, then in an elevated window, and record whether the elevated case works.
- [ ] 8.6 Open the terminal host and confirm that the NixOS profile is the default and starts in the Linux home directory.
- [ ] 8.7 Confirm that the declared terminal font renders powerline and device glyphs.
- [ ] 8.8 Browse a repository in the Git client and record the observed responsiveness.

## 9. Record the Manual Surface

- [ ] 9.1 Perform the one-time file-association pass and record exactly which extensions were bound.
- [ ] 9.2 Record that the PDF handler stays with the centrally managed reader.
- [ ] 9.3 Record that the LaTeX previewer decision belongs to `evaluate-pdf-toolset`.
- [ ] 9.4 Record the taskbar pinned-list exclusion and its reason.

## 10. Verify the Complete Change

- [ ] 10.1 Run `nix fmt -- --fail-on-change`.
- [ ] 10.2 Run `nix flake check --print-build-logs` and inspect the new Windows document checks.
- [ ] 10.3 Run `nix build .#darwinConfigurations.macbook-pro.system` and confirm that the Darwin host still builds.
- [ ] 10.4 Run `nix run .#check-darwin-build-plans`.
- [ ] 10.5 Run `openspec validate manage-windows-layer --strict`.
- [ ] 10.6 Extend the operator runbook with the render, preview, apply, and confirm procedure, and state that DSC provides no rollback.
- [ ] 10.7 Update `README.md` for the third layer and its different guarantee set.
- [ ] 10.8 Review the final diff by shared settings, document, validation, and documentation.
