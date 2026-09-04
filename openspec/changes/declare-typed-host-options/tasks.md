## 1. Baseline

- [x] 1.1 Record the parent commit, the SHA-256 of `flake.lock`, and the current wrapper text of `packages.<system>.personal-omp` for both systems in `baseline.md`, and confirm the file names the gate command from design decision 8.
- [x] 1.2 Evaluate `config.system.build.toplevel.drvPath` for both hosts at the parent commit with `system.configurationRevision` forced to one constant through `extendModules`, record both values in `baseline.md`, and confirm that a second evaluation of the same commit returns the same values.

## 2. Host Declaration

- [x] 2.1 Add `modules/fleet/host.nix` with the options from design decision 1 and `modules/fleet/default.nix` that imports it, and confirm that `nix eval` of a fixture through `lib.evalModules` returns a complete declaration for each executable tag.
- [x] 2.2 Add `packages/host-declaration-check.nix` with the fixtures from design decision 7 and wire it as `checks.hostDeclaration` on every system, and confirm that `nix build .#checks.<system>.hostDeclaration` passes on `x86_64-linux`.
- [x] 2.3 Confirm that the check rejects, with a temporary probe that removes the `deepSeq` from the relative-`absolute` fixture and observes the check fail, then revert the probe.

## 3. Hosts Declare Themselves

- [x] 3.1 Move `username` and `ompRuntime` from the flake table into `hosts/macbook-pro/default.nix` and `hosts/korolev/default.nix` as `host.*` definitions, set `host.name` from the table's `name`, import `../../modules/fleet`, and reduce `specialArgs` to `{ inherit inputs; }`; confirm that both hosts evaluate `config.host` to the values the table held.
- [x] 3.2 Replace every `hostname` and `username` function argument in `modules/darwin/` and `modules/nixos/` with `config.host.name` and `config.host.username`, and confirm that no file under `modules/darwin/` or `modules/nixos/` declares one of the four retired arguments.
- [x] 3.3 Confirm that a host which omits `host.username` fails evaluation with a message that names `host.username`, with a temporary probe that the task reverts.

## 4. Structured Executable

- [x] 4.1 Change `packages/personal-omp.nix` to receive `ompRuntime`, render the shell word in one place as design decision 3 states, keep `passthru.ompExecutable` as the rendered word, and add `passthru.ompRuntime`; confirm that the wrapper text for both systems is byte-identical to the text recorded in `baseline.md`.
- [x] 4.2 Make `perSystem` in `flake.nix` read `hostConfiguration.config.host.ompRuntime` for `packages.personal-omp` and `hostConfiguration.config.host.username` where a check locates the user's Home Manager configuration, and confirm that `packages.<system>.personal-omp.drvPath` is unchanged for both systems.
- [x] 4.3 Confirm that a host whose executable is a bare string fails evaluation with a type error that names `host.ompRuntime.executable`, with a temporary probe that the task reverts.

## 5. User Scope Reads the Host

- [x] 5.1 Make `modules/home/omp.nix` read `osConfig.host.ompRuntime` and drop its `ompExecutable` and `ompInstallCommand` arguments, and confirm that the user's `home.packages` still carries `personal-omp` with an unchanged derivation path on both hosts.
- [x] 5.2 Replace the hardcoded profile path in `modules/home/darwin/zed.nix` with `config.home.profileDirectory` and drop its `username` argument, and confirm that the rendered Zed settings file is unchanged.
- [x] 5.3 Add `modules/fleet/home-manager.nix` with the shared settings from design decision 5 and `extraSpecialArgs = { inherit inputs; }`, reduce each platform `home-manager.nix` to its Home Manager module import and its complete `users.<name>.imports` list, and confirm that both hosts evaluate the same `home-manager.useGlobalPkgs`, `useUserPackages`, and `backupFileExtension` values as before.
- [x] 5.4 Confirm that `home.packages` of each host has the same names in the same order as at the parent commit, by comparing `map (p: p.name)` across `git+file://$PWD?rev=<parent>` and the working tree.

## 6. Shared Binary Cache Declaration

- [x] 6.1 Add `modules/shared/binary-caches.nix` and export it from `modules/shared/default.nix`, make `modules/darwin/nix.nix` and `modules/nixos/nix.nix` read it, and confirm that `nix.settings.extra-substituters` and `extra-trusted-public-keys` on `korolev` and `determinateNix.customSettings` on `macbook-pro` evaluate to the values they held before.
- [x] 6.2 Replace `korolevNixSettings` with a per-system `hostNixSettings` check that reads the data file and asserts against the host of that system, and confirm that `nix flake check` passes on `x86_64-linux` and lists `hostNixSettings`.
- [x] 6.3 Confirm that the check rejects, with a temporary probe that changes one character of the declared key in the data file alone and observes `hostNixSettings` fail, then revert the probe.
- [x] 6.4 Add a comment beside the literal in `.github/workflows/check.yml` and beside the literal command in `docs/operations/wsl-omp-bootstrap.md` that names `modules/shared/binary-caches.nix` as the source, and confirm that no other file under `modules/` or `flake.nix` carries the URL or key as a literal.

## 7. Verify the Complete Change

- [ ] 7.1 Run `nix fmt -- --fail-on-change`.
- [ ] 7.2 Run `nix flake check --print-build-logs` on `x86_64-linux` with the Nix the host declares, and confirm that `moduleImports`, `hostDeclaration`, and `hostNixSettings` are among the passing checks.
- [ ] 7.3 Evaluate both pinned-revision `toplevel.drvPath` values as in task 1.2 against the working tree, confirm that both equal the values in `baseline.md`, and record the result in `baseline.md`; if either differs, trace the difference to an evaluated cause and record the `nvd` closure diff for that host before continuing.
- [ ] 7.4 Confirm that `flake.lock` is unchanged from the parent commit.
- [ ] 7.5 Run `nix flake check --print-build-logs`, `nix build .#darwinConfigurations.macbook-pro.system`, and `nix run .#check-darwin-build-plans` on the Darwin host, and record in `baseline.md` that `hostDeclaration` and `hostNixSettings` passed there.
- [ ] 7.6 Run `openspec validate declare-typed-host-options --strict`.
- [ ] 7.7 Review the final diff and confirm that `specialArgs` and `extraSpecialArgs` name `inputs` alone in every file, that no module declares `hostname`, `username`, `ompExecutable`, or `ompInstallCommand` as an argument, and that the flake table rows hold `kind` and `name` alone.

## 8. Documentation

- [ ] 8.1 Add the changed invariants to the architecture decision log: one typed host declaration read through `config.host` and `osConfig.host`, and one declaration per shared fact; confirm that the entry names the date and the two invariants.
- [ ] 8.2 Update the `modules/` rows of the README layout table to name `modules/fleet/` and the shared cache data, and confirm that `nix fmt -- --fail-on-change README.md` passes.
