# Tasks

## 1. Package

- [x] 1.1 Add `packages/bun-bin/package.nix` from the official `bun-darwin-aarch64.zip` release asset with a fixed hash, and add it to `modules/shared/user-packages.nix`. Verify that `nix build .#bun-bin` produces `bin/bun` that prints the pinned version.
- [x] 1.2 Add a flake check that compares the package's version with the `Oven-sh.Bun` entry in `windows/workstation.json`. Verify that it passes now and fails, naming both versions, when the declaration's version is changed.
- [x] 1.3 Run the README checks for Darwin. Verify that they pass.

## 2. Delivery

- [x] 2.1 Ask for an interactive `darwin-switch` from this branch. Verify in a fresh login shell that `bun --version` prints 1.4.4, that `bun run check:toolchain` passes in omp-agent-setup, and that OMP's commit tool runs the repository's hooks.
- [ ] 2.2 With explicit authorization, open a PR, merge after the required checks pass, and archive the change.
