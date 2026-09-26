## Context

`flake.nix` is 839 lines. Its system-keyed host map, manually selected configurations, shared package set, and current checks are at `flake.nix:95-109`, `:115-143`, `:146-279`, and `:281-793`. Host builders hold both identity and per-user settings (`hosts/macbook-pro/default.nix:1-45`, `hosts/korolev/default.nix:1-65`). `modules/fleet/host.nix:7-36` already types name, username, logical cores, and tailnet facts. The wrapper resolves the selected host-local source generation at run time (`packages/personal-omp.nix:24-36`, `:104-120`); there is no host-specific executable option. The NixOS builder and SSH modules currently force a second host configuration for peer facts (`modules/nixos/nix.nix:9-10`, `modules/nixos/programs.nix:11-12`). The policy renderer hard-codes its unreachable host (`packages/tailnet-policy.nix:56-67`, `:88-102`).

The current flake calls `personal-omp`, `markdown-oxide`, and Roslyn packages separately from Home Manager (`flake.nix:192-202`, `modules/home/omp.nix:9-21`). It exposes the updater through the wrapper (`flake.nix:254-261`). It embeds Python and shell check programs (`flake.nix:282-389`, `:487-697`). The updater builds a shell application that launches a Python source file with a generated JSON config (`packages/omp-dev-update.nix:7-53`); its unittest file has 650 lines and imports the script after changing `sys.argv` (`packages/omp-dev-update-tests.py:1-27`). Treefmt enables `ruff-format`, not `ruff-check` (`treefmt.nix:17-23`). The tailnet workflow embeds Python (`.github/workflows/tailnet-policy.yml:35-95`).

## Goals / Non-Goals

**Goals:**

- One standalone typed declaration per host, one host-keyed registry, and no cross-host configuration evaluation in modules.
- Generate configurations and host gates for each declared host, including two hosts on one system.
- One package-set instance per system. Modules and checks consume the packages that instance exposes.
- Separate package derivations, checks, and the policy renderer by purpose. Put executable check programs in files.
- Preserve the current builder and tailnet policy, source-generation workflow, and Windows rendering.
- Compare pinned-revision derivations against the recorded baseline and explain each intentional difference.

**Non-goals:**

- Add a third host, a typed Air host, or a new inbound tailnet service. Issue #17 governs Air removal.
- Prepare OMP source generations during activation or add a per-host wrapper option.
- Change Windows application policy or the check's accepted behavior. The next change owns its new CLI package.
- Add a pre-push hook, change Nix revisions, or perform host activation.

## Decisions

### 1. Evaluate host facts alone, then distribute a typed registry

`hosts/macbook-pro/host.nix` and `hosts/korolev/host.nix` set only `host.*`. Move the current facts from `hosts/macbook-pro/default.nix:26-30` and `hosts/korolev/default.nix:26-32` there. Extend `modules/fleet/host.nix` with required `host.system : types.str` and `host.kind : types.enum [ "darwin" "nixos" ]`. Each declaration holds its existing username, builder core count, tailnet tag, and reachability. The directory name supplies `host.name`; its declaration does not repeat that fact.

`flake-modules/hosts.nix` enumerates directory entries under `../hosts`. For each directory name `name`, evaluate exactly:

```nix
(lib.evalModules {
  modules = [
    ../modules/fleet/host.nix
    (../hosts + "/${name}/host.nix")
    { host.name = name; }
  ];
}).config.host
```

The result maps `name` to the typed host facts. Declare `fleet.hosts` as a read-only flake-parts option with an `attrsOf` submodule type derived from `modules/fleet/host.nix` options, and set it to this result. This option is the only registry. Derive `systems = lib.unique (lib.mapAttrsToList (_: host: host.system) config.fleet.hosts)`. A missing `host.nix` fails the explicit `fleetSurface` gate, not a silent skip during enumeration; evaluate only entries with that file and let the gate report absent files.

