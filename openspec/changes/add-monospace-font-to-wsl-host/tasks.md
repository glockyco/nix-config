## 1. Declare the font

- [x] 1.1 Set `fonts.packages = [ pkgs.jetbrains-mono ]` in the WSL workstation role, with a comment naming the Linux renderers it serves; verify that the evaluated Korolev configuration lists the package.
- [x] 1.2 Assert the package in Korolev's evaluation checks in `flake-modules/checks.nix`, and verify that the check fails when the declaration is removed.

## 2. Validate and activate

- [x] 2.1 Validate the OpenSpec change strictly and run the repository's formatting and flake gates.
- [ ] 2.2 Review and commit; activate the committed Korolev configuration under the README release procedure, keeping the previous generation.
- [ ] 2.3 On the activated host, check that `fc-match "JetBrains Mono"` and `fc-match monospace` resolve to JetBrains Mono, that no system unit failed, and that `vhs` renders a one-line tape in JetBrains Mono.
