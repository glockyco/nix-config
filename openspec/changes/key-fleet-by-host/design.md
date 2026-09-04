## Context

See `proposal.md` for the motivation. The facts that shape the approach:

- `declare-typed-host-options` and `connect-fleet-over-tailnet` are archived when this change starts. Each host declares `options.host` from `modules/fleet/host.nix`, `hosts/<name>/default.nix` sets its own identity, `specialArgs` carries `inputs` alone, and the flake reads `hostConfiguration.config.host`. `packages/personal-omp.nix` receives `ompRuntime` and exposes `passthru.ompRuntime` and `passthru.ompExecutable`. `packages/host-declaration-check.nix` and the per-system `hostNixSettings` check exist. Every machine has a MagicDNS name, and korolev can build Darwin outputs on the Mac through `nix.buildMachines`.
- The flake table binds a system to `{ kind; name; }` (`flake.nix:92-113`), `systems` is its key set (`flake.nix:116`), and `perSystem` reads `host = hosts.${system}` (`flake.nix:159`). `withSystem` hands the per-system package set to each hand-written configuration (`flake.nix:126-142`). `pkgs` is `inputs.nixpkgs.legacyPackages.${system}.extend self.overlays.default` (`flake.nix:171`), and `_module.args.pkgs = pkgs` (`flake.nix:220`) replaces the flake-parts default. flake-parts declares that default with `lib.mkOptionDefault` in its `nixpkgs.nix` module, so the override is the documented mechanism.
- flake-parts' `easyOverlay` module builds `overlays.default` by re-evaluating `perSystem` with `prev` as `pkgs`, and it defines `final` as `pkgs.extend overlays.default`, which is a second nixpkgs evaluation. The pinned revision is `427bf4bd9435fdf21321c8cc628c24efc14c0f7a`.
- `self.darwinConfigurations.macbook-pro.system` and `self.darwinConfigurations.macbook-pro.config.system.build.toplevel` evaluate to the same derivation, `59hsvhnv2i5yv4m3iim8wmc6whn193yx-darwin-system-26.05.c3e90c8.drv`, measured on `x86_64-linux` at `96e005f`.
- `inputs.nix-darwin.packages` publishes `darwin-rebuild` for the two Darwin systems only. On `x86_64-linux` it publishes `manpages`, `manualHTML`, and `optionsJSON`. `herdr` and `openspec` from `inputs.llm-agents` declare `meta.platforms` that include both fleet systems.
- `flake.lock` holds three `flake-parts` nodes. `flake-parts` belongs to `determinate/nix`, `flake-parts_2` is this flake's input, and `flake-parts_3` belongs to `llm-agents`. `personal-omp-plugin` declares `llm-agents` and `nixpkgs` as its only inputs, so it has no `flake-parts` input to follow. The `llm-agents` flake at the locked revision declares `flake-parts` only to forward it to `bun2nix`, and it consumes `bun2nix` through `inputs.bun2nix.overlays.default` applied to its own package set.
- `packages/module-imports-check.nix` takes one root and asserts, for every directory that holds a `default.nix`, that each sibling `.nix` file appears in that list. `packages/check-darwin-build-plans.nix` reads the attribute names of `checks`, `packages`, and `devShells` from the flake, so a generated output is covered without an edit.
- `packages/air-batch-check-tests.nix` and `packages/container-runtime-check-tests.nix` drive their programs through shell doubles and need `coreutils` and `runtimeShell` only. Both are declared under the Darwin host condition today (`flake.nix:460-464`).
- `writeShellApplication` accepts `meta` and `passthru` as arguments. `mkDerivation` removes both from the derivation attributes, so neither enters the derivation path. `packages/personal-omp.nix` and `packages/container-runtime-check.nix` add `passthru` through `overrideAttrs` instead.
- `personalOmpShape` asserts one literal, `path=("/etc/profiles/per-user/${host.username}/bin"`, against the user's `programs.zsh.initContent` (`flake.nix:275-276`). `modules/home/shell.nix:12-15` renders that line from `config.home.profileDirectory` because nix-homebrew prepends its prefix in `/etc/zshrc`. `separate-platform-baseline-from-roles` moves that fragment to a Darwin-only module.
- `lefthook.yml` declares one `pre-commit` job that runs `treefmt`. `.github/workflows/check.yml` runs `nix flake check` on both legs, builds the Linux host's Nix first, and runs `check-darwin-build-plans` on macOS. Its comment names `darwinSystem`.
- `docs/operations/dependency-updates.md` states that `glockyco/dependency-automation` is the only automated writer of `flake.lock`.

