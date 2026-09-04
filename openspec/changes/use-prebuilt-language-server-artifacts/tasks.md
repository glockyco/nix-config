## 1. Fixed-Output Language Servers

- [ ] 1.1 Add a Marksman package that selects the official `marksman-macos` or `marksman-linux-x64` release artifact by system, installs it as `marksman`, and verify its version command on both supported systems.
- [ ] 1.2 Add a Roslyn package that selects the official `roslyn-language-server.osx-arm64` or `roslyn-language-server.linux-x64` NuGet tool package by system, launches its DLL with the binary .NET 10 runtime as `Microsoft.CodeAnalysis.LanguageServer`, and verify initialization on both supported systems.

## 2. Wrapper and Build-Plan Integration

- [ ] 2.1 Replace the Nixpkgs source-built Marksman and Roslyn selections in `packages/personal-omp.nix` with the fixed-output packages, then build the wrapper shape checks for both systems and confirm both command names resolve.
- [ ] 2.2 Extend `check-darwin-build-plans` to reject source-built Marksman and Roslyn derivations, add live positive controls for both Nixpkgs packages, and verify the controls fail if each application pattern is removed.
- [ ] 2.3 Update the overlapping `align-documentation-with-fleet` delta with the combined release-gate wording and application exclusions, then run strict validation for both active changes.

## 3. Operations and Verification

- [ ] 3.1 Document the official artifact sources, version-and-hash update boundary, and required post-update language smoke in the dependency update procedure, then verify the procedure names both packages and both supported systems.
- [ ] 3.2 Run the focused package, wrapper-shape, and Darwin build-plan checks on their native systems and confirm no build plan reaches a source-built Marksman or Roslyn derivation.
- [ ] 3.3 Run `nix fmt -- --fail-on-change`, `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the applicable native hosts.
- [ ] 3.4 After review and merge, activate the Darwin generation and run the documented C# and Markdown language smoke through the wrapped OMP environment; keep the previous generation until both pass.
