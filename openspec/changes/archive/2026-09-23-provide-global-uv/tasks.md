## 1. Shared Package

- [x] 1.1 Add `pkgs.uv` to the shared Home Manager package set and verify the evaluated package lists for Korolev and the Mac contain the Nixpkgs `uv` package.

## 2. Validation

- [x] 2.1 Validate `provide-global-uv` with strict OpenSpec validation and verify `nix fmt -- --fail-on-change` reports no formatting changes.
- [x] 2.2 Run `nix flake check --print-build-logs` and verify all checks for the current host pass.