## Goals / Non-Goals

**Goals:**

- One host table keyed by name. A second host on a system is one row and one directory.
- Every host output and every host gate generated from that table, with no host or user literal outside `hosts/`.
- Each repository package instantiated once per system, consumed as `pkgs.<name>`, and checked as the derivation the host installs.
- Program checks that run the program, kept beside the program.
- A flake that a reviewer can read one output family at a time.
- Both system derivations unchanged by the change, up to the configuration revision.

**Non-Goals:**

- Any change to what a check asserts about a host, beyond replacing a source-text assertion with a behavioral one. The isolation, container-runtime, login-shell, and Nix-settings assertions keep their content.
- Roles, identity literals in `modules/`, and the Python programs. Those belong to `separate-platform-baseline-from-roles` and `package-user-programs`.
- The Windows check, which `derive-windows-check-from-declaration` owns. This change routes `modules/windows` through the overlay and changes nothing inside it.
- A third host. The structure admits one, and `fleetSurface` proves the table and the directories agree, but no row is added.
- The version of Nix on the macOS runner. The accepted requirement names the implementation, and both the runner and the Darwin host run Determinate Nix.
- Automated lock updates. `dependency-automation` owns them.

## Decisions

### 1. The host table is a typed flake-parts option keyed by host name

`flake-modules/hosts.nix` declares:

```text
fleet.hosts.<name>.system   types.str
fleet.hosts.<name>.kind     types.enum [ "darwin" "nixos" ]
```

and defines the two rows. `systems = lib.unique (lib.mapAttrsToList (_: row: row.system) config.fleet.hosts)`. A misspelled kind fails at evaluation with the option path and the two permitted values, which is the scenario the spec names.

Alternative rejected: keep the table as a `let` binding. A `let` has no type, and the other flake modules could not read it without a second copy.

Alternative rejected: derive the table from `builtins.readDir ./hosts` and read `system` and `kind` from a file inside each directory. The flake needs `system` before it can evaluate the host, so the file would be a second module format with one purpose. The explicit table plus the directory assertion in decision 4 is the boring form.

### 2. Configurations are generated by kind, and a host directory is a plain module

`flake.darwinConfigurations` is `lib.mapAttrs` over the rows with `kind == "darwin"`, and `flake.nixosConfigurations` over the rows with `kind == "nixos"`. Each entry is:

```text
withSystem row.system ({ pkgs, ... }:
  <builder> {
    specialArgs = { inherit inputs; };
    modules = [
      { nixpkgs.pkgs = pkgs; host.name = name; }
      ../hosts/${name}
    ];
  })
```

where `<builder>` is `inputs.nix-darwin.lib.darwinSystem` or `inputs.nixpkgs.lib.nixosSystem`. `hosts/<name>/default.nix` becomes a plain module. It imports its platform list, `../../modules/darwin` or `../../modules/nixos`, and defines `host.username`, `host.ompRuntime`, and the per-machine Home Manager values. The generator sets `host.name` from the table key, so the name has one declaration.

The host file imports its own platform list rather than receiving it from the generator. The host is the place that says what a machine is, and `separate-platform-baseline-from-roles` adds role imports to the same list.

Alternative rejected: keep `hosts/<name>/default.nix` as a function that calls the builder itself. That leaves the builder call, the `nixpkgs.pkgs` line, and `specialArgs` in every host file, which is the duplication that generation removes.

