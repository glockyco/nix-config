# Acceptance baseline

The acceptance gate is a closure diff, not a store-path comparison. See design decision 2 for the reason.

| Item                 | Value                                                                     |
| -------------------- | ------------------------------------------------------------------------- |
| Parent commit        | `9222191b93ba5ebb4a0353061861491af037aa22`                                |
| `flake.lock` SHA-256 | `56bb25b6e102b743aa000896c5be167d30dce44cfb4a4ea8522f1107051ef4fa`        |
| Parent Darwin system | `/nix/store/3mpkbm920h23s6vqyw00c6llncyjqaqp-darwin-system-26.05.c3e90c8` |

## Acceptance gate, on the Mac

```sh
nvd diff /nix/store/3mpkbm920h23s6vqyw00c6llncyjqaqp-darwin-system-26.05.c3e90c8 <this-change-system>
```

The gate passes when the diff reports no added package, no removed package, and no version change. `modules/home/darwin/darwin-switch.nix` already uses `nvd diff` for the same question after every switch.

## Evaluated invariants, on either host

Each comparison uses the parent commit as the reference:

```sh
REV=9222191b93ba5ebb4a0353061861491af037aa22
BASE="git+file://$PWD?rev=$REV#darwinConfigurations.macbook-pro.config.home-manager.users.glockyco"
NOW=".#darwinConfigurations.macbook-pro.config.home-manager.users.glockyco"
```

| Invariant                                           | Applied to                              | Measured result                                       |
| --------------------------------------------------- | --------------------------------------- | ----------------------------------------------------- |
| Same package set                                    | `home.packages`, `map (p: p.name)`      | 35 both sides, sorted sets identical                  |
| Same file targets                                   | `home.file`, `builtins.attrNames`       | 23 both sides, identical                              |
| Same activation entries                             | `home.activation`, `builtins.attrNames` | 21 both sides, identical                              |
| Every derivation difference traces to package order | differing activation texts              | 3 entries differ, each only by a package-derived hash |

## Measured cause of the store-path difference

The split reorders `home.packages` because two import lists replace one. The set stays identical, and six packages change position: `air-batch-check`, `fastmail`, `darwin-switch`, `colima`, `docker`, and `container-runtime-check`.

That single change propagates:

```
home.packages order
  -> home-manager-path            buildEnv receives paths in list order
  -> home-manager-fonts           aggregate over the package list
  -> home-manager-applications    aggregate over the package list
  -> hm_LibraryFonts version file content derived from the package list
       -> activation script text  names the four paths above
            -> home-manager-files -> home-manager-generation -> darwin-system
```

The three activation entries that differ are `checkFilesChanged`, `copyApps`, and `onFilesChange`, and each differs only by one of those hashes.

`buildEnv` receives `ignoreCollisions = false`. A collision depends on the package set rather than its order, and the current Mac already builds that set, so the reordered set cannot collide and the built tree stays identical.

## Rule

`flake.lock` SHALL NOT change while this change is open. An input update changes the closure and invalidates the comparison.

## Result

Measured on `x86_64-linux` against the parent commit, with the refactor complete at `b0f91c59ee55`:

| Invariant                                           | Result                                                                                    |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| Same package set                                    | same, 35 both sides                                                                       |
| Same file targets                                   | same, 23 both sides                                                                       |
| Same activation entries                             | same, 21 both sides                                                                       |
| Every derivation difference traces to package order | only `checkFilesChanged`, `copyApps`, and `onFilesChange`, each by a package-derived hash |

The intended host-scope moves are present. `programs.git.settings.user` holds the same value from the host, `programs.gh.settings.editor` is empty so `gh` reads the environment, and `home.sessionVariables.EDITOR` is set.

`nix fmt -- --fail-on-change` exits 0. `nix flake check` exits 0 for `x86_64-linux` and reports 17 outputs, including `moduleImports` and `moduleImportsCommand`. The portable module set builds as a standalone Home Manager generation for `x86_64-linux`.

The Darwin system path at `b0f91c59ee55` is `/nix/store/49f89hn1n09d43gc9g84zar837cs9ycl-darwin-system-26.05.c3e90c8`. That value belongs to that revision only, because `system.configurationRevision` enters the derivation. The Mac gate SHALL build the system from the final revision of this change rather than reuse this path.

## Import check fixtures

The check runs against synthetic trees, so an empty result on the real tree means something. Six fixtures cover it:

| Fixture              | Expectation                                                       |
| -------------------- | ----------------------------------------------------------------- |
| accepted             | a nested tree with every module imported, and a data file ignored |
| accepted, large list | an early match followed by a list larger than the pipe buffer     |
| rejected, nested     | a module that its own nested list omits                           |
| rejected, root       | a module that the top-level list omits                            |
| rejected, comment    | an import that only appears inside a comment                      |
| usage                | a missing module-root argument                                    |

Two of those encode bugs that the first implementation had, and each was reproduced before the fix:

- Matching the raw file accepted a commented-out import, so disabling a module read as importing it.
- Piping into `grep -q` reported an imported module as missing once the list outgrew the pipe buffer. `grep -q` exits at its first match, the producer then takes SIGPIPE, and `pipefail` fails the pipeline. Restoring that form makes the large fixture report `portable.nix` as unimported although the list imports it on its third line.

The check now reads each list once per directory and matches with a shell pattern, so no pipeline carries the result.

## Darwin checks

Both ran on the Mac and passed.

`nix flake check` reported every `aarch64-darwin` output green, including `darwinSystem`, `moduleImports`, and `moduleImportsCommand`, and it named `x86_64-linux` as the omitted system. `nix run .#check-darwin-build-plans` reported 22 outputs, none reaching a source-built .NET package or a Swift compiler.

The `moduleImports` and `moduleImportsCommand` checks therefore pass on both supported systems.

## Outstanding, on the Mac

- `nvd diff` between the parent system and this change's system.

The parent reference is the `git+file:` form with an explicit revision. A line continuation in that command does not survive a paste into zsh, which splits it into an argument-free `nix build` and a second line that the shell tries to run. Assign the reference to a variable on its own line instead.
