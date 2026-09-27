## Scheduling — 2026-09-26

The owner scheduled this change after a plan review. It is position 1, after `align-specs-with-source-generations` is archived.

## 1. Record the Baseline

- [x] 1.1 Fill `baseline.md` with the parent commit, `flake.lock` checksum, and both systems' wrapper, `herdr`, `openspec`, and plugin derivation paths. Use `/tmp/fleet-drv.nix` with `system.configurationRevision` forced to 40 zeros through `extendModules` and `lib.mkForce`. Proof: record the two pinned paths and the exact probe command.
- [x] 1.2 Evaluate the pinned system paths and package paths twice before edits. Proof: identical repeated results, including the known `7723a53` system paths in `baseline.md`.

## 2. Split the Flake

- [x] 2.1 Move output families into `flake-modules/{hosts,packages,checks,devshell,formatter}.nix` and import them through `default.nix`. Keep inputs and `mkFlake` in `flake.nix`. Proof: `nix flake show --json` exposes the same pre-refactor outputs.
- [x] 2.2 Extend the module-import gate to `flake-modules/`. Probe and remove a temporary unlisted sibling. Proof: the gate rejects the omission and accepts the complete imports.
- [x] 2.3 Retain the single `_module.args.pkgs` override and remove its stale Darwin comment. Proof: repeat the pinned-revision path comparison.

## 3. Build the Standalone Host Registry

- [x] 3.1 Add required `host.system` and typed `host.kind` to `modules/fleet/host.nix`. Move each host's typed facts into `hosts/<name>/host.nix`, leaving per-user settings in `default.nix`. Proof: `nix eval` exposes both expected typed records.
- [x] 3.2 Evaluate each directory's `host.nix` with `lib.evalModules` and `modules/fleet/host.nix`, setting `host.name` from the directory. Declare read-only flake-parts `fleet.hosts` and derive `systems` from it. Proof: `nix eval` reports the two names and two systems; a malformed kind fails by option name.
- [x] 3.3 Add typed `fleet.hosts` under `modules/fleet/`; pass the registry into generated Darwin and NixOS configurations. Make both `hosts/<name>/default.nix` files plain modules that import `./host.nix`. Proof: `nix eval` reads the same registry facts from both configurations.
- [x] 3.4 Replace both `inputs.self.darwinConfigurations.macbook-pro.config.host` module reads with registry lookups. Derive remote builders from other hosts with non-null `build.logicalCores`, including system and name-based root key path. Proof: evaluate Korolev's builder set and SSH peer against current values; search modules for zero `inputs.self.*Configurations` uses.
- [x] 3.5 Feed the registry to `lib/tailnet-policy.nix`. Derive every port-22 deny target from hosts with `tailnet.reachable = false`, and update both policy checks. Proof: compare rendered `policy.hujson` bytes with the baseline and run the synthetic-peer rejection checks.
- [x] 3.6 Generate each host's system, home, Nix-settings, login-shell, wrapper-installation, and kind-specific gates with host-prefixed names. Read `config.system.build.toplevel` for both system gates. Proof: inspect `nix flake show --json` and evaluate both gate paths.
- [x] 3.7 Make `fleetSurface` reject a host directory missing `host.nix` or `default.nix` and an evaluated-system mismatch. Keep the default-shell check. Proof: each temporary failure names its directory; remove the probes. Complete directories enter the registry automatically, so there is no separate unlisted-directory case.
- [x] 3.8 Add a temporary second host directory on an existing system. Proof: its configuration and generic gates appear while `systems` stays unchanged; remove the probe.

## 4. Lay Out Packages and Checks

- [x] 4.1 Move every current `packages/` file to its destination in design decision 4. Move the Windows derivation and its source files into `packages/windows-configuration/`, with unchanged rendered output. Proof: compare the Windows output and account for every old package file.
- [x] 4.2 Generate local overlay packages with `lib.packagesFromDirectoryRecursive`, add four explicit input re-exports, and keep the `nixosOptionsDoc` override in `overlays/nixos-options-doc.nix`. Proof: evaluate the overlay attribute names on both systems.
- [x] 4.3 Set `meta.description`, `meta.platforms`, and program `meta.mainProgram` on repository packages. Pass `meta` and `passthru` directly where supported. Proof: an unsupported package and its program check are absent on that system, while both exist on a supported one.
- [x] 4.4 Replace separate Home Manager package calls with `pkgs.<name>`. Install `pkgs.personal-omp`, its updater, and verifier; check their derivation identities in each user's `home.packages`. Proof: compare installed and exported `drvPath` values; a temporary divergent package fails the installation assertion.
- [x] 4.5 Keep `nix build .#tailnet-policy`, `darwin-rebuild` on a system with a Darwin host, and the build-plan command available. Proof: evaluate their flake outputs and exercise the build-plan command on the Mac.