Alternative rejected: derive the builder from `lib.systems.elaborate row.system`. A Linux system could carry a non-NixOS configuration in principle, and the explicit kind is what the enum validates.

### 3. `perSystem` receives the hosts of its system and generates the host outputs

`flake-modules/hosts.nix` sets `perSystem._module.args.hostConfigurations` to an attribute set, keyed by host name, of `{ kind; configuration; }` for every row whose `system` equals the current system. `configuration` is `self.darwinConfigurations.<name>` or `self.nixosConfigurations.<name>`. The per-host outputs are one `lib.concatMapAttrs` over that set:

| Output                                          | For          | Reads                                                                                                                |
| ----------------------------------------------- | ------------ | -------------------------------------------------------------------------------------------------------------------- |
| `checks.<name>-system`                          | every host   | `configuration.config.system.build.toplevel`                                                                         |
| `checks.<name>-home`                            | every host   | `configuration.config.home-manager.users.<username>.home.activationPackage`                                          |
| `checks.<name>-nix-settings`                    | every host   | the shared cache data against the host's settings, as `hostNixSettings` does today                                   |
| `checks.<name>-login-shell`                     | every host   | `programs.zsh.enable`, `users.users.<username>.shell`, `environment.shells`, and on Darwin the profile line in `zsh` |
| `checks.<name>-personal-omp`                    | every host   | `packages/personal-omp-tests.nix` applied to the wrapper the host installs, decision 8                               |
| `packages.<name>-personal-omp`                  | every host   | the same wrapper                                                                                                     |
| `checks.<name>-isolation`                       | NixOS hosts  | the `korolevIsolation` assertions                                                                                    |
| `checks.<name>-container-runtime`               | NixOS hosts  | the `korolevContainerRuntime` assertions                                                                             |
| `checks.<name>-air-batch-configuration`         | Darwin hosts | `packages/air-batch-config-check.nix` with the user's Home Manager configuration                                     |
| `checks.<name>-container-runtime-configuration` | Darwin hosts | `packages/container-runtime-config-check.nix` with the user's Home Manager configuration                             |

`<username>` is `configuration.config.host.username` in every row. `<name>-system` reads `config.system.build.toplevel` on both kinds, which the Context records as the derivation that `.system` aliases on Darwin. The Darwin profile-line assertion of `<name>-login-shell` reads `home.profileDirectory` rather than a literal, and it applies to Darwin hosts only, because the fragment exists for nix-homebrew and `separate-platform-baseline-from-roles` moves it to a Darwin module.

The names use the host name as a prefix and a hyphen, so `nix flake show` groups a host's gates together and a renamed host changes exactly those names. The kind-scoped rows carry the assertions that `korolev*` and the Darwin `on...Host` blocks carry today, with the host bound by the generator instead of by a `let`. `separate-platform-baseline-from-roles` may re-scope the two Darwin configuration checks from kind to role.

Alternative rejected: keep camel-case names such as `korolevSystem` with the host name interpolated. `${name}System` produces `macbook-proSystem`, and a hyphenated host name has no camel-case form.

Alternative rejected: one check per system that asserts every host of that system in one derivation. A failure would then name the system rather than the host, and `check-darwin-build-plans` would report one output where several exist.

### 4. `fleetSurface` proves the table and the host directories agree

The check asserts three things and reads no `checks` attribute:

- The sorted directory names under `hosts/`, read with `builtins.readDir`, equal the sorted keys of `fleet.hosts`.
- `self.devShells.${system}` has `default`.
- Every host on the system reports that system as `configuration.pkgs.stdenv.hostPlatform.system`.

After decision 2, "the table names every configuration" holds by construction, so the old comparison of name lists would be a tautology. A host directory with no row is the mistake that structure cannot prevent, and it is the one the check now reports, with the directory name in the assertion message.

Alternative rejected: keep the name-list comparison. It cannot fail after generation.

