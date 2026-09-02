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
- Keep the built Darwin system store path identical.
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

### 2. Prove equality with two evaluated store paths

The refactor is acceptable only when two store paths stay identical: the complete Darwin system and the Home Manager activation package. Evaluate both before the first edit, and evaluate both again after the last edit.

Evaluation is as strong as a build here. A store path is the hash of the derivation inputs, so an identical path proves identical inputs. Evaluation also runs on either supported host, while an `aarch64-darwin` build runs only on the Mac.

`modules/darwin/system.nix` sets `system.configurationRevision` from the flake revision, and that value enters the system derivation. A measured probe confirmed the consequence: one appended newline in a tracked file changed the system store path, because the revision took its dirty form. The system gate therefore pins that one option.

```sh
nix eval --raw '.#darwinConfigurations.macbook-pro' \
  --apply 'c: (c.extendModules { modules = [ ({ lib, ... }: { system.configurationRevision = lib.mkForce "gate"; }) ]; }).system.outPath'
```

The Home Manager gate needs no pin, because the activation package carries no revision.

```sh
nix eval --raw '.#darwinConfigurations.macbook-pro.config.home-manager.users.glockyco.home.activationPackage.outPath'
```

The second gate is the tighter one, because every edit in this change reaches the user scope. The first gate detects an accidental change in system scope.

**Alternative:** Compare the built system path without a pin. Rejected because the flake revision moves the path on every tracked edit and on every commit, so the comparison can never succeed.

**Alternative:** Add a flake output for the pinned system. Rejected because the gate serves one change, and a new output would remain in the repository after the change is archived.

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

- **A module classified as portable holds a hidden macOS assumption.** The store-path gate does not detect this, because the Darwin host still imports every module. Mitigation: the verification spike already built four portable modules on `x86_64-linux`, and `adopt-nixos-wsl-host` builds the complete portable set.
- **An input update moves both store paths.** Mitigation: evaluate the baseline immediately before the first edit, and run no input update during the change.
- **A verification step cannot run on the implementing host.** Both store-path gates evaluate on `x86_64-linux`, but `nix run .#check-darwin-build-plans` is a Darwin-only flake output, and `nix flake check` realizes the Darwin system only on Darwin. Mitigation: name those two steps as Mac-only, and complete them before the change is archived.
- **`catppuccin` and `zed` resist a clean class.** Both hold portable settings and a host-specific package. Mitigation: leave both at `modules/home/` and treat their package selection as host scope. `adopt-nixos-wsl-host` decides the Linux package.

## Migration Plan

1. Record both baseline store paths.
1. Create `modules/home/darwin/` and move the 14 Darwin-only modules with `git mv`.
1. Split `default.nix` into a portable import list and a Darwin import list.
1. Move the Git identity and the editor value to `hosts/macbook-pro/`.
1. Extend the `moduleImports` check and add a rejected fixture for a nested unimported module.
1. Compare both store paths with the recorded values.
1. Update the `README.md` layout description.

Rollback is a normal commit revert. The change activates no generation and mutates no external service.
