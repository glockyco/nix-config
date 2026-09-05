## Scheduling — 2026-09-05

This change is deferred, not canceled or complete. It is not a prerequisite for wrapped OMP usability or the WSL restart, DNS, MagicDNS, and SSH checks. The scheduling notice below remains authoritative.

The technical proposal, design, specifications, and unchecked tasks remain requirements for future implementation. CLI artifact and task counts describe artifact and task state, not authorization to start work. Work resumes only when a concrete maintenance or use requirement warrants it and the owner schedules the change after another plan review.

## 1. Record the Refactor Baseline

- [ ] 1.1 Record the parent commit, `flake.lock` checksum, both wrappers, and the `herdr`, `openspec`, and plugin derivation paths in `baseline.md`. Force one `system.configurationRevision` through `extendModules`, and record both system `toplevel.drvPath` values.
- [ ] 1.2 Run the recorded evaluations twice before editing. Confirm that every path is stable and that the Darwin `.system` output equals `config.system.build.toplevel`.

## 2. Split the Flake by Output Family

- [ ] 2.1 Create `flake-modules/{hosts,packages,checks,devshell,formatter}.nix` and one importing `default.nix`. Move declarations without changing them, and keep only inputs and `mkFlake` in `flake.nix`.
- [ ] 2.2 Extend `moduleImports` to cover `flake-modules/`. Confirm that it accepts the complete list and rejects one temporary unlisted sibling before the probe is reverted.
- [ ] 2.3 Delete the stale `_module.args.pkgs` comment and keep the documented package-set override. Confirm that both pinned-revision system paths still equal the baseline.

## 3. Key the Fleet by Host Name

- [ ] 3.1 Add the typed `fleet.hosts.<name>.system` and `kind` options. Declare `macbook-pro` and `korolev` as rows, and derive the supported systems as the unique row systems.
- [ ] 3.2 Generate Darwin and NixOS configurations by filtering the table by kind. Make each host directory a plain module, and confirm both generated configuration names and systems through `nix eval`.
- [ ] 3.3 Generate `hostConfigurations` for each `perSystem` scope. Generate each host's system, home, Nix-settings, login-shell, wrapper, and kind-specific gates with host-prefixed names.
- [ ] 3.4 Make every host-bound gate read the host and user through `configuration.config.host`. Confirm that no check declaration contains `macbook-pro`, `korolev`, or `glockyco` as a lookup literal.
- [ ] 3.5 Make every system gate read `configuration.config.system.build.toplevel`. Confirm that the Darwin and NixOS gate expressions use the same option path.
- [ ] 3.6 Rewrite `fleetSurface` to compare `hosts/` directory names with table keys and to verify each row's evaluated system. Confirm it rejects a temporary unmatched host directory and reports its name, then remove the probe.
- [ ] 3.7 Add a temporary second host row on an existing system with a matching minimal host directory. Confirm its configuration and all generic host gates appear without changing `systems`, then remove the probe.

## 4. Build Repository Packages Once

- [ ] 4.1 Extend `overlays.default` with every repository package and the pinned `herdr`, `openspec`, and personal plugin re-exports. Keep the attribute list explicit, and make `perSystem.packages` filter it through `meta.platforms`.
- [ ] 4.2 Add direct `meta.description`, `meta.mainProgram`, and `meta.platforms` arguments to every program package. Add `meta.description` and `meta.platforms` to non-program outputs, and remove `overrideAttrs` wrappers used only for metadata or passthru.
- [ ] 4.3 Cut the Air batch and container-runtime modules over to `pkgs.air-batch-check` and `pkgs.container-runtime-check`. Confirm that the installed and exported values have identical derivation paths.
- [ ] 4.4 Add `programs.personal-omp.package`, defaulted from `osConfig.host.ompRuntime`. Make installation, activation, the host package output, and its check read that option.
- [ ] 4.5 Confirm that each host wrapper check asserts the exact derivation in that user's declared packages. Change one temporary option to another wrapper, observe the check fail, then revert the probe.
- [ ] 4.6 Confirm that an unavailable package and its program check are absent from the unsupported system through `meta.platforms`, with no host-kind branch.

## 5. Move Wrapper Checks Beside the Package

- [ ] 5.1 Create `packages/personal-omp-tests.nix` with delegation, missing-executable, home-relative, absolute-path, plugin payload, verification, and Herdr reconciliation scenarios. Drive every executable through doubles.
- [ ] 5.2 Replace every wrapper source-text assertion with a run of the wrapper. Confirm that a source-only rewrite passes and that removing or reordering one delegated argument fails.
- [ ] 5.3 Delete the inline wrapper test shell from `flake.nix` and register the sibling test for every host wrapper. Confirm each generated check names its host and exercises that host's installed derivation.
- [ ] 5.4 Remove the tautological OpenSpec version comparison. Confirm that the home-generation gate still builds the pinned OpenSpec package that the host installs.

## 6. Reduce Duplicate Lock Nodes Safely

- [ ] 6.1 Add `llm-agents.inputs.flake-parts.follows = "flake-parts"` without changing any locked revision. Confirm that `flake-parts_3` leaves the lock and that the Determinate-owned flake-parts node remains.
- [ ] 6.2 Compare `herdr`, `openspec`, plugin, wrapper, and both pinned-revision system derivation paths with `baseline.md`. Revert the follows edit and record the measured reason if any path changes.
- [ ] 6.3 Confirm that no nonexistent `personal-omp-plugin.inputs.flake-parts` follows and no `llm-agents.inputs.nixpkgs` follows was added.

## 7. Update Gate Names and Documentation

- [ ] 7.1 Update workflow comments and the flake description for the generated host-prefixed check names. Confirm every named check appears in `nix flake show --json`.
- [ ] 7.2 Keep `lefthook.yml` limited to the formatting gate. Keep the no-pre-push rationale in this design and the hook configuration comment.
- [ ] 7.3 Update relevant README links and check invocations for the generated host outputs; do not add an output inventory.

## 8. Verify the Complete Change

- [ ] 8.1 Confirm both pinned-revision system derivation paths equal the baseline. Run `nvd diff` for any difference and remove every unexplained closure change.
- [ ] 8.2 Confirm the `flake.lock` diff removes only the gated duplicate node and changes no `rev`.
- [ ] 8.3 Run `nix fmt -- --fail-on-change`.
- [ ] 8.4 Run `nix flake check --print-build-logs` on `x86_64-linux` with the Nix the host declares.
- [ ] 8.5 Run `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the Mac.
- [ ] 8.6 Run `openspec validate key-fleet-by-host --strict`.
- [ ] 8.7 Review the final diff by flake module, host generator, package, program check, workflow, and documentation. Confirm that no compatibility alias, duplicate package call, source grep, or literal host lookup remains.

## 9. Record the Architecture Decision

- [ ] 9.1 Record the host-keyed fleet, generated outputs, overlay ownership, and behavior-driven checks in this change and nearby rationale comments.
- [ ] 9.2 Record the no-pre-push decision and the gated `flake-parts` follows outcome in this change. Confirm that the entry names the measured derivation gate.