### 5. `flake.nix` splits into five flake-parts modules under `flake-modules/`

| File                          | Owns                                                                                                                                                                               |
| ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `flake-modules/hosts.nix`     | `fleet.hosts`, `systems`, the generated configurations, `hostConfigurations`, the per-host outputs, `fleetSurface`                                                                 |
| `flake-modules/packages.nix`  | `_module.args.pkgs`, `overlays.default`, `perSystem.packages`, and `darwin-rebuild` for a system with a Darwin host                                                                |
| `flake-modules/checks.nix`    | the host-independent checks: `moduleImports`, `moduleImportsCommand`, `hostDeclaration`, `openspecContracts`, `windowsConfiguration`, `airBatchCommand`, `containerRuntimeCommand` |
| `flake-modules/devshell.nix`  | `devShells.default`                                                                                                                                                                |
| `flake-modules/formatter.nix` | the `treefmt-nix` import and `treefmt = import ../treefmt.nix pkgs`                                                                                                                |

`flake-modules/default.nix` imports the five, and `flake.nix` imports `./flake-modules`. `flake.nix` keeps the description, the inputs, and the `mkFlake` call. The `moduleImports` check runs on `./flake-modules` as well as `./modules`, so a flake module that its `default.nix` omits fails the same way a host module does.

Each file answers one reviewer question: which hosts exist, which packages exist, which repository gates exist, what the shell carries, and how formatting is configured. The host file is the largest because it is the one that changes when a host is added. The formatter file is small, but it is where the `treefmt-nix` flake module is imported, and the import belongs beside its configuration.

Alternative rejected: one `flake-modules/outputs.nix`. That moves 500 lines and answers no question.

Alternative rejected: split by system, with one module per platform. Nothing in the flake is platform-specific after this change. The platform-bound outputs are generated from the table or filtered by `meta.platforms`.

Alternative rejected: a `flake-modules/` without `default.nix`, listed from `flake.nix`. That places the list outside the directory that the `moduleImports` rule covers.

### 6. Keep `_module.args.pkgs`, delete the stale comment, reject `easyOverlay`

`flake-modules/packages.nix` keeps `_module.args.pkgs = inputs.nixpkgs.legacyPackages.${system}.extend self.overlays.default` and drops the comment at `flake.nix:218-219`, which describes a Darwin path that no longer exists. flake-parts declares its own default with `lib.mkOptionDefault` for exactly this override.

`easyOverlay` is rejected. Its `final` argument is `pkgs.extend overlays.default`, a second nixpkgs evaluation per system, and its overlay re-runs `perSystem` for every consumer of `overlays.default`. Both contradict the one-instance-per-system requirement that `unify-fleet-flake-outputs` accepted.

### 7. The overlay is the package inventory, and exports follow `meta.platforms`

`overlays.default` in `flake-modules/packages.nix` becomes:

```text
final: _prev: {
  air-batch-check           = final.callPackage ../packages/air-batch-check.nix { };
  check-darwin-build-plans  = final.callPackage ../packages/check-darwin-build-plans.nix { };
  container-runtime-check   = final.callPackage ../packages/container-runtime-check.nix { };
  module-imports-check      = final.callPackage ../packages/module-imports-check.nix { };
  neo-keyboard-layouts      = final.callPackage ../packages/neo-keyboard-layouts.nix { };
  windows-configuration     = final.callPackage ../modules/windows { };
  herdr                     = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.herdr;
  openspec                  = inputs.llm-agents.packages.${final.stdenv.hostPlatform.system}.openspec;
  personal-omp-plugin       = inputs.personal-omp-plugin.packages.${final.stdenv.hostPlatform.system}.default;
}
```

An attribute name equals the file basename, so `packages/<attr>.nix` is `pkgs.<attr>`. The three re-exports pin the fleet's `herdr`, `openspec`, and plugin to the flake inputs, and an attribute of the same name in nixpkgs is overridden on purpose. `modules/home/darwin/ssh.nix` and `modules/home/darwin/container-runtime.nix` drop their `callPackage` and read `pkgs.air-batch-check` and `pkgs.container-runtime-check`.

