## Why

The flake keys its host table by system. `flake.nix:92-113` holds one row for `aarch64-darwin` and one for `x86_64-linux`, `flake.nix:116` derives `systems` from those keys, and `flake.nix:159` selects `host = hosts.${system}`. A second host on either system has no place in that table. The assumption then leaks into every output: `darwinConfigurations.macbook-pro` and `nixosConfigurations.korolev` are written by hand (`flake.nix:126-142`), two checks name `self.darwinConfigurations.macbook-pro.config.home-manager.users.glockyco` (`flake.nix:191`, `flake.nix:199`), six checks bind `korolev` through `let` (`flake.nix:208-211`, `flake.nix:410-459`), and the Darwin system check reads `self.darwinConfigurations.macbook-pro.system` while the NixOS one reads `korolevConfig.system.build.toplevel` (`flake.nix:465`, `flake.nix:413`). `fleetSurface` (`flake.nix:261-271`) compares name lists only, so it cannot report a host directory that the table omits.

Three repository packages are built twice. `packages/personal-omp.nix`, `packages/container-runtime-check.nix`, and `packages/air-batch-check.nix` are each called once in `flake.nix` (`flake.nix:177-193`) and once in a Home Manager module (`modules/home/omp.nix:13-17`, `modules/home/darwin/container-runtime.nix:8`, `modules/home/darwin/ssh.nix:10`). The checks test the flake's copy, and the host installs the module's copy. The two are equal today because the arguments happen to agree, and no check would notice when they stop agreeing. `overlays.default` (`flake.nix:144-146`) already exists for exactly this purpose and carries one package.

The checks for the wrapper assert source text rather than behavior. `personalOmpShape` (`flake.nix:273-308`) runs `grep` over the wrapper script for store paths and for the absence of `/Users/`. `personalOmpVerification` and `herdrOmpReconciliation` (`flake.nix:310-398`) drive the real scripts through stubs, which is the correct form, but their 90 lines of shell live inline in `flake.nix` while every other program test lives in `packages/<x>-check-tests.nix`. `flake.nix` is 512 lines and holds the host table, the package set, twenty checks, the packages, the shell, and the formatter in one `perSystem` function.

This change follows `declare-typed-host-options`, which moved identity into `hosts/<name>/` and gave the flake `hostConfiguration.config.host` to read, and `connect-fleet-over-tailnet`, which put every machine on the tailnet. Both are archived when this change starts. The next change, `separate-platform-baseline-from-roles`, adds roles to hosts, so the host table has to be host-shaped before then.

## What Changes

- Key the host table by host name. Each row holds `system` and `kind`. `systems` becomes the unique set of row systems. `darwinConfigurations` and `nixosConfigurations` are generated from the rows by kind, and `hosts/<name>/default.nix` becomes a plain module.
- Generate every host-bound check and package per host from the table. `<host>-system`, `<host>-home`, `<host>-nix-settings`, `<host>-login-shell`, and `<host>-personal-omp` exist for every host on the system. Kind-scoped checks exist for every host of that kind. No output names a host or a user as a literal.
- Make `fleetSurface` assert that the set of directories under `hosts/` equals the set of table keys, so a host directory without a table row fails the check.
- Split `flake.nix` into flake-parts modules under `flake-modules/`: hosts, packages, checks, devshell, and formatter. `flake.nix` keeps the inputs and the `mkFlake` call. The `moduleImports` check covers `flake-modules/` as it covers `modules/`.
- Build each repository package once. `overlays.default` gains `air-batch-check`, `container-runtime-check`, `windows-configuration`, and the re-exported `herdr`, `openspec`, and `personal-omp-plugin`. Modules consume `pkgs.<name>`. `modules/home/omp.nix` declares `programs.personal-omp.package`, built from `osConfig.host.ompRuntime`, and every check for a host's wrapper reads that option.
- Move the wrapper tests out of `flake.nix` into `packages/personal-omp-tests.nix`, driven by stub executables like the sibling `*-check-tests.nix` files. Replace every `grep` over the wrapper source with a run of the wrapper against a stub.
- Give every repository package `meta.description`, `meta.mainProgram`, and `meta.platforms`, passed to `writeShellApplication` as direct arguments together with `passthru`. Exported packages and program checks are filtered by `meta.platforms`, not by a host-kind branch.
- Delete the stale `_module.args.pkgs` comment. Keep the override, which is the mechanism flake-parts documents for a caller-supplied package set.
- Add `llm-agents.inputs.flake-parts.follows = "flake-parts"`, which removes the `flake-parts_3` lock node, and keep it only if the `herdr`, `openspec`, and plugin derivation paths are unchanged.
- Keep the commit hook as the only local gate. No `pre-push` hook is added. The design records the reason.
- Update the flake description and the workflow comments that name `darwinSystem` or a retired check name.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `repository-quality-gates`: requires hosts to be declared by name with a system, requires the host outputs and the host gates to be generated from that declaration, requires a program check to exercise the program rather than its source text, and strengthens the shared-artifact scenario so that a check asserts the derivation the host installs.

## Impact

The change affects `flake.nix`, a new `flake-modules/` directory, `hosts/macbook-pro/default.nix`, `hosts/korolev/default.nix`, every file under `packages/`, a new `packages/personal-omp-tests.nix`, `modules/home/omp.nix`, `modules/home/darwin/container-runtime.nix`, `modules/home/darwin/ssh.nix`, `.github/workflows/check.yml`, `README.md`, and the architecture decision log.

It changes no host behavior. The acceptance gate is the one `declare-typed-host-options` established: identical `config.system.build.toplevel.drvPath` for both hosts with `system.configurationRevision` pinned, plus an `nvd` closure diff on each host, recorded in `baseline.md`. No input revision changes while the change is open. The one permitted `flake.lock` edit removes a duplicate `flake-parts` node and changes no `rev`.

Explicit non-goals: the `AIR_BATCH_DOCKER` requirement in `packages/air-batch-check.nix`, the hardcoded Air identity in `packages/air-batch-config-check.nix`, the `computerName` and container sizing literals, the role split of `modules/darwin/` and `modules/nixos/`, the Python programs under `modules/home/darwin/`, the Windows check, the version of Nix on the macOS runner, and every documentation finding. Each belongs to `separate-platform-baseline-from-roles`, `package-user-programs`, `derive-windows-check-from-declaration`, or `align-documentation-with-fleet`.