Add `modules/fleet/registry.nix`, imported from `modules/fleet/default.nix`. Its `fleet.hosts` option is typed as `types.attrsOf (types.submodule { options = (import ./host.nix { inherit lib; }).options.host; })`. The generated configuration sets `fleet.hosts = config.fleet.hosts` in an injected module. Registry values are direct host facts at `config.fleet.hosts.${name}.name`, not nested `host.host`. Each `hosts/<name>/default.nix` becomes a plain module. It imports `./host.nix` and its platform modules and keeps per-user configuration. Builders receive `specialArgs = { inherit inputs; }`, `nixpkgs.pkgs = pkgs`, and the typed registry. Modules read their own identity through `config.host` and peer facts through `config.fleet.hosts`; no module reads `inputs.self.darwinConfigurations` or `inputs.self.nixosConfigurations`.

The registry's option type must reuse the same host option declarations, not a second set of field types. An explicit typed table in `flake-modules/hosts.nix` is rejected: the host module now serves the builder, peer consumers, and renderer as well as the flake.

### 2. Generate each host configuration and gate from the registry

Filter `fleet.hosts` by `kind` for `flake.darwinConfigurations` and `flake.nixosConfigurations`. Apply `withSystem host.system` and the matching `inputs.nix-darwin.lib.darwinSystem` or `inputs.nixpkgs.lib.nixosSystem`. Import `../hosts/${name}/default.nix`; do not call a builder from that module. For each `perSystem`, filter hosts by `host.system == system`, then form `{ host; configuration; }` records. A record reads its configuration only when a gate needs it. There is no one-host-per-system binding.

Generate `<name>-system` using `configuration.config.system.build.toplevel` for both kinds. Generate `<name>-home`, `<name>-nix-settings`, `<name>-login-shell`, and `<name>-personal-omp` for each host. Keep existing kind-specific isolation, container, Darwin tailnet, Air configuration, and container configuration assertions. Bind usernames through `host.username`, never a literal. Make the package gate compare `pkgs.personal-omp`, `.devUpdate`, and `.verifyPersonalOmp` by derivation identity with that user's `home.packages`. The standalone wrapper's own behavior tests are one system-wide check and run on the same `pkgs.personal-omp` derivation. Host-prefixed checks retain a per-host installation assertion.

`fleetSurface` compares the directory set and registry keys. Every directory must have both `host.nix` and `default.nix`; a missing file or unlisted directory fails with its name. Also assert `self.devShells.${system} ? default` and each current-system configuration's `pkgs.stdenv.hostPlatform.system == host.system == system`. Do not compare generated configuration names to registry keys: generation makes that comparison tautological. Probe a second host directory on an existing system, then remove it.

### 3. Derive builder and tailnet peer behavior without configuration recursion

`modules/nixos/nix.nix` selects every registry entry other than `config.host.name` for which `build.logicalCores != null`. For each builder, set `hostName = builder.name`, `sshUser = builder.username`, `system = builder.system`, `sshKey = "/root/.ssh/${builder.name}-builder"`, and both job and speed values from its logical cores. The current registry selects only the Mac and preserves its existing settings (`modules/nixos/nix.nix:35-45`). `modules/nixos/programs.nix` reads that peer from `config.fleet.hosts` for SSH and tailnet naming. It does not evaluate the Darwin configuration. The existing Windows desktop remains a separately declared unmanaged peer (`modules/nixos/programs.nix:14-25`).

`lib/tailnet-policy.nix` takes the registry and the shared peer declaration. The policy's port-22 deny entries derive from every registry host with `tailnet.reachable = false`; it does not name `korolev`. Update `checks/tailnet-policy-check.nix` to derive expected deny targets from the same property and keep its synthetic `fixture-peer` offboarding probe. Preserve the bytes of `policy.hujson` and the `packages.tailnet-policy` output. An overlay attribute for the renderer is rejected because its function takes the registry, not package-set inputs.

### 4. Split flake outputs and classify package files

`flake.nix` keeps input declarations and `mkFlake`. `flake-modules/default.nix` imports `hosts.nix` (registry, configurations, per-host gates), `packages.nix` (overlay, package exports, `_module.args.pkgs`), `checks.nix` (host-independent checks and policy wiring), `devshell.nix`, and `formatter.nix`. Extend `moduleImports` to cover `flake-modules/`. Keep `_module.args.pkgs = inputs.nixpkgs.legacyPackages.${system}.extend self.overlays.default` (`flake.nix:165-168`, `:250-252`), but remove the Darwin-specific comment that no longer applies. Do not use `easyOverlay`: it extends and re-evaluates the package set.

