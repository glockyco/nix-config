## Why

The WSL work machine `korolev` is the only machine in this repository that has no host directory. It entered as a package and an imperative installer: `packages/personal-omp-wsl.nix` selects four executables, and `packages/bootstrap-omp-on-wsl.nix` plus its tests spend 535 lines to reimplement ordered activation, generation replacement, and rollback. `modules/home/omp.nix` expresses the same activation for the Mac in 7 lines.

Because `korolev` has no user scope, it has no shell, Git, SSH, or command-line configuration, and no place to put any. The environment cannot grow past four executables.

The installation also depends on two manual layers that a standard Windows user should not need: `apt-get` prerequisites and a separate Nix installer. The recorded acceptance evidence contains a repeated warning that Nix ignores a client-specified `trusted-public-keys` setting, because a non-trusted user advertises the Numtide cache through the root flake.

Verification spikes proved the replacement. A NixOS-WSL system built against the pinned `0.2605` nixpkgs in 77 seconds, imported without administrator rights, and started with systemd as process 1.

## What Changes

- Add `nixos-wsl` as a flake input whose nixpkgs follows the pinned nixpkgs.
- Add `hosts/korolev/` and expose `nixosConfigurations.korolev`.
- Add `modules/nixos/` for WSL system scope, and consume the portable user modules through the Home Manager NixOS module.
- Declare the Numtide substituter and its trusted key in system Nix configuration.
- Declare the work Git identity globally, and select the GitHub no-reply address for personal repository trees.
- Enable `nix-ld` for prebuilt executables that project work requires.
- Provide a rootless container runtime on the WSL host with Docker command compatibility.
- Replace `nix run .#bootstrap-omp-on-wsl` with a tarball import and `nixos-rebuild switch`.
- Delete `packages/personal-omp-wsl.nix`, `packages/bootstrap-omp-on-wsl.nix`, `packages/bootstrap-omp-on-wsl-tests.nix`, and their two checks.
- Rewrite `docs/operations/wsl-omp-bootstrap.md`.
- **BREAKING**: the named `personal-omp-wsl` profile entry and its bootstrap application no longer exist. The operator imports a distribution and activates NixOS generations.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-omp-workstation`: replaces the user-profile bootstrap with a declarative NixOS-WSL host, moves the binary cache to system configuration, makes the Git identity declarative, and adds host configuration, activation, rollback, shared user modules, network isolation, and a container runtime.

## Impact

The change affects `flake.nix`, `flake.lock`, `hosts/`, `modules/nixos/`, `modules/home/`, three packages, two checks, the WSL runbook, `README.md`, and the architecture decision log.

It does not change the Darwin host, the OMP package, the personal plugin, the language-server set, or OMP-owned mutable state. It does not manage Windows applications, Windows policy, or the Intune-managed software on `korolev`.

This change depends on `split-home-modules-by-platform`, because the portable user modules must exist before a Linux host can select them.