`perSystem.packages` is the overlay's attribute names, taken from `pkgs`, filtered with `lib.meta.availableOn pkgs.stdenv.hostPlatform`. The names come from `builtins.attrNames (self.overlays.default pkgs pkgs)`, which forces no value. `neo-keyboard-layouts` declares `lib.platforms.darwin` and therefore disappears from the Linux set through the filter, which removes the `onDarwinHost` branch and its comment. `darwin-rebuild` cannot enter the overlay, because nix-darwin publishes no such package for `x86_64-linux`. It stays in `packages.nix` and in the shell behind the condition "a Darwin host lives on this system", read from `hostConfigurations`. That is the workflow condition from `unify-fleet-flake-outputs` decision 3, now derived from the table rows rather than from one host.

The program checks `airBatchCommand` and `containerRuntimeCommand` move to `flake-modules/checks.nix` without a platform condition. Both run their program against shell doubles, so they pass on Linux, and running them there covers the Linux leg of CI too.

Alternative rejected: build the overlay from `builtins.readDir ./packages`. The directory holds `*-tests.nix` and `*-config-check.nix` files that are not packages, so the rule would need a naming convention that a reader cannot see in the overlay.

Alternative rejected: a second hand-written list for `perSystem.packages`. Two lists drift, and the overlay is already the list.

Alternative rejected: keep the kind branch for `neo-keyboard-layouts`. `meta.platforms` already states the fact, and the filter is what the existing comment says the branch stands in for.

### 8. The wrapper is a Home Manager option, and the flake reads it per host

`modules/home/omp.nix` declares:

```text
programs.personal-omp.package   types.package
  default = pkgs.callPackage ../../packages/personal-omp.nix { ompRuntime = osConfig.host.ompRuntime; }
```

`callPackage` resolves `herdr` and `personal-omp-plugin` from the package set, so `packages/personal-omp.nix` renames its `plugin` argument to `personal-omp-plugin` and drops `pkgs` in favor of the packages it names. The module's `home.packages` reads `config.programs.personal-omp.package`, its `verifyPersonalOmp`, and `pkgs.openspec`, and its activation entry reads the option's `reconcileHerdrOmp`. The flake reads `configuration.config.home-manager.users.<username>.programs.personal-omp.package` for `packages.<name>-personal-omp` and for `checks.<name>-personal-omp`, and the check asserts that the same derivation is an element of the user's `home.packages`. The check therefore exercises the derivation the host installs, by identity rather than by equal arguments.

The wrapper is host-specific because `ompRuntime` is, so it cannot be one overlay attribute of a package set that two hosts on one system share.

Alternative rejected: `personal-omp = final.callPackage ../packages/personal-omp.nix { }` in the overlay with `ompRuntime` left for `.override`. `callPackage` wraps the call in `makeOverridable`, which forces the result to attach `override`, and a required argument that is missing fails at that force. `pkgs.personal-omp.override` cannot recover from it.

Alternative rejected: an overlay attribute with a placeholder `ompRuntime` default. A wrapper with a placeholder executable is a derivation that no host installs, and the check would exercise it.

Alternative rejected: no option, with the check locating the wrapper in `home.packages` by `pname`. A name match is not an identity, and a second package named `omp` would satisfy it.

### 9. `packages/personal-omp-tests.nix` exercises the wrapper, the verifier, and the reconciler

The file takes `personal-omp` and the build tools it needs, and it follows `container-runtime-check-tests.nix`: doubles written into `$TMPDIR`, calls recorded through environment variables, one `runCommand`. It contains:

