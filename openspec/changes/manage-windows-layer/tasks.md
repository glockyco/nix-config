## 1. Share Cross-Platform Settings

- [x] 1.1 Create `modules/shared/default.nix` and confirm that the `moduleImports` check covers the new directory.
- [x] 1.2 Move the Zed user settings into `modules/shared/zed-settings.nix` as platform-free data.
- [x] 1.3 Make `modules/home/darwin/zed.nix` consume that expression, and confirm that the Darwin values stay identical.
- [x] 1.4 Move the Zen enterprise policies into `modules/shared/zen-policies.nix` as platform-free data.
- [x] 1.5 Make `modules/darwin/zen.nix` consume that expression, and confirm that the Darwin values stay identical.
- [ ] 1.6 Build `.#darwinConfigurations.macbook-pro.system` and confirm that only the intended values changed.

## 2. Render the Windows Document

- [x] 2.1 Create `modules/windows/default.nix` that renders one WinGet Configuration document and a narrow Zen policy script from one declaration.
- [x] 2.2 Render the document with a structured Nix format writer and generate the policy script from the same policy expression.
- [x] 2.3 Expose the rendered document, policy script, and review files as a flake package for `x86_64-linux` and `aarch64-darwin`.
- [x] 2.4 Record the reviewed set of centrally managed application identifiers as repository data, with its audit date.
- [x] 2.5 Assert that only the Zen package and policy file require elevation, that the policy script owns only Zen's Program Files path, and that the document declares no machine registry value or Windows feature.

## 3. Declare the Application Set

- [x] 3.1 Declare the editor, browser, and Git client with explicit pinned versions.
- [x] 3.2 Declare PowerToys as both the launcher and mouse window tool, and declare the Neo2 layout with explicit pinned versions.
- [x] 3.3 Declare the terminal host and the terminal font with explicit pinned versions.
- [x] 3.4 Confirm that every declared identifier is absent from the recorded centrally managed set.
- [x] 3.5 Confirm that each confirmed role has exactly one declared application.

## 4. Declare Windows Settings

- [x] 4.1 Declare the keyboard repeat delay and repeat rate by named registry values.
- [x] 4.2 Declare the file-manager settings for file extensions, hidden files, view style, and folder sorting.
- [x] 4.3 Declare the regional settings for 24-hour time, metric units, and Celsius.
- [x] 4.4 Declare the window-snapping behavior and the screenshot folder location.
- [x] 4.5 Enable only Command Palette and Grab And Move in PowerToys, and declare every other discovered module as disabled.
- [x] 4.6 Keep the taskbar visible with a resource that sets and tests only that flag.
- [x] 4.7 Declare the browser enterprise policies from the shared expression.
- [x] 4.8 Verify that the installed browser policy path is `C:\Program Files\Zen Browser\distribution\policies.json`, and record its required elevation.
- [x] 4.9 Declare the built-in Windows dark appearance and Bloom wallpaper without owning custom accent data.

## 5. Declare Application Configuration Files

- [x] 5.1 Render the Windows Terminal settings, including the default profile for the NixOS distribution.
- [x] 5.2 Declare the Windows Terminal settings as a converged file that preserves generated profile identifiers.
- [x] 5.3 Render the Zed settings from the shared expression, and declare them as a converged file.
- [x] 5.4 Resolve the Zed agent-server command for `omp acp` so that it reaches `omp` inside WSL, and record the value.
- [x] 5.5 Keep mouse window control in the converged PowerToys settings instead of a separate application file.
- [x] 5.6 Declare the PowerToys settings as a converged file and restart PowerToys around a locked-file update.
- [x] 5.7 Declare the standalone Neo2 selection as a converged ReNeo setting and start ReNeo at user logon.
- [x] 5.8 Install the pinned Zed theme and merge the Catppuccin Mocha scheme into Windows Terminal.
- [x] 5.9 Support Zed's WSL extension propagation, select `nixd` from the Linux environment, and disable the `nil` fallback.

## 6. Add Repository Validation

- [x] 6.1 Add a pure flake check that validates the rendered document against the WinGet Configuration schema and verifies the narrow Zen policy-script boundary.
- [x] 6.2 Extend the check to fail when any declared application has no explicit version.
- [x] 6.3 Extend the check to fail when a declared application appears in the recorded centrally managed set.
- [x] 6.4 Extend the check to fail when the document declares machine scope.
- [x] 6.5 Add rejected fixtures for the unpinned, managed-collision, and machine-scope cases.
- [x] 6.6 Add an allowed fixture that proves a correct document passes.
- [x] 6.7 Validate the pinned Zed theme and exact Windows Terminal Catppuccin palette.

## 7. Apply and Prove on the Machine

- [x] 7.1 Test the document and Zen policy script before apply, and inspect the reported changes.
- [x] 7.2 Apply the document as the interactive user and the policy script from an Administrator PowerShell session.
- [x] 7.3 Confirm with each test operation that the applied state matches both artifacts.
- [x] 7.4 Confirm the package scopes and record the WindowsApps payload and PowerToys installer-registration exceptions to the user-scope rule.
- [x] 7.5 Reapply the document and policy script and confirm that the second run reports no change.

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
- [ ] 9.5 Record Night Light as enabled from sunset to sunrise at 50% strength and explain the CloudStore exclusion.

## 10. Verify the Complete Change

- [ ] 10.1 Run `nix fmt -- --fail-on-change`.
- [ ] 10.2 Run `nix flake check --print-build-logs` and inspect the new Windows document checks.
- [ ] 10.3 Run `nix build .#darwinConfigurations.macbook-pro.system` and confirm that the Darwin host still builds.
- [ ] 10.4 Run `nix run .#check-darwin-build-plans`.
- [ ] 10.5 Run `openspec validate manage-windows-layer --strict`.
- [ ] 10.6 Extend the operator runbook with the render, preview, apply, and confirm procedure, and state that DSC provides no rollback.
- [ ] 10.7 Update `README.md` for the third layer and its different guarantee set.
- [ ] 10.8 Review the final diff by shared settings, document, validation, and documentation.
