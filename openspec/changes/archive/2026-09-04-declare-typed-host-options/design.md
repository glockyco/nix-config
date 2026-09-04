## Context

See `proposal.md` for the motivation. The facts that shape the approach:

- `flake.nix` holds a table keyed by system. Each row carries `kind`, `name`, `username`, and `ompRuntime`. `hosts/<name>/default.nix` receives the row, unpacks four values, and passes them as `specialArgs` to `darwinSystem` or `nixosSystem`. Both `home-manager.nix` files copy the same four values into `extraSpecialArgs`.
- `perSystem` reads `host.ompRuntime` from the table to build `packages.personal-omp` and reads `host.username` to locate the user's Home Manager configuration in checks. It already reads other values back out of the evaluated host, for example `korolevConfig.wsl.defaultUser`.
- Home Manager runs as a system module on both hosts. Its NixOS module passes `osConfig` to every user-scope module (`nixos/common.nix:30` in the pinned revision), and its nix-darwin module imports that same file. No forwarding is needed for a user-scope module to read the system configuration.
- The pinned `lib` provides `types.attrTag` for a tagged union and `types.path` for an absolute path. A probe against that `lib` confirmed that `lib.evalModules` rejects a missing definition, a wrong tag, and a relative string under `absolute`, and that `builtins.tryEval` observes each rejection only when the value is forced with `builtins.deepSeq`. A shallow force accepted `absolute = "relative/omp"`.
- `modules/shared/default.nix` is a plain attribute set of data, consumed with `import ../shared` outside the module system. `modules/darwin/` and `modules/nixos/` are module lists. The `moduleImports` check requires every `.nix` file under `modules/` to appear in its directory's `default.nix`.
- `system.configurationRevision` enters both system derivations, so a store-path comparison across commits reports every commit as a change. `split-home-modules-by-platform` used an `nvd` closure diff plus evaluated invariants as its gate.

## Goals / Non-Goals

**Goals:**

- One typed declaration per host, validated at evaluation time, read through `config.host` and `osConfig.host`.
- `specialArgs` and `extraSpecialArgs` carry `inputs` alone.
- Each shared fact has one declaration that both platform scopes and their checks read.
- Both system derivations are unchanged by the change, up to the configuration revision.

**Non-Goals:**

- Rekeying the host table by name, generating configurations, or per-host checks. That is the next planned change; this one leaves the table keyed by system.
- Building `personal-omp` once through the overlay. `modules/home/omp.nix` keeps its `callPackage` and reads its arguments from `osConfig.host`.
- Any behavior change: the Darwin `trusted-users` entry, `computerName`, the `/home/<user>` restatement, and the CI and runbook copies of the cache key stay as they are.
- Standalone Home Manager activation outside a system scope. Both hosts import Home Manager as a system module, and the portable modules now depend on that.

## Decisions

### 1. Declare `host` as module options in `modules/fleet/host.nix`

The module declares:

```text
host.name                              types.str
host.username                          types.str
host.ompRuntime.executable             types.attrTag { absolute = types.path; homeRelative = types.str; }
host.ompRuntime.installCommand         types.nonEmptyStr
```

No option has a default. A host that omits one fails at the first read with the option name in the message, before any consumer evaluates.

`modules/fleet/` is a new directory for modules that a complete host of either kind imports. `modules/shared/` is rejected because it is a data attribute set that `import ../shared` consumes, not a module list. `modules/darwin/` and `modules/nixos/` are rejected because the declaration must be identical in both scopes. Inlining the options in `flake.nix` is rejected because `hosts/<name>/default.nix` could not import them idiomatically. `modules/fleet/default.nix` imports `./host.nix` and `./home-manager.nix`, which satisfies the `moduleImports` check, and both platform `default.nix` files import `../fleet`.

Alternative rejected: a submodule under `types.submodule` with `freeformType`. The set of host facts is closed, and an unknown attribute should fail.

### 2. Identity lives in `hosts/<name>/default.nix`; the flake table binds system to host

The flake table shrinks to `{ kind; name; }` per system. `hosts/<name>/default.nix` receives `{ inputs, pkgs, name }` and contains a module that sets `host.name = name` plus `host.username` and `host.ompRuntime`. The per-machine Git identity already lives there, so the directory becomes the one place that says what a machine is.

`perSystem` reads `hostConfiguration.config.host` for the values it needs: `ompRuntime` for `packages.personal-omp` and `username` for the checks that locate the user's Home Manager configuration. This follows the direction the flake already uses for `korolevConfig.wsl.defaultUser`, and it is the direction the later overlay change needs, where the flake exposes the package that the host builds.

Alternative rejected: keep identity in the table and have the host module copy it into `config.host`. That keeps two homes for the same fact and makes the table a second, untyped declaration.

### 3. The executable is a tagged value, and the wrapper renders it

`packages/personal-omp.nix` receives `ompRuntime` and renders one shell word in one place:

```text
absolute     -> "<path>"
homeRelative -> "$HOME/<relative>"
```

