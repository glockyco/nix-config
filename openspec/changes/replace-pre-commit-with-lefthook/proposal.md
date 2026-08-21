## Why

The Darwin CI job takes 5 hours 18 minutes, and 5 hours 2 minutes of that compiles the .NET SDK and the Swift toolchain from source. One test-only dependency causes it: `pre-commit` is not in the binary cache for `aarch64-darwin`, so it is built, and its `nativeCheckInputs` name `dotnet-sdk`. That resolves to the source build, which needs Swift. A formatter hook therefore compiles two toolchains to run tests this repository never reads.

The accepted specification already forbids this, but only for the wrapped OMP package, and nothing verifies the claim. The invariant is stated in one place, enforced by two hand-written overrides in `packages/personal-omp.nix`, and already broken one scope away.

## What Changes

- Replace `git-hooks-nix` and `pre-commit` with `lefthook` as the hook runner. `lefthook` is cached for `aarch64-darwin`, so it substitutes instead of building.
- Keep `checks.treefmt` as the formatting gate. It exists, its build plan is already free of both toolchains, and it reads the same `treefmt.nix` the hook will read, so the two cannot disagree.
- Widen the no-source-build requirement from the wrapped OMP package to every Darwin output this repository asks Nix to build.
- Verify that requirement automatically. Today a maintainer can only confirm it by reading a build plan by hand.
- **BREAKING**: the installed Git hook changes identity. A working tree that still has the `pre-commit` hook must have it removed, because an uninstalled runner leaves a hook file that fails or silently does nothing.

## Capabilities

### New Capabilities

- `repository-quality-gates`: how formatting is enforced before a commit and in CI, which configuration both read, and how the local hook is installed and removed.

### Modified Capabilities

- `darwin-dependency-builds`: the "Minimal managed language-server toolchain" requirement covers only the wrapped OMP package and is checked by inspection. It becomes a requirement over every Darwin output the repository builds, with automated verification.

## Impact

- `flake.nix`: five touchpoints. The `git-hooks-nix` input, the flake module import, `pre-commit.settings.hooks.treefmt.enable`, `config.pre-commit.settings.enabledPackages` in the dev shell, and `config.pre-commit.shellHook`.
- `flake.lock`: drops `git-hooks-nix` and the inputs it carries.
- New `lefthook.yml` at the repository root.
- `.github/workflows/check.yml`: gains the verification step for the widened requirement.
- Local working tree: the existing `.git/hooks/pre-commit` must be replaced.
- No change to what is formatted, or to the system closure. `checks.darwinSystem` and every other output already build without either toolchain.
