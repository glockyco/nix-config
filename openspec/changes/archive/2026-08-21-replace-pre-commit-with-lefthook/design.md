## Context

See proposal.md for motivation. The measurements that shape this design:

| Fact                                                          | Value                                                                               |
| ------------------------------------------------------------- | ----------------------------------------------------------------------------------- |
| Outputs whose Darwin build plan reaches the source toolchains | `checks.pre-commit` and `devShells.default` only                                    |
| Every other check, package, and the system closure            | free of both                                                                        |
| `nix flake check` realises                                    | `checks.*` only, so CI pays for the check and the shell cost lands on `nix develop` |
| `lefthook` on `aarch64-darwin`                                | cached, build closure 1098                                                          |
| `pre-commit` on `aarch64-darwin`                              | absent from the cache, build closure 2206                                           |
| Enabled hooks today                                           | one, `treefmt`                                                                      |

`checks.treefmt` already exists, is independent of the hook runner, and its build plan is clean.

The chain is `checks.pre-commit` to `pre-commit` to its `nativeCheckInputs` `dotnet-sdk` to `dotnetCorePackages.sdk_8_0`, which is the source build. The Swift toolchain is a dependency of that source build, not a separate cause. Removing the .NET source build removes Swift with it.

## Goals / Non-Goals

**Goals:**

- Remove both source toolchains from every Darwin build plan the repository asks for.
- Keep one configuration behind the commit gate and the CI gate.
- Make the source-free property fail a run rather than wait for someone to read a build plan.

**Non-Goals:**

- Hoisting the binary .NET scope from `packages/personal-omp.nix` into `overlays.default`. It would prevent a future recurrence at the source, but it changes package identity for every .NET consumer on the system and deserves its own change. The verification below makes a recurrence visible, which is the part missing today.
- A push-to-cache service. Roughly 15 minutes of the Darwin job is uncached small packages and Nix installation. That is a separate question from compiling two toolchains.
- Changing what is formatted. `treefmt.nix` is untouched.

## Decisions

### Lefthook replaces git-hooks-nix

Lefthook is a single cached Go binary. The measurement above is the reason: the current runner is absent from the Darwin cache, so it is built, and building it is what reaches the toolchains. `docs/architecture/personal-omp-environment.md` already names lefthook as the hook runner for this workstation, and `HotRepl/flake.nix` already uses `pkgs.lefthook` with a `lefthook.yml`. This aligns the repository with both.

Alternatives considered:

- **`pre-commit.overrideAttrs { doCheck = false; }`.** One line, removes the test inputs, keeps the current runner. Rejected because it keeps a package that upstream does not cache for this platform, so every nixpkgs bump rebuilds it, and because it leaves the repository as the only one on the workstation using a different hook runner.
- **Hoist the binary .NET scope into the overlay.** Fixes the dependency rather than the runner. Rejected as the primary fix for the reason under Non-Goals, and because it leaves an uncached Python application in the critical path.
- **A binary cache.** Turns a five hour build into a five hour build that happens once. It does not answer why a formatter hook compiles a .NET SDK.

### The CI formatting gate stays in `checks.treefmt`

A `nix flake check` derivation cannot run Git hooks. It has no working tree and no Git. Rather than add a second CI entry point that runs the hook, CI keeps the existing `checks.treefmt` derivation.

Both gates call the same treefmt wrapper built from `treefmt.nix`, so the formatter set cannot diverge. The gates differ only in scope: the hook formats staged files, the check reads the whole tree. That difference is intended.

Alternative considered: mirror HotRepl and add `nix run .#check` that runs `lefthook run pre-commit --force` in CI. Rejected as redundant here, because this repository has exactly one hook and `checks.treefmt` already covers it. Revisit if a hook that treefmt does not cover is added.

### The hook runs the pinned wrapper, never a name on `PATH`

`lefthook.yml` invokes the treefmt wrapper from the development shell. It does not name `treefmt` and hope. The architecture document states this rule for GUI-launched hooks, and this session found two sibling repositories that broke it by treating one executable on `PATH` as proof of an environment.

`lefthook.yml` carries no formatter list, no file patterns, and no exclusions. Those live in `treefmt.nix`. This is what keeps the two gates from disagreeing.

### The verification is an app, not a check, and it carries a positive control

A build plan cannot be inspected from inside a `nix flake check` derivation, because the sandbox has no store access and recursive Nix is experimental. The verification is therefore a flake app that CI invokes as its own step, next to `nix flake check`.

It enumerates `checks`, `packages`, and `devShells` for the current system from the flake itself, so an output added later is covered without editing the verification. For each it walks the derivation closure and fails on a source-built .NET package or a Swift compiler, naming the output and the path that reaches it.

It also asserts a known-positive case: a package whose Darwin plan is known to reach the source toolchain must still be detected. Without that control, an upstream rename turns the check into a mechanism that always passes and proves nothing. The control fails the run if detection stops matching.

## Risks / Trade-offs

- **A second configuration file could drift from `treefmt.nix`.** → `lefthook.yml` holds no formatter knowledge. It calls the wrapper. Drift has nowhere to live.
- **Lefthook may refuse to overwrite a hook it did not write.** → Migration removes the previous hook explicitly before the first install, and the spec requires that no hook from the previous runner survives.
- **Detection matches derivation names, which upstream can rename.** → The positive control fails the run when detection stops recognising a known case.
- **Dropping the input changes `flake.lock` beyond one line.** → `git-hooks-nix` has five touchpoints and no other consumer in this repository, all verified before the change.
- **The verification adds a CI step that can itself break.** → It runs after `nix flake check`, so a failure is attributable, and it names the output and dependency path rather than reporting a bare non-zero exit.

## Migration Plan

1. Land the flake change, `lefthook.yml`, and the verification app together. The repository has one maintainer and one working tree, so no coordination window is needed.
1. In the existing working tree, remove the hook the previous runner installed, re-enter the development shell, and confirm the new hook is installed and runs once.
1. Confirm the Darwin CI job no longer compiles either toolchain and record the new duration against the 5 hour 18 minute baseline.

Rollback is a revert of the commit plus restoring the previous runner's hook by re-entering the shell. No state outside the working tree changes.
