## 1. One Package Set per System

- [x] 1.1 Instantiate the per-system package set in `perSystem` from the pinned nixpkgs and `overlays.default`, and confirm with `nix eval` that `packages.<system>.personal-omp.drvPath` matches the pre-change value on both systems.
- [x] 1.2 Hand that instance to both hosts through `withSystem` and `nixpkgs.pkgs`, and confirm that the system derivation path of each host matches its pre-change value.
- [x] 1.3 Remove `nixpkgs.hostPlatform` and `nixpkgs.overlays` from `modules/darwin/system.nix`, and confirm that the Darwin host still evaluates and still reports `aarch64-darwin`.
- [x] 1.4 Confirm that a host module which declares a package-set option the supplied instance already fixes fails evaluation, with a temporary probe that the task reverts.
- [x] 1.5 Confirm that the WSL host no longer instantiates a second package set, by comparing the host's `nixpkgs.pkgs` path with the flake's per-system instance.

## 2. A Development Shell on Every System

- [x] 2.1 Declare `devShells.default` with no platform condition, carrying the repository tools that any host needs, and confirm that `nix develop --command treefmt --version` succeeds on `x86_64-linux`.
- [x] 2.2 Keep the host-activation tools behind the host condition, and confirm by evaluation that the Darwin shell carries `darwin-rebuild` and `dnscontrol` while the Linux shell carries neither.
- [x] 2.3 Confirm that the Darwin shell's derivation still contains every package it carried before the change.
- [x] 2.4 Confirm on the WSL host that entering the shell installs `.git/hooks/pre-commit` and that the installed hook names the pinned runner.
- [x] 2.5 Confirm that the installed hook rejects a commit which carries an unformatted staged file, and that the working tree is left as it was.

## 3. One Host Binding Table

- [x] 3.1 Add the host binding table, derive `systems` from it, and confirm that `nix flake show` still exposes both systems.
- [x] 3.2 Replace every `isDarwin` and `isLinux` use with the table, and confirm that the package, check, and shell attribute names on both systems match their pre-change sets except for the additions this change makes.
- [x] 3.3 Add a check that asserts the development shell exists for the system, that the table names every declared host configuration, and that each table key matches its host's declared platform; confirm that `nix flake check` passes.
- [x] 3.4 Confirm that the check rejects, with a temporary probe that declares a host outside the table and that the task reverts.

## 4. Gate Equivalence

- [x] 4.1 Run the `x86_64-linux` continuous-integration gate with the Nix that the WSL host declares, and confirm the command sequence on the host before committing the workflow change.
- [x] 4.2 Confirm that the Darwin leg keeps Determinate Nix, which is the implementation its host runs, and that the build-plan step stays macOS-only.
- [x] 4.3 State in the workflow comment why each leg pins its Nix, next to the existing rule about one runner per system.

## 5. Documentation

- [x] 5.1 State in the runbook that entering the clone installs the commit hook, and that a host without the development shell has no local gate.
- [x] 5.2 Add the changed invariants to the architecture decision log: one package set per system for the host and the outputs, and one Nix implementation per gate.

## 6. Verify the Complete Change

- [x] 6.1 Run `nix fmt -- --fail-on-change`.
- [x] 6.2 Run `nix flake check --print-build-logs` on `x86_64-linux` with the Nix the host declares.
- [x] 6.3 Confirm that the Darwin system derivation path is unchanged by the whole change, which is the strongest available proof from a Linux host.
- [x] 6.4 Run `nix build .#darwinConfigurations.macbook-pro.system` and `nix run .#check-darwin-build-plans` on the Darwin host.
- [x] 6.5 Run `openspec validate unify-fleet-flake-outputs --strict`.
- [x] 6.6 Review the final diff by package set, shell, table, workflow, and documentation, and confirm that no output gained a platform condition that its workflow does not require.