Generate local package attributes in `overlays.default` with `lib.packagesFromDirectoryRecursive { inherit (final) callPackage; directory = ../packages; }`. Add explicit `herdr`, `openspec`, `personal-omp-plugin`, and `plannotator` input re-exports. Apply the `nixosOptionsDoc` override from `overlays/nixos-options-doc.nix`. Packages resolve package dependencies through `final`, with no second call site. Each `package.nix` must instantiate from package-set arguments alone. A host-specific optional argument may be supplied with `.override` in the consuming module. `packages/tailnet-builder-check.nix:2-8` currently requires `hostName`; make it optional and override it with the selected registry builder name in the consuming module. Keep the installed command's zero-argument behavior. `packages/check-darwin-build-plans.nix:1-7` requires `flakeSource`; make it optional in the generic overlay package, then supply `self.outPath` through `.override` for the flake output. Preserve its packaged-flake snapshot behavior (`packages/check-darwin-build-plans.nix:31-69`). The Windows derivation at `modules/windows/default.nix:1-7` moves with its five sibling source files to `packages/windows-configuration/`. Adjust its `../shared` import to preserve the rendered files.

Existing `packages/` files have these destinations. A package directory contains `package.nix`, optional `tests.nix`, and source files. An assertion check is not an overlay package.

| Current file(s)                                                                                     | Destination                                                                                                              |
| --------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| `air-batch-check.nix`, `air-batch-check-tests.nix`                                                  | `packages/air-batch-check/{package,tests}.nix`                                                                           |
| `air-batch-config-check.nix`                                                                        | `checks/air-batch-config-check.nix`                                                                                      |
| `check-darwin-build-plans.nix`                                                                      | `packages/check-darwin-build-plans/package.nix`                                                                          |
| `container-runtime-check.nix`, `container-runtime-check-tests.nix`                                  | `packages/container-runtime-check/{package,tests}.nix`                                                                   |
| `container-runtime-config-check.nix`                                                                | `checks/container-runtime-config-check.nix`                                                                              |
| `host-declaration-check.nix`, `host-nix-settings-check.nix`                                         | `checks/{host-declaration-check,host-nix-settings-check}.nix`                                                            |
| `markdown-oxide.nix`, `roslyn-language-server.nix`                                                  | `packages/{markdown-oxide,roslyn-language-server}/package.nix`                                                           |
| `module-imports-check.nix`, `module-imports-check-tests.nix`                                        | `packages/module-imports-check/{package,tests}.nix`                                                                      |
| `neo-keyboard-layouts.nix`                                                                          | `packages/neo-keyboard-layouts/package.nix`                                                                              |
| `omp-browser-runtime-check.nix`                                                                     | `checks/omp-browser-runtime-check.nix`                                                                                   |
| `omp-dev-update.nix`, `omp-dev-update.py`, `omp-dev-update-tests.py`                                | `packages/omp-dev-update/package.nix`, `src/omp_dev_update/`, `tests/`                                                   |
| `options-context.nix`                                                                               | `overlays/nixos-options-doc.nix`                                                                                         |
| `personal-omp.nix`                                                                                  | `packages/personal-omp/package.nix`                                                                                      |
| `tailnet-builder-check.nix`, `tailscale-set-after-login.nix`, `tailscale-set-after-login-tests.nix` | `packages/{tailnet-builder-check,tailscale-set-after-login}/package.nix`, `packages/tailscale-set-after-login/tests.nix` |
| `tailnet-policy.nix`                                                                                | `lib/tailnet-policy.nix`                                                                                                 |
| `tailnet-policy-check.nix`, `tailnet-policy-rejects.nix`                                            | `checks/{tailnet-policy-check,tailnet-policy-rejects}.nix`                                                               |
| `windows-configuration-check.nix`, `windows-configuration-check.py`                                 | `checks/windows-configuration.nix`, `checks/windows-configuration-check.py`; the next change packages the CLI            |
| `wsl-open.nix`, `wsl-open-tests.nix`                                                                | `packages/wsl-open/{package,tests}.nix`                                                                                  |

