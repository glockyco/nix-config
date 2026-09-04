## 1. Personal Plugin Cutover

- [x] 1.1 In `glockyco/omp-agent-setup`, create and apply a change that disables OMP's built-in `marksman` server and defines `markdown-oxide` for Markdown files, then verify the plugin package contains both declarations and no Marksman fallback.
- [x] 1.2 Run the plugin repository checks and exercise Markdown diagnostics, definition, references, and rename with Markdown Oxide against a fixed representative project, then publish the verified plugin revision.

## 2. Fixed-Output Language Servers

- [ ] 2.1 Add a Markdown Oxide package that selects the official `aarch64-apple-darwin` or `x86_64-unknown-linux-gnu` release artifact by system, installs it as `markdown-oxide`, and verify its version command on both supported systems.
- [ ] 2.2 Add a Roslyn package that selects the official `roslyn-language-server.osx-arm64` or `roslyn-language-server.linux-x64` NuGet tool package by system, launches its DLL with the binary .NET 10 runtime as `Microsoft.CodeAnalysis.LanguageServer`, and verify initialization on both supported systems.
- [ ] 2.3 Advance the personal-plugin pin and replace the Nixpkgs source-built Marksman and Roslyn selections in `packages/personal-omp.nix` with the fixed-output packages, then build the wrapper shape checks for both systems and confirm that Markdown Oxide and Roslyn resolve while Marksman does not.

## 3. Build-Plan and Operations Integration

- [ ] 3.1 Extend `check-darwin-build-plans` to reject source-built Markdown Oxide and Roslyn derivations, add live positive controls for both Nixpkgs packages, and verify the controls fail if each application pattern is removed.
- [ ] 3.2 Update the overlapping `align-documentation-with-fleet` delta with the combined release-gate wording and application exclusions, then run strict validation for both active changes.
- [ ] 3.3 Document the official artifact sources, version-and-hash update boundary, personal-plugin release boundary, and required post-update language smoke in the dependency update procedure, then verify the procedure names both packages and both supported systems.

## 4. Verification

- [ ] 4.1 Run the focused package, wrapper-shape, Markdown smoke, C# smoke, and Darwin build-plan checks on their native systems and confirm no build plan reaches a source-built Markdown Oxide or Roslyn derivation.
- [ ] 4.2 Run `nix fmt -- --fail-on-change`, `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the applicable native hosts.
- [ ] 4.3 After review and merge, activate the Darwin generation and run the documented C# and Markdown language smoke through the wrapped OMP environment; keep the previous generation until both pass.
