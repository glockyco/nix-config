## Why

The two hosts describe themselves with four bare strings. `hosts/macbook-pro/default.nix` and `hosts/korolev/default.nix` each unpack `hostname`, `username`, `ompExecutable`, and `ompInstallCommand` from the flake table and pass them as `specialArgs`. `modules/darwin/home-manager.nix` and `modules/nixos/home-manager.nix` copy the same four names into `extraSpecialArgs`. Eleven files then declare one or more of them as function arguments. `specialArgs` bypass the module system: the values have no type, no default, no merge, and no `mkIf`, and a missing or misspelled value fails as `attribute missing` inside a consumer rather than at the declaration.

The 2026-09-04 audit found the consequences. `ompRuntime.executable` is an absolute path on Darwin and the shell fragment `$HOME/.local/lib/oh-my-pi/omp` on Linux (`flake.nix:107`). Nothing records that the wrapper expands it, so `lib.escapeShellArg` on the value would break the WSL host while the Darwin host kept working. `modules/home/darwin/zed.nix:21` receives `username` for one purpose: to spell `/etc/profiles/per-user/${username}/bin/omp`, which `config.home.profileDirectory` already provides. The Numtide cache URL and public key are literals in `modules/darwin/nix.nix`, `modules/nixos/nix.nix`, and the `korolevNixSettings` check, so a key rotation is three edits with no check that they agree. The two `home-manager.nix` files are identical except for one import line, and they have already drifted in comments.

This is the first of the planned structural changes. The later changes, which key the host table by name, build each package once through the overlay, and split platform baselines from roles, all consume a host declaration. That declaration has to exist and be typed first.

## What Changes

- Add a module that declares `options.host` with `lib.types`: `name`, `username`, and `ompRuntime` with a structured `executable` and an `installCommand`. The executable is a tagged value that names either an absolute path or a path relative to the user's home directory.
- Move each host's identity values from the flake table into `hosts/<name>/default.nix` as `config.host` definitions. The flake table keeps only the binding of a system to a host kind and name.
- Pass `inputs` alone through `specialArgs`. Every system-scope module reads `config.host.*`, and every user-scope module reads `osConfig.host.*`.
- Render the wrapper's executable shell word in `packages/personal-omp.nix` from the structured value, so the expansion rule lives beside the code that depends on it.
- Replace the hardcoded per-user profile path in `modules/home/darwin/zed.nix` with `config.home.profileDirectory`.
- Declare the Home Manager wiring that both platforms share in one module under `modules/fleet/`. Each platform module imports its Home Manager module and adds only what differs.
- Declare the Numtide substituter and its public key once as shared data. Both Nix modules and the `korolevNixSettings` check read that data.
- Add a check that evaluates the host module in isolation and proves that it rejects a declaration with a missing value, rejects an executable that is neither tag, and accepts a complete declaration.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `repository-quality-gates`: requires one typed host declaration per host that the module system validates, and requires each fact that both platforms share to have one declaration that both platform scopes and their checks consume.

## Impact

The change affects `flake.nix`, `hosts/macbook-pro/default.nix`, `hosts/korolev/default.nix`, `packages/personal-omp.nix`, every module under `modules/darwin/` and `modules/nixos/` that currently declares one of the four arguments, `modules/home/omp.nix`, `modules/home/darwin/zed.nix`, `modules/shared/default.nix`, and a new `modules/fleet/` directory.

It changes no host behavior. The acceptance gate is a closure diff of both system derivations against the parent commit, as `split-home-modules-by-platform` established: no package added, removed, or changed in version, and every differing derivation traced to an evaluated cause. `flake.lock` does not change while the change is open.

Explicit non-goals: the Darwin `trusted-users` entry, the `computerName` literal, the `/home/<user>` restatement, the second instantiation of `personal-omp` in `modules/home/omp.nix`, and the system-keyed host table. Each changes behavior or belongs to a later planned change, and this change leaves each as it is.
