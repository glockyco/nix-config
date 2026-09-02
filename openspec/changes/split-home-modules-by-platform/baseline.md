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
| Same package set                                    | `home.packages`, `map (p: p.name)`      | 34 both sides, sorted sets identical                  |
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
