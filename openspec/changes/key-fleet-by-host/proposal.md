## Scheduling — 2026-09-26

The owner scheduled this change after a plan review. It is position 1, after `align-specs-with-source-generations` is archived.

## Why

`flake.nix:95-109` keys hosts by system. The two builders are hand-written (`flake.nix:115-135`), and `perSystem` selects one host per system (`flake.nix:154-163`). A second host on an existing system cannot fit this model. Checks and configuration outputs use literal host names (`flake.nix:174-177`, `:710-793`). Two NixOS modules evaluate the Darwin configuration to obtain peer facts (`modules/nixos/nix.nix:9-10`, `modules/nixos/programs.nix:11-12`). The tailnet renderer names one unreachable host (`packages/tailnet-policy.nix:66-67`, `:88-92`).

The flake and Home Manager independently call the OMP package (`flake.nix:192-202`, `modules/home/omp.nix:11-21`). The same pattern affects the Air and container-runtime commands (`flake.nix:208-222`, `modules/home/darwin/ssh.nix:12`, `modules/home/darwin/container-runtime.nix:8`). Checks can exercise a derivation other than the one a host installs. `flake.nix` has 839 lines and embeds Python and shell programs in checks (`flake.nix:282-389`, `:487-697`). Its package files mix packages, check derivations, and a policy renderer under `packages/`.

## What Changes

- Move each host's typed facts into `hosts/<name>/host.nix`. Evaluate each declaration alone to build a read-only, host-keyed `fleet.hosts` registry. Generate configurations and per-host gates from that registry. Pass it into configurations as a typed option. Derive builder and tailnet peer facts from it, without reading another host's evaluated configuration.
- Make `fleetSurface` compare declared names to directories that contain both `host.nix` and `default.nix`. It also checks each host's evaluated system. A second host on an existing system adds a directory, not a flake output branch.
- Split the flake into output-family modules under `flake-modules/`. Move repository packages to `packages/<name>/package.nix` and generate overlay attributes with `lib.packagesFromDirectoryRecursive`. Put assertion checks in `checks/`, the NixOS options override in `overlays/`, and the tailnet renderer outside `packages/`.
- Export the host-independent `pkgs.personal-omp` wrapper through the overlay. Assert that hosts install that exact derivation and its updater and verifier. Exercise source-generation behavior with program tests; do not add a per-host wrapper option.
- Set one Python packaging convention. Package `omp-dev-update` with `buildPythonApplication` and run its existing unittest suite during the package build. Keep its config file, certificate environment, tool paths, and source-generation behavior.
- Move all inline check programs and the workflow's Python program into tracked files. Add `ruff-check` to treefmt. Keep package metadata and platform filtering, the one package set per system, and the existing pre-commit-only hook.
- Try `llm-agents.inputs.flake-parts.follows = "flake-parts"` only if pinned-revision system paths and selected package derivations remain unchanged. Keep the `nix build .#tailnet-policy` output.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `repository-quality-gates`: requires standalone typed host declarations, a generated registry and host gates, package-set identity, and program checks that exercise behavior.

## Impact

Implementation changes the flake, both host directories, `modules/fleet/`, the NixOS peer consumers, package and check layout, the tailnet renderer, `treefmt.nix`, the tailnet workflow, related comments, and relevant documentation. `modules/windows/` becomes `packages/windows-configuration/` without changing rendered output. The next change, `derive-windows-check-from-declaration`, consumes that package layout.

The gate compares both system derivations with `system.configurationRevision` pinned. The baseline at `7723a53` is in `baseline.md`; other package paths and the lock checksum are recorded during implementation. The only permitted lock change removes the gated duplicate `flake-parts` node without changing any input revision. Owner-only Linux and live gates remain separate tasks.

This change does not add a host, change tailnet access, prepare OMP source during activation, change the Air lifecycle, or install a Windows resource. The Air package and checks stay functional for the later role split and eventual removal under issue #17.
