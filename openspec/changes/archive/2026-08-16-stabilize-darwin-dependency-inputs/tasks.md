## 1. Stable Neo Sources

- [x] 1.1 Replace the Neo repository input with hash-pinned official macOS release resources
- [x] 1.2 Preserve bundle metadata and duplicate layout identifier validation
- [x] 1.3 Build and inspect the Neo bundle from a clean Nix source path
- [x] 1.4 Commit the Neo source cutover atomically

## 2. Minimal Managed Language-Server Closure

- [x] 2.1 Override the Marksman and Roslyn .NET package scope with Nixpkgs binary variants
- [x] 2.2 Prove the Darwin build plan excludes Swift and source-built .NET packages
- [x] 2.3 Build the wrapped OMP package and verify both managed language servers remain on PATH
- [x] 2.4 Commit the managed language-server closure change atomically

## 3. Acceptance

- [x] 3.1 Run formatting and strict OpenSpec validation
- [x] 3.2 Run the complete flake check and Darwin system build
- [x] 3.3 Push the update branch and verify required Darwin and Linux checks
- [x] 3.4 Archive the OpenSpec change after repository acceptance passes