- Delegation. Run the wrapper with a stub in the executable's place. The stub records `$*`. Assert the record is `--extension <plugin> --plugin-dir <plugin>/lsp` followed by the caller's arguments, and that the stub saw every language server on `PATH` by recording `PATH` and checking each server's `bin` directory.
- Absence. Run the wrapper with no executable at the declared location. Assert exit status 1 and a message that names the rendered location and the declared installation command.
- Location rendering. Run `personal-omp.override { ompRuntime.executable.homeRelative = "omp-stub"; }` under `HOME=$TMPDIR/home` with a stub at that relative path, and assert the stub ran. Run `personal-omp.override { ompRuntime.executable.absolute = "/dev/null/omp"; }` and assert the absence message names that path. Both tags are therefore exercised on every system, and the host's own wrapper is exercised with the branch its tag selects.
- Plugin payload. The `package.json`, `lsp.json`, `commands/opsx-propose.md`, and `lsp/commands` assertions from `personalOmpShape`, unchanged, because they assert files of the plugin input rather than the wrapper's text.
- The `personalOmpVerification` and `herdrOmpReconciliation` scenarios, moved verbatim.

The `grep` assertions over the wrapper's script text are deleted, and so is the `openspec --version` assertion, which compared an upstream package with itself. `<name>-home` builds the generation that carries `openspec`.

Alternative rejected: keep the greps beside the behavioral tests. A grep that passes proves nothing that the delegation run does not prove, and a grep fails on a harmless rewrite of the script.

Alternative rejected: a host-independent test that builds its own fixtures only. The check would then never touch the wrapper a host installs, which is the coupling the proposal exists to establish.

### 10. Every package declares `meta`, passed as an argument

Each `writeShellApplication` receives `meta = { description; mainProgram; platforms; }` and, where it has one, `passthru` as direct arguments. The `overrideAttrs` wrappers in `packages/personal-omp.nix` and `packages/container-runtime-check.nix` disappear. `windows-configuration` is a `runCommand` without a program, so it declares `description` and `platforms` only. The platforms are `lib.platforms.unix` for every program and `lib.platforms.darwin` for `neo-keyboard-layouts`. `check-darwin-build-plans` is `unix` because it skips itself on Linux by design.

`meta` and `passthru` do not enter the derivation, so the acceptance gate is unaffected.

Alternative rejected: `lib.platforms.darwin` for `air-batch-check` and `container-runtime-check`. Both build and run on Linux, and their doubles-driven checks are worth running on the Linux leg. Where a host installs them is a module decision, not a package fact.

### 11. One `follows`, gated by unchanged derivations

Add `llm-agents.inputs.flake-parts.follows = "flake-parts"`. `llm-agents` forwards `flake-parts` to `bun2nix` and evaluates none of its own outputs through it, and `bun2nix` enters `llm-agents` as an overlay over the `llm-agents` package set. The change removes the `flake-parts_3` node and changes no input revision. The gate is that `herdr`, `openspec`, and the plugin have the same `drvPath` on both systems before and after the edit, and that both pinned-revision system derivations stay equal to the baseline. If either differs, the `follows` is reverted and a comment beside the input records the measured reason.

`personal-omp-plugin.inputs.flake-parts.follows` is not added. The lock shows that input has no `flake-parts` input, and Nix warns about a `follows` for an input that does not exist. The audit lead was wrong on that point. The `flake-parts` node under `determinate/nix` is two levels deep and stays.

`llm-agents.inputs.nixpkgs.follows` stays absent, for the reason the comment at `flake.nix:67-68` records.

Alternative rejected: leave the duplicate. The edit is one line and the gate is cheap.

### 12. No `pre-push` hook

`lefthook.yml` keeps its one `pre-commit` job. `nix flake check` builds both host closures through `<name>-system` and `<name>-home`, which takes minutes on either host, and a push hook that takes minutes is the hook that `--no-verify` retires. The remote gate runs the identical check set with the host's Nix on both legs within minutes of the push, and `AGENTS.md` lists `nix flake check` among the release gates that run before a merge. A hook that duplicates the remote gate at a fraction of its reliability adds a second place where the gate command lives.

