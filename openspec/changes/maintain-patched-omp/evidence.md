# Verification evidence

## Shared patch source — 2026-09-07

Published the user-approved branch `fix/wsl-terminal-hyperlinks` to `https://github.com/glockyco/oh-my-pi` without changing the upstream repository.

- Upstream base: `a1b254047d12e143b7c6011536e918c6c35c5906`.
- Patch tip: `62aa62869813e2834dc5887453f0f6c984953442`.
- Korolev and macbook-pro each fetched the branch into a new, separate temporary bare repository.
- On each host, `git merge-base --is-ancestor <base> <tip>` succeeded and `git rev-list --count <base>..<tip>` returned `5`.
- Upstream's latest-release API reported `v18.1.13`, with `draft=false` and `prerelease=false`.

## Implementation verification — 2026-09-07

- `openspec validate maintain-patched-omp --strict`: passed.
- `nix fmt -- --fail-on-change` and `nix flake check --all-systems --print-build-logs`: passed.
- The updater's 16 behavioral tests and the wrapper shape, generation, and verifier checks passed on both architectures. Darwin checks ran on macbook-pro through the existing builder connection.
- The Darwin system built successfully. The native `check-darwin-build-plans` command checked 37 outputs and found no forbidden source build.
- Korolev completed source preparation and selected `generations/v18.1.13-tnmqfjfj`, with result commit equal to the pinned patch tip. All three package checks, 361 regressions across ten files, native loading, and immutable plugin registration passed. The packaged wrapper reported `18.1.13` from `/tmp`.
- An initial native-load probe omitted the raw binding's required tab-width argument. Preparation failed without selecting that candidate. The corrected probe and a complete subsequent preparation passed. A concurrent rollback attempt was rejected while preparation held the lock.

## Deployment prerequisites

The Mac is reachable through its existing tailnet SSH endpoint and reports `Darwin arm64`. Its installed Nix is Determinate Nix 3.21.9 / Nix 2.34.8. Remote `sudo -n true` requires a password; system activation needs an operator-authorized local administrator step. No privilege or authentication configuration was changed.
