## 1. Stable Neo Sources

- [x] 1.1 Replace the Neo repository input with hash-pinned official macOS release resources
- [x] 1.2 Preserve bundle metadata and duplicate layout identifier validation
- [x] 1.3 Build and inspect the Neo bundle from a clean Nix source path
- [ ] 1.4 Commit the Neo source cutover atomically

## 2. Minimal Roslyn Closure

- [ ] 2.1 Override the Roslyn .NET package scope with Nixpkgs binary SDK variants
- [ ] 2.2 Prove the Darwin build plan excludes Swift and source-built .NET SDKs
- [ ] 2.3 Build the wrapped OMP package and verify the Roslyn executable remains on PATH
- [ ] 2.4 Commit the Roslyn closure change atomically

## 3. Acceptance

- [ ] 3.1 Run formatting and strict OpenSpec validation
- [ ] 3.2 Run the complete flake check and Darwin system build
- [ ] 3.3 Push the update branch and verify required Darwin and Linux checks
- [ ] 3.4 Archive the OpenSpec change after repository acceptance passes