Alternative rejected: a `pre-push` job that runs a cheap subset, such as `moduleImports`, `hostDeclaration`, and `openspecContracts`. The subset is a list of checks kept in `lefthook.yml`, which is the pattern the formatting requirement forbids for formatters, and it would drift from `checks` as checks are added.

Alternative rejected: `pre-push` with the full `nix flake check`. See above.

### 13. Acceptance gate: identical system derivations with the revision pinned

The gate is the one `declare-typed-host-options` established. Evaluate `config.system.build.toplevel.drvPath` for both hosts at the parent commit and at each step, with `system.configurationRevision` forced to one constant through `extendModules`, and require equality. Record the values in `baseline.md`. The `nvd` closure diff on each host is the fallback when a path differs and the difference traces to an evaluated cause.

Two steps can move the path by design and are measured separately. Decision 8 adds a Home Manager option in the user scope. Home Manager renders option documentation for the modules in its submodule type, not for modules that `imports` adds, so the option is expected to render nowhere. Decision 11 edits `flake.lock`. The rule "no input revision changes while the change is open" replaces the rule that the lock does not change.

## Risks / Trade-offs

- \[Two hosts on one system share `pkgs`, so a host cannot override an overlay package for itself\] → That is the accepted one-instance requirement. A host-specific package is a Home Manager option, as decision 8 shows for the wrapper.
- \[`readDir ./hosts` makes `fleetSurface` depend on the working tree layout\] → The path is a flake source path, not a build input, and the check reads names only.
- \[`builtins.attrNames (overlay pkgs pkgs)` applies the overlay a second time\] → The application produces an attribute set of thunks and forces none of them. No derivation is evaluated twice.
- \[The generated names reorder `nix flake check` output\] → `check-darwin-build-plans` reads names from the flake, and the workflow comment is updated to name `<host>-system`.
- [The new option could enter the rendered option documentation and move the system derivation] → Decision 13 measures the step alone. If it moves, `unify-fleet-flake-outputs` accepted a documentation-only difference with the closure diff as proof, and the same standard applies.
- \[`follows` for `llm-agents` changes the `lib` that `bun2nix`'s flake evaluates with\] → Decision 11 gates the edit on unchanged derivation paths and reverts otherwise.
- \[Running `airBatchCommand` and `containerRuntimeCommand` on Linux adds two builds to the Linux leg\] → Both are seconds of shell against doubles, and the Linux leg gains coverage it lacks today.
- \[`programs.personal-omp.package` reads `osConfig`, so a standalone Home Manager evaluation fails\] → `declare-typed-host-options` already made the portable modules depend on `osConfig.host`, and standalone evaluation is a stated non-goal there.
- [A host directory that a row names but that does not exist] → Evaluation of that configuration fails at the import with the path in the message, which is the same signal as today.

## Migration Plan

1. Record the baseline: parent commit, `flake.lock` checksum, both pinned-revision `toplevel.drvPath` values, and the `drvPath` of `herdr`, `openspec`, the plugin, and both wrappers, in `baseline.md`.
1. Split `flake.nix` into `flake-modules/` with no semantic change, and confirm the derivation paths.
1. Introduce the typed table, the generators, the plain host modules, and `hostConfigurations`. Confirm the derivation paths.
1. Extend the overlay, add `meta`, and make the modules consume `pkgs.<name>`. Confirm the derivation paths.
1. Add `programs.personal-omp.package`, `packages/personal-omp-tests.nix`, and the per-host outputs. Delete the inline checks. Confirm the derivation paths.
1. Update `fleetSurface`, the flake description, and the workflow comments.
1. Add the `follows`, and confirm the package derivation paths and the system derivation paths.
1. Run the repository gates on both systems. A Darwin-only check can be built from korolev through the remote builder that `connect-fleet-over-tailnet` configured.
1. Update the documentation.

Activation is not required, because the closure is unchanged. Rollback is a Git revert. No generation, no OMP-owned state, and no platform executable changes.