The generated overlay's attribute names equal package directory names. Package outputs and program checks filter on `meta.platforms`, not a host-kind branch. Add `meta.description`, `meta.mainProgram` for programs, and `meta.platforms`. Pass `meta` and `passthru` directly to `writeShellApplication`; remove `overrideAttrs` wrappers used only to attach them. `darwin-rebuild` remains a conditional external input, and the registry determines whether a Darwin host exists on the system. `tailnet-policy` remains an explicit flake package from the renderer. `check-darwin-build-plans` retains its store-access command, outside sandboxed checks.

### 5. Keep the wrapper host-independent and test source generations

Place `personal-omp` in the overlay as `pkgs.personal-omp` with `devUpdate`, `verifyPersonalOmp`, and `reconcileHerdrOmp` passthru. Move its updater dependency to `pkgs.omp-dev-update`. Home Manager consumes the overlay package and its passthru commands (`modules/home/omp.nix:24-36`). Do not add `programs.personal-omp.package`. This reflects the wrapper's fixed `~/.local/share/omp-dev/current` lookup (`packages/personal-omp.nix:24-36`). The wrapper shape, source-generation, version verification, and Herdr reconciliation tests keep their observable assertions (`flake.nix:447-697`). Delete the OpenSpec version self-comparison (`flake.nix:483`); the home-generation gate exercises the installed package. No test invents an absolute/home-relative executable declaration or installation command.

### 6. Define the Python program convention here and apply it to the updater

A packaged Python program lives in `packages/<name>/` with `pyproject.toml` and `src/<module>/`. Its entry point has signature `main(argv: Sequence[str] | None = None) -> int`. It owns `argparse`, parses `sys.argv[1:]` when `argv` is `None`, and the console script exits with its returned status. Importing the module has no side effects. Use stdlib `unittest` under `tests/` and `python3Packages.buildPythonApplication` with `pyproject = true` and `unittestCheckHook`. Expected failures print a concise diagnostic on stderr without a traceback and return 1; the program owns its diagnostic format. The current updater already owns argument parsing in `main(argv)` (`packages/omp-dev-update.py:887-935`); add the explicit type signature and console-script entry point. Keep its tests but import the module normally, without `spec_from_file_location` or `sys.argv.pop` (`packages/omp-dev-update-tests.py:1-27`). Run the 650-line suite as part of the package build with real local Git fixtures and no network (`packages/omp-dev-update-tests.py:27-84`).

The updater reports phase, candidate, and error on stderr for handled failures (`packages/omp-dev-update.py:918-935`). Preserve that diagnostic, its exit status, and its handled error classes. Package relocation does not change operator failure evidence.

The generated JSON must still carry pinned URLs, patch commits, system, plugin, Git, gh, Nix and nix-store paths, and Linux `nixPackage` (`packages/omp-dev-update.nix:7-31`). The installed entry point must still receive `--config` with that JSON; preserve `SSL_CERT_FILE`, `NIX_SSL_CERT_FILE`, and the Git/gh/coreutils/Nix PATH from the current launcher (`packages/omp-dev-update.nix:32-45`). A package-set-only overlay call supplies the plugin from `pkgs.personal-omp-plugin`; avoid a recursive `pkgs.personal-omp` dependency. Preserve `--status`, `--rollback`, and source-generation selection. Add a real entry-point invocation to the package-build tests to cover launcher behavior and the environment contract.

The Python files that only drive Nix checks are plain `.py` beside their `tests.nix`. Pass their store paths through environment variables, not generated Python source. Add `ruff-check` to `treefmt.nix` beside `ruff-format`; use default rules. Later Python program migrations follow this convention instead of redefining it.

### 7. Move all inline programs to tracked sources

