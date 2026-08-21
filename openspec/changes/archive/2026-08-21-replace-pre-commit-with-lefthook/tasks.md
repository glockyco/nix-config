## 1. Establish the baseline

- [x] 1.1 Record the current Darwin job duration and its attribution, so the end state is compared against a number rather than an impression: 5 h 18 min wall clock, `dotnet-stage0-vmr` 100 min, `swift` 98 min, `dotnet-vmr` 92 min, everything else 15 min.
- [x] 1.2 Record which outputs reach the source toolchains today. For each attribute in `checks`, `packages`, and `devShells` on `aarch64-darwin`, resolve `drvPath` and count paths matching `dotnet-vmr`, `dotnet-stage0-vmr`, and `swift-5.10` in its derivation closure. Expect 5 for `checks.pre-commit`, 5 for `devShells.default`, and 0 everywhere else.
- [x] 1.3 Record that `lefthook` is substitutable for `aarch64-darwin` and `pre-commit` is not, with the build closure sizes, so the choice stays justified if either changes.

## 2. Add the new hook runner

- [x] 2.1 Add `lefthook.yml` at the repository root with one `pre-commit` job that runs the treefmt wrapper over staged files. It carries no formatter list, no file patterns, and no exclusions.
- [x] 2.2 Add `lefthook` and the treefmt wrapper built from `treefmt.nix` to the development shell packages. The hook invokes the wrapper by store path, not by a name resolved from `PATH`.
- [x] 2.3 Install the hook from the shell hook, so entering the shell installs it and re-entering it does not fail.
- [x] 2.4 Prove the gate: stage a file the formatter would rewrite and confirm the commit is rejected. Format it, commit again, and confirm it passes.

## 3. Remove the previous runner

- [x] 3.1 Remove all five `git-hooks-nix` touchpoints in `flake.nix`: the input, the flake module import, `pre-commit.settings.hooks.treefmt.enable`, `config.pre-commit.settings.enabledPackages`, and `config.pre-commit.shellHook`.
- [x] 3.2 Update `flake.lock` and confirm the removed input takes its transitive inputs with it.
- [x] 3.3 Confirm `checks.aarch64-darwin` no longer lists `pre-commit` and still lists `treefmt`, and that `nix flake check` passes on both systems.
- [x] 3.4 Remove the hook the previous runner installed in this working tree, re-enter the shell, and confirm exactly one hook runs on commit.

## 4. Verify the source-free requirement

- [x] 4.1 Add a flake app that enumerates `checks`, `packages`, and `devShells` for the current system from the flake itself, so an output added later is covered without editing the app.
- [x] 4.2 Walk each output's derivation closure and fail when it reaches a source-built .NET package or a Swift compiler. Report the output name and the dependency path that reaches it, not a bare exit code.
- [x] 4.3 Scope the app to Darwin. On Linux these packages are cached and their plans legitimately contain the source build, so the same assertion there would fail for the wrong reason.
- [x] 4.4 Add the positive control: a package whose Darwin plan is known to reach the source toolchain must still be detected. Fail the run when the control is not detected, so an upstream rename cannot turn the app into a check that always passes.
- [x] 4.5 Prove the app fails on a real regression. Add a dependency that reaches the source toolchain, confirm the failure names the output and the path, and revert.
- [x] 4.6 Prove the control fails. Break detection so it matches nothing, confirm the run fails as unreliable, and revert.

## 5. Wire it into continuous integration

- [x] 5.1 Add the verification as its own step in `.github/workflows/check.yml`, after `nix flake check`, on the macOS runner, following the file's one concern per step style.
- [x] 5.2 Confirm the Linux job is unchanged.

## 6. Confirm the outcome

- [x] 6.1 Re-run the measurement from task 1.2 and confirm every output reports 0.
- [x] 6.2 Confirm the Darwin job compiles neither toolchain, and record the new duration against the 5 h 18 min baseline.
- [x] 6.3 Update `docs/architecture/personal-omp-environment.md` where it describes the hook mechanism for this repository. Leave `docs/plans/` alone. The `consolidate-planning-home` change owns those files.
