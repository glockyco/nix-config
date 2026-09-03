## Why

`repository-quality-gates` states its purpose as one formatting configuration "so that the local gate and the remote gate read one configuration and cannot disagree". Two measurements on `korolev` show that the guarantee does not hold on the second host.

The commit gate is absent there. `lefthook.yml` routes the hook through `nix develop --command treefmt`, and the development shell installs that hook on entry. `devShells` is declared for `aarch64-darwin` alone, so `.envrc` fails, the shell hook never runs, and `.git/hooks/pre-commit` never appears. Thirteen commits on that host passed no formatting gate, and nothing reported a missing environment. The requirement that the hook installs from the development shell carries no platform qualifier, unlike `container-runtime` and `darwin-dependency-builds`, so the host violates accepted behavior.

The remote gate also disagrees with the local one. Revision `f24e147` passed `nix flake check` on the `ubuntu-latest` runner, which installs Determinate Nix 3.22.1, and the same revision failed on `korolev`, which runs the pinned `nix-2.34.8`. The failure was a Darwin-only package in the `x86_64-linux` package set. A green Linux leg is therefore no evidence that the Linux host can run the same gate.

Both findings share one cause. The flake grew from one host to two, and each output re-decides its platform gating at its own definition site with `isDarwin` or `isLinux`. Four asymmetries surfaced one at a time during the `korolev` cutover: the flake-provided cache settings, the Darwin-only package in a shared set, a fixed `gh` transport in a portable module, and the missing development shell. Nothing states which outputs every supported system must provide, and `pkgs` itself is asymmetric: the Darwin outputs reuse the host's package set, while the Linux outputs instantiate a second one that the NixOS host never sees.

## What Changes

- Feed both hosts from the per-system package set through `withSystem` and `nixpkgs.pkgs`, so one nixpkgs instance per system serves the host and the flake outputs.
- Move `overlays.default` and the host platform declaration out of `modules/darwin/system.nix`, which `nixpkgs.pkgs` makes an error to set.
- Declare `devShells.default` for every system in `systems`, with the portable repository tools in the shared list and the host-activation tools behind an explicit platform condition.
- Declare every repository-development output unconditionally, so an asymmetry cannot be expressed rather than being caught by a later assertion.
- Replace the `isDarwin` and `isLinux` booleans with one host binding table that maps each system to its host and its kind, and derive the host proof checks from that table.
- Add a check that asserts the table covers `systems` exactly and names every declared host configuration.
- Run the `x86_64-linux` continuous-integration leg with the Nix that the WSL host declares, so the remote gate and the host gate have the same semantics.
- Record in the runbook that entering the clone installs the commit hook, and that a host without the hook has no local gate.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `repository-quality-gates`: requires a development shell on every supported system so every host can install the commit hook, requires each continuous-integration leg to run the Nix implementation of the host it represents, and requires one package-set instance per system for the host and the flake outputs.

## Impact

The change affects `flake.nix`, `modules/darwin/system.nix`, `.github/workflows/check.yml`, and `docs/operations/wsl-omp-bootstrap.md`.

It changes no host behavior that either machine already has. The Darwin package set, the Darwin outputs, the formatter configuration, and every accepted `korolev` gate stay as they are. It adds no dependency and no input.

This change follows `adopt-nixos-wsl-host`, which created the second host and exposed these asymmetries. Until it lands, `korolev` has no local formatting gate.