Both forms are double-quoted, and the rendered text for the two current hosts is byte-identical to the current wrapper text. `passthru.ompExecutable` keeps its name and now holds the rendered word, so the existing `grep -qF` checks keep working, and `passthru.ompRuntime` exposes the structured value.

`installCommand` stays a string. It is display text that the user runs by hand, and on Linux it names `$HOME` on purpose.

Alternative rejected: `types.either types.path types.str`. It types the status quo and still leaves the expansion rule implicit.

### 4. User-scope modules read `osConfig.host`

`modules/home/omp.nix` reads `osConfig.host.ompRuntime`. `modules/home/darwin/zed.nix` drops its `username` argument and uses `config.home.profileDirectory`, which Home Manager derives from `useUserPackages`; the evaluated string is unchanged. `extraSpecialArgs` becomes `{ inherit inputs; }`.

Alternative rejected: forward `config.host` through `extraSpecialArgs`. It is another untyped forwarding layer, and `osConfig` is the mechanism Home Manager provides for this purpose.

### 5. Shared Home Manager wiring in `modules/fleet/home-manager.nix`

The fleet module sets `useGlobalPkgs`, `useUserPackages`, `backupFileExtension`, and `extraSpecialArgs`. Each platform module imports its Home Manager module and sets the complete `users.<name>.imports` list for its platform.

The platform module owns the complete list rather than appending `../home/darwin` to a shared `[ ../home ]`. Two definitions of one list option merge in module order, and a changed order of `home.packages` propagates into the generation derivation, as `split-home-modules-by-platform` measured. One definition per host keeps the list order fixed and the gate clean.

### 6. Binary cache as shared data in `modules/shared/binary-caches.nix`

The file exports `{ substituters; trustedPublicKeys; }`. `modules/darwin/nix.nix` places them in `determinateNix.customSettings.extra-*`, `modules/nixos/nix.nix` in `nix.settings.extra-*`. `korolevNixSettings` becomes a per-system `hostNixSettings` check that reads the data file and asserts against `nix.settings` on NixOS and `determinateNix.customSettings` on Darwin.

The option paths differ per platform, so a module cannot set both; data is the right shape. The literal in `.github/workflows/check.yml` and the literal command in the WSL runbook stay: the runner has no Nix before the action installs one, and the runbook command is for a machine that has neither host configuration. Each carries a comment that names the data file as the source.

### 7. A check proves the declaration rejects

`packages/host-declaration-check.nix` evaluates `modules/fleet/host.nix` with `lib.evalModules` against fixtures: a declaration that omits `username`, a declaration whose executable is a bare string, a declaration whose `absolute` value is relative, and one complete declaration of each tag. Each rejection is observed through `builtins.tryEval (builtins.deepSeq value true)`, and the accepted fixtures render to the expected shell words. The check follows `air-batch-config-check.nix`: Nix assertions, then a `runCommand` that touches `$out`. It runs on every system because it depends on nothing platform-bound.

### 8. Acceptance gate: identical system derivations with the revision pinned

Both hosts expose `extendModules`. The gate evaluates each host's `config.system.build.toplevel.drvPath` at the parent commit and at the final revision with `system.configurationRevision` forced to one constant on both sides, and requires equality. This is stronger than the closure diff, because it compares the derivation that would be built, byte for byte, and it runs from the Linux host for both systems.

If the derivation paths differ, the change is not accepted until the difference traces to an evaluated cause and the `nvd` closure diff on each host reports no package added, removed, or changed in version, as the precedent gate did.

`flake.lock` does not change while the change is open.

## Risks / Trade-offs

- \[Portable user-scope modules now require `osConfig`\] → Both hosts run Home Manager as a system module and the accepted specification describes that model. The `korolevHomeGeneration` check evaluates the user scope from within the host and keeps passing. A standalone Home Manager evaluation is a stated non-goal.
- \[A shallow `tryEval` passes an invalid `absolute` value\] → The check forces every fixture with `deepSeq`, and one fixture exists for exactly this case.
- \[`packages.personal-omp` now evaluates the host configuration\] → The checks for that system already evaluate it, so the total evaluation work of `nix flake check` is unchanged. A bare `nix build .#personal-omp` evaluates more than before.
- \[Two `imports` definitions could reorder `home.packages`\] → Decision 5 gives each platform module one complete list.
- [The CI and runbook literals can drift from the data file] → Both are outside evaluation by necessity. The comments name the data file, and the `hostNixSettings` check catches drift between the data file and either host.
- \[`attrTag` error text is less familiar than a plain type error\] → The message names the option path and the permitted tags, which is what the scenario requires.

## Migration Plan

1. Record the baseline: parent commit, `flake.lock` checksum, and both pinned-revision `toplevel.drvPath` values, in `baseline.md` in this change.
1. Land the refactor in the order of `tasks.md`, comparing the pinned-revision derivation paths after each group.
1. Run the repository gates on both systems.
1. Activation is not required, because the closure is unchanged. An activation on either host is a valid extra proof: `darwin-switch` prints an empty `nvd` diff, and `nixos-rebuild switch` registers a generation whose closure diff against the previous one is empty.

Rollback is a Git revert. No generation, no OMP-owned state, and no platform executable changes.
