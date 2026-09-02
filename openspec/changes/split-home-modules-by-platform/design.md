## Context

See `proposal.md` for motivation.

`README.md` states that `hosts/` owns one directory for each machine, `modules/darwin/` owns system scope, and `modules/home/` owns user scope. The Darwin host obeys that model. `modules/darwin/home-manager.nix` imports `../home` as one unit, so every module applies to macOS and only to macOS.

A direct inspection of all 26 modules produced this classification.

| Class          | Count | Modules                                                                                                                                                                                              |
| -------------- | ----- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Portable       | 10    | `shell`, `cli`, `git`, `gh`, `ghq`, `packages`, `nix-index`, `omp`, `typst`, `tex`                                                                                                                   |
| Darwin-only    | 14    | `apple-terminal`, `brave`, `container-runtime`, `darwin-switch`, `default-apps`, `fastmail`, `ghostty`, `karabiner`, `keyboard-shortcuts`, `network-shares`, `neo2`, `screenshots`, `secrets`, `ssh` |
| Host-dependent | 2     | `catppuccin`, `zed`                                                                                                                                                                                  |

The Darwin-only class is not a matter of taste. Each module names a macOS interface: `launchd.agents`, `osascript`, `duti` and LaunchServices, `~/Library` paths, an `NSKeyedArchiver` font blob, `com.apple.symbolichotkeys`, the Secretive agent socket, a Homebrew-supplied binary, or `darwin-rebuild`.

A verification spike built the portable subset `shell`, `cli`, `git`, and `ghq` as a standalone Home Manager generation for `x86_64-linux`. The build succeeded, which confirms that the portable class is real.

## Goals / Non-Goals

**Goals:**

- Create a platform boundary inside `modules/home/`.
- Keep the Darwin closure free of any package, version, or option change.
- Move host-specific values out of portable modules.
- Extend the module-import check to the new directories.

**Non-Goals:**

- Add a Linux host, a Linux home configuration, or a new flake input.
- Change any package selection, option value, or activation script.
- Resolve the `catppuccin` and `zed` host-dependent modules beyond what the boundary requires.
- Edit `docs/architecture/personal-omp-environment.md`, which the active `consolidate-planning-home` change owns.

## Decisions

### 1. Split by directory rather than by conditional

Move the 14 Darwin-only modules to `modules/home/darwin/`. Keep the portable modules at `modules/home/`. Let `modules/home/default.nix` import the portable set, and let the Darwin path import the `darwin/` set.

**Alternative:** Guard each Darwin-only module with `lib.mkIf pkgs.stdenv.isDarwin`. Rejected because `default-apps.nix` alone holds about 380 lines of LaunchServices logic that says nothing on Linux. A conditional hides the boundary instead of declaring it.

### 2. Prove equality with a closure diff, not with a store path

A store path is input-addressed, so it encodes the concatenation order of every list-valued option. `imports` order therefore reaches the hash. A directory split necessarily reorders `home.packages`, so a store-path comparison rejects the refactor itself instead of testing its behavior. Measurement confirmed this: the split kept the same 34 packages and moved 6 of them in the list, which changed `home-manager-path`, `home-manager-fonts`, `home-manager-applications`, the fonts-version file, the activation script that names them, and therefore the system path.

This repository already owns the correct instrument. `modules/home/darwin/darwin-switch.nix` wraps `darwin-rebuild switch` because *"it reports that it activated a generation, but not what actually changed"*, and it answers that question with `nvd diff`. A closure diff compares packages and versions, so a pure reorder reports no change.

The acceptance gate is therefore a closure diff on the Mac, between the system built from the parent commit and the system built from this change.

```sh
nvd diff <pre-refactor-system> <post-refactor-system>
```

The gate passes when the diff reports no added package, no removed package, and no version change.

Four evaluated invariants run on either host, and they precede the closure diff because they need no Darwin build. Each one already holds for this change.

| Invariant                                                              | Command shape                            |
| ---------------------------------------------------------------------- | ---------------------------------------- |
| `home.packages` holds the same set                                     | compare `map (p: p.name)` as sorted sets |
| `home.file` declares the same targets                                  | compare `builtins.attrNames`             |
| `home.activation` declares the same entries                            | compare `builtins.attrNames`             |
| Every remaining derivation difference traces to the package list order | compare the differing activation texts   |

`buildEnv` receives `ignoreCollisions = false`, and a collision depends on the package set rather than its order. The current Mac already builds that set, so the reordered set cannot collide either, and the built tree stays identical.

**Alternative:** Compare store paths, with the flake revision pinned so that a dirty tree does not move them. Rejected because the comparison still fails on a legitimate reorder. The pin removes one false failure and leaves the real one.

**Alternative:** Keep one flat import list and guard each Darwin-only module with `lib.mkIf`. Rejected in decision 1 on its own merits, and rejected again here because adopting it to hold a hash steady would contort the source to satisfy the measurement.

**Alternative:** Sort `home.packages` so that module order cannot reach the hash. Rejected because it changes an option value, which this change excludes, and because it also serves the measurement rather than the behavior. It may deserve its own change.

### 3. Move the Git identity to host scope

`modules/home/git.nix` sets `user.email` to the GitHub no-reply address for every consumer. That value is correct for the personal Mac and wrong for a work host, where the global address must stay `johann.glock@scch.at`.

Keep the portable behavior in the module: `delta`, Git LFS, `init.defaultBranch`, `pull.rebase`, `push.autoSetupRemote`, and `core.autocrlf`. Move `user.name` and `user.email` to the host.

**Alternative:** Keep the identity in the shared module and override it per host. Rejected because an override leaves two declarations of one fact and hides which host wins.

### 4. Replace the hard-coded editor

`modules/home/gh.nix` sets `editor = "zed --wait"`. That names an application rather than a role, and it is false on a host without Zed.

Set `EDITOR` in host scope and let the GitHub CLI module read it.

### 5. Extend the module-import check

The `moduleImports` check asserts that every module has an import in its sibling `default.nix`. It reads one directory level, so a module inside `modules/home/darwin/` would escape it.

Extend the check to nested directories. An unimported module must remain a check failure rather than a silent absence.

## Risks / Trade-offs

- **A module classified as portable holds a hidden macOS assumption.** Neither the closure diff nor the evaluated invariants detect this, because the Darwin host still imports every module. Mitigation: the verification spike already built four portable modules on `x86_64-linux`, and `adopt-nixos-wsl-host` builds the complete portable set.
- **An input update changes the closure.** Mitigation: record the baseline immediately before the first edit, and run no input update during the change.
- **A verification step cannot run on the implementing host.** The four evaluated invariants run on `x86_64-linux`, but the closure diff, `nix run .#check-darwin-build-plans`, and the Darwin half of `nix flake check` all need the Mac. Mitigation: name those steps as Mac-only, and complete them before the change is archived.
- **`catppuccin` and `zed` resist a clean class.** Both hold portable settings and a host-specific package. Mitigation: leave both at `modules/home/` and treat their package selection as host scope. `adopt-nixos-wsl-host` decides the Linux package.

## Migration Plan

1. Record the baseline: the parent system path and the four evaluated invariants.
1. Create `modules/home/darwin/` and move the 14 Darwin-only modules with `git mv`.
1. Split `default.nix` into a portable import list and a Darwin import list.
1. Move the Git identity and the editor value to `hosts/macbook-pro/`.
1. Extend the `moduleImports` check and add a rejected fixture for a nested unimported module.
1. Confirm the four evaluated invariants, then run the closure diff on the Mac.
1. Update the `README.md` layout description.

Rollback is a normal commit revert. The change activates no generation and mutates no external service.