Move `markdownOxideVersion` (`flake.nix:282-287`) to `packages/markdown-oxide/tests.nix`. Keep comparing `markdown-oxide --version` with `markdownOxide.version`. Move `roslynInitialization` (`flake.nix:289-389`) to `packages/roslyn-language-server/{tests.nix,initialization.py}`. Move the module-import shell check (`flake.nix:391-396`) to `packages/module-imports-check/tests.nix`. Move `personalOmpShape` (`flake.nix:447-485`), `personalOmpGeneration` and its probe (`:487-581`), `personalOmpVerification` and its two probes (`:583-654`), and `herdrOmpReconciliation` and its shell stub (`:656-697`) to `packages/personal-omp/tests.nix` with adjacent plain `.py` or `.sh` files. Keep shell test drivers in files too. Keep assertions about generation selection, state preservation, plugin payload, PATH precedence, version reporting, and Herdr integration. Move `.github/workflows/tailnet-policy.yml:43-95` to `checks/tailnet-policy-workflow.py` and invoke that tracked script in the workflow. Ruff formats and checks all tracked Python files.

### 8. Limit lock and hook changes; gate derivations with a pinned revision

Keep `lefthook.yml` at pre-commit only. Full `nix flake check` builds both host and home closures; a pre-push hook duplicates CI and encourages bypass. Keep `llm-agents.inputs.nixpkgs.follows` absent: `flake.nix:67-69` records its separate cached package set. Try `llm-agents.inputs.flake-parts.follows = "flake-parts"`; do not add a nonexistent `personal-omp-plugin.inputs.flake-parts.follows`. Keep this edit only if `herdr`, `openspec`, and plugin `drvPath` values on both systems match their pre-edit paths and no input revision changes. Compare pinned-revision system derivations at the same step. Revert this one follows edit if a path changes and record the measured reason beside the input.

The baseline revision is `7723a53`. Force `system.configurationRevision` through `extendModules` with `lib.mkForce` to 40 zeros, using `/tmp/fleet-drv.nix`. Baseline `config.system.build.toplevel.drvPath` values are `/nix/store/415gil1nfc8ri1g9s05ycfbgxhp1n82g-darwin-system-26.05.c3e90c8.drv` for `macbook-pro` and `/nix/store/g49mzl623c5b30jb3y21m1v916byafvv-nixos-system-korolev-26.05.20260903.a5cc6f2.drv` for `korolev`. During implementation fill `baseline.md` with the lock checksum and `herdr`, `openspec`, plugin, and wrapper derivation paths. Evaluate twice before editing. After each logical step compare pinned-revision paths and inspect `nvd diff` on each host for any difference. The Python package and moved source paths can intentionally change derivations; record the exact cause and closure diff rather than claim bit-identical paths. Reject unexplained differences. Korolev can evaluate on the Mac but needs Korolev or CI to build.

## Risks / Trade-offs

- A host directory can be incomplete. `fleetSurface` explicitly names missing `host.nix` or `default.nix` and an evaluated-system mismatch.
- The registry option duplicates a typed *instance*, not option definitions: both module scopes reuse `modules/fleet/host.nix` types. This avoids cross-host recursion.
- Source relocation and Python packaging can change store paths even when behavior is unchanged. The pinned revision and closure comparison expose the cause; do not waive an unexplained path change.
- Generated package attributes can include unsupported platforms. `meta.platforms` filters exports and their program checks before evaluation on that system.
- Policy construction depends on the source directory and registry. Rendered policy comparison catches a grant or deny change before a push.

## Migration Plan

1. Fill `baseline.md` with measured lock and package paths. Run the pinned-revision probe twice.
1. Split flake modules without changing outputs. Compare the pinned-revision paths.
1. Extract host declarations and build the typed registry. Migrate configurations and every module consumer to it. Probe a second host and incomplete directories.
1. Move packages, checks, Windows source, and renderer. Generate overlay attributes. Wire modules to overlay derivations.
1. Package the updater, move all check programs and workflow Python, and add `ruff-check`. Exercise updater, wrapper, renderer, and the workflow driver.
1. Try the gated lock `follows` edit. Compare derivation paths, keep or revert it according to the measured result.
1. Update relevant documentation and workflow comments. Run applicable gates. Leave owner-only activation, Korolev, and CI results pending until the owner records them.

A repository refactor does not select a new OMP source generation. Git revert restores the declarations; Nix activation and OMP rollback remain separate operations.