The Mac evaluated the Linux builder derivation. The CI Linux leg built the Korolev system and home generation.

## 5. Package Python and Move Check Programs

- [x] 5.1 Build `packages/omp-dev-update/` with `pyproject.toml`, `src/omp_dev_update/`, and stdlib `unittest` tests under `tests/`. Use `main(argv: Sequence[str] | None = None) -> int` to own argparse; the console script exits with its return value. Use `buildPythonApplication`, `pyproject = true`, and `unittestCheckHook`. Proof: its 650-line suite runs in the package build without `sys.argv.pop` or dynamic file import, and direct argv calls work.
- [x] 5.2 Preserve generated JSON, certificate variables, PATH tools, and `--config` in the installed updater entry point. Proof: execute the packaged command with local fixtures and confirm status, rollback, stderr diagnostics, and exit statuses match the current updater; run its existing package-build suite.
- [x] 5.3 Move markdown-oxide and Roslyn inline checks to `packages/<name>/tests.nix` plus a plain Python driver for Roslyn. Move the inline module-import shell check into `packages/module-imports-check/tests.nix`. Keep the markdown version comparison against `markdownOxide.version`. Proof: build all three checks; mutate a temporary expected result and observe rejection, then revert.
- [x] 5.4 Move wrapper shape, source-generation, version-verification, Herdr reconciliation, and embedded probes to `packages/personal-omp/tests.nix` and adjacent `.py` or `.sh` files. Proof: run the check against the installed wrapper with stub source generations and verify failures for missing or unusable current launchers.
- [x] 5.5 Remove the tautological OpenSpec version comparison. Proof: the home-generation gate still contains the installed pinned OpenSpec package; no test asserts an upstream package equals itself.
- [x] 5.6 Move the workflow Python to `checks/tailnet-policy-workflow.py` and invoke it from `.github/workflows/tailnet-policy.yml`. Proof: run the script against controlled HTTP responses and verify authorization rejection status, without live credentials.
- [x] 5.7 Add `ruff-check` beside `ruff-format` to treefmt. Proof: `nix fmt -- --fail-on-change` accepts the tracked Python sources and rejects a temporary lint violation, then remove the probe.

## 6. Gate the Lock Experiment and Derivations

- [x] 6.1 Add only `llm-agents.inputs.flake-parts.follows = "flake-parts"` without changing a locked revision. Proof: inspect the lock diff for removal of its duplicate node and no changed `rev`.
- [x] 6.2 Compare pre- and post-edit `herdr`, `openspec`, and plugin `drvPath` on both systems, then compare pinned-revision system paths. Revert this follows edit and record the measured reason if a path differs. Proof: keep measurements in `baseline.md`.
- [x] 6.3 Confirm no `personal-omp-plugin.inputs.flake-parts.follows` or `llm-agents.inputs.nixpkgs.follows` was added. Proof: inspect the final input declarations and lock diff.

Both pinned system paths were evaluated at each cutover. The Mac `nvd diff` explained its updater-only closure change. `nix-diff` traced the changed Korolev derivation to the packaged updater.

## 7. Finish Repository Gates and Documentation

`lefthook.yml` has only a pre-commit hook. A pre-push hook would duplicate CI and encourage bypass, so this change does not add one.

- [x] 7.1 Update affected README links, workflow comments, and nearby rationale for the new host-prefixed gates and file layout. Proof: each named command or path resolves and `nix flake show --json` lists named outputs.
- [x] 7.2 Keep `lefthook.yml` limited to pre-commit and record the no-pre-push decision here. Proof: inspect hook configuration and run the development-shell hook smoke.
- [x] 7.3 Run `nix fmt -- --fail-on-change`, `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the Mac. Proof: record command exit statuses and inspect the build-plan output.
- [x] 7.4 Owner: Run `nix flake check --print-build-logs` on `x86_64-linux` with Korolev's declared Nix, either on Korolev or in CI. Proof: record the complete passing check run for that system.
- [x] 7.5 Owner: Record the CI outcome after a reviewed push; do not push solely for this gate. Proof: link the passing `check` workflow run.
- [x] 7.6 Run `openspec validate key-fleet-by-host --strict` after the predecessor is archived. Proof: strict validation exits zero.
- [x] 7.7 Review the complete diff for old package paths, host/user lookup literals, inline programs, duplicate package calls, and obsolete options. Proof: every former caller has one replacement and there are no compatibility aliases.
