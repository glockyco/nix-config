## Context

See `proposal.md` for motivation and `specs/repository-quality-gates/spec.md` for the contract.

### Measured state

An audit of the flake surface on 2026-09-03 produced these facts. They decide the approach below.

| Output group                                                        | `aarch64-darwin`                       | `x86_64-linux`       |
| ------------------------------------------------------------------- | -------------------------------------- | -------------------- |
| `formatter`, `checks.treefmt`                                       | present                                | present              |
| `checks.moduleImports`, `moduleImportsCommand`, `openspecContracts` | present                                | present              |
| `packages.openspec`, `packages.personal-omp`                        | present                                | present              |
| `devShells.default`                                                 | present                                | **absent**           |
| Host proof checks                                                   | `darwinSystem` and three Darwin checks | six `korolev` checks |
| Platform-bound packages                                             | five                                   | none                 |

| Property                            | Observed value                                                                                 |
| ----------------------------------- | ---------------------------------------------------------------------------------------------- |
| Commit hook in the `korolev` clone  | absent; 13 commits passed no formatting gate                                                   |
| `pkgs` on `aarch64-darwin`          | `self.darwinConfigurations.macbook-pro.pkgs`                                                   |
| `pkgs` on `x86_64-linux`            | `inputs.nixpkgs.legacyPackages.x86_64-linux.extend self.overlays.default`                      |
| `korolev` host package set          | a second instance from `nixosSystem`, without the overlay                                      |
| `nix flake check` at `f24e147`      | passed on `ubuntu-latest` under Determinate Nix 3.22.1, failed on `korolev` under `nix-2.34.8` |
| `korolev` declared Nix              | `nix-2.34.8` through `config.nix.package`                                                      |
| Package-set options in host modules | `nixpkgs.hostPlatform` and `nixpkgs.overlays` in `modules/darwin/system.nix` only              |

The two package sets on `x86_64-linux` produce equal derivations today, because both use the default configuration and the overlay only adds an attribute. That equality is a coincidence of the current content, not a property of the structure.

### Measured result

A comparison across the change, with `system.configurationRevision` pinned to one value on both sides so that the commit itself does not move the hash, reports these differences and no others.

| Compared value                                  | Result                                                                                                              |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| Home Manager generation, both hosts             | identical derivation                                                                                                |
| Package and shell attribute names, both systems | unchanged, plus `devShells.default` on `x86_64-linux` and `checks.fleetSurface` on both                             |
| Development shell contents, `aarch64-darwin`    | the same six packages, in a different order                                                                         |
| System closure, both hosts                      | differs only in the rendered option documentation, and in the `etc` and `system-path` derivations that reference it |

The documentation moves because an option's declaration site moved: `nixpkgs.pkgs` now arrives from an inline module, and two declarations left `modules/darwin/system.nix`.

## Goals / Non-Goals

**Goals:**

- Give every supported system the outputs that the repository's own workflow needs.
- Make an output asymmetry unrepresentable where structure can express the invariant.
- Give the flake one package-set instance per system, consumed by the host and the outputs.
- Make the gate mean the same thing on a host and on that host's continuous-integration leg.

**Non-Goals:**

- Change what either host installs, activates, or runs.
- Change the formatter set, the file patterns, or the exclusions. `treefmt.nix` keeps that ownership.
- Unify the two Nix implementations across the fleet. Decision 9 of the architecture record keeps Determinate Nix on Darwin and the system Nix on NixOS.
- Add a third host or a third system.

## Decisions

### 1. Feed the hosts from the per-system package set

Instantiate one package set for each system in `perSystem`, and hand it to both hosts through `withSystem` and `nixpkgs.pkgs`.

Today the arrow points the wrong way and points differently per system. The Darwin outputs read the host's package set, so evaluating one package drags in a host evaluation. The Linux outputs build their own set, and the NixOS host builds a third. One instance per system, flowing outward, removes both the fork and the duplicate.

The current comment claims that nixpkgs is evaluated once and that the outputs cannot drift from the host. This decision makes that claim true on both systems instead of on one.

`nixpkgs.pkgs` fixes the platform and the overlay list, so `nixpkgs.hostPlatform` and `nixpkgs.overlays` leave `modules/darwin/system.nix`. Both hosts then declare no package-set options, and the overlay is applied where it is declared.

**Alternative:** Give both systems an independent package set and keep the hosts self-instantiating. Rejected because it leaves two instances per Linux system and keeps drift possible.

**Alternative:** Keep the host-derived package set on both systems, reading `self.nixosConfigurations.korolev.pkgs` on Linux. Rejected because every output then depends on a host evaluation, and a system without a host can expose nothing.

### 2. Declare repository-development outputs unconditionally

Declare `formatter`, the repository checks, and `devShells.default` with no platform condition.

The first instinct was a parity check that reads `self.devShells` and `self.checks`. That check introspects the same attribute set it belongs to, which is a recursion hazard, and it guards a mistake that structure can prevent instead. An unconditional declaration cannot express the asymmetry that this change exists to remove.

An assertion stays only where a human can still choose wrongly and structure cannot prevent it. That is decision 4.

The implementation keeps one narrow assertion for the shell, in `checks.fleetSurface`. It reads `self.devShells.${system}`, which is a different output attribute, so it forces no part of `checks` and needs no self-reference. Its purpose is a later edit that reintroduces a platform condition, not the state this change leaves behind.

**Alternative:** Assert the presence of every required check as well. Rejected because a member of `checks` cannot read `checks` for its own system without forcing the attribute set it belongs to.

### 3. Split the development shell by workflow, not by convenience

Put the repository tools in the shared package list: Git, the hook runner, the formatter wrapper, and the pinned interpreter. Put a host tool behind a platform condition when its workflow cannot complete on the other host.

`darwin-rebuild` activates the Darwin host. `dnscontrol` exists for `x86_64-linux`, and its configuration in this repository needs the decrypted credential that `modules/home/darwin/secrets.nix` supplies through sops. The WSL host declares no secret, so that tool would be present and unusable there. A tool that cannot complete its workflow is worse than an absent one, because it moves the failure from shell entry to the middle of an operation.

The shell hook keeps installing the commit hook, because the accepted requirement names shell entry as the installation point.

**Alternative:** One shell with an identical package list on both systems. Rejected because it either drops the Darwin activation and DNS workflows or ships an unusable tool.

**Alternative:** A second named shell for the host tools. Rejected because two shells need a name, a document, and an entry decision for a two-host repository, and the shared-list-with-condition form is the common Nixpkgs idiom.

### 4. Replace the platform booleans with one host binding table

Map each supported system to its host configuration and its kind in one table, and derive the host proof checks and the shell's host tools from it.

`isDarwin` and `isLinux` re-derive which host lives on a system from a string, separately, at every definition site. That is why four asymmetries arrived as four separate failures during the cutover. With the table, the fleet shape is stated once, and a third host is one entry.

Derive `systems` from the table with `builtins.attrNames`, so "the table covers `systems`" becomes a property of the code rather than a claim a check has to make. A supported system with no host, and a host on a system that no gate covers, both become unrepresentable.

One assertion remains, because the table can still fall behind a new host. The check asserts that the table names every configuration under `darwinConfigurations` and `nixosConfigurations`, and that the host for the current system reports that system as its platform. It reads the table and the host attribute names, not the output set it belongs to, so it needs no self-reference. It matches the assertion style of the existing `korolevIsolation` and `korolevNixSettings` checks, which carry no rejecting counterpart either.

**Alternative:** Keep the booleans and document the rule. Rejected because the four failures are the evidence that a documented rule does not hold.

### 5. Run each continuous-integration leg with its host's Nix

Build the Nix that the host declares, and run the gate with it on the leg for that system.

`nix flake check` is implementation-sensitive. The same revision passed under Determinate Nix 3.22.1 on `ubuntu-latest` and failed under `nix-2.34.8` on `korolev`, because the two implementations disagree about a package whose `meta.platforms` excludes the system. The Darwin leg is already correct, because the runner and the host both use Determinate Nix. Only the Linux leg needs the pinned Nix, which `nixosConfigurations.korolev.config.nix.package` names exactly.

The workflow already states the sibling rule: one runner per system in `systems`. This adds its missing half.

**Alternative:** Write outputs that pass under the strictest implementation and keep one runner Nix. Rejected because the strictest reading is not knowable in advance, which makes it a hope rather than a gate.

**Alternative:** Install Determinate Nix on the WSL host. Rejected because it reverses an accepted decision to work around a symptom, and NixOS-WSL owns `/etc/nix/nix.conf` on that host.

## Risks / Trade-offs

- **`nixpkgs.pkgs` rejects a host module that still declares package-set options.** Mitigation: the audit found those options in one file only, and the change removes both lines in the same commit. Evaluation fails loudly rather than silently ignoring them, which the spec requires.
- **Feeding the host from `perSystem` inverts the evaluation direction, so a mistake in the overlay now reaches both hosts.** Mitigation: the host closure builds are already flake checks on both systems, so the failure appears in review.
- **The Darwin development shell loses nothing, but its package list is now conditional, and a future portable tool may be added to the wrong list.** Mitigation: the condition names host workflows rather than systems, and the spec scenario states the rule.
- **Building the pinned Nix on the Linux leg adds a step that can fail on its own.** Mitigation: the substituters serve that closure, and a failure is a real signal that the pinned Nix is unavailable.
- **The change touches the shared flake, so a defect affects both hosts rather than one.** Mitigation: the release gates run on both systems, and the Darwin host keeps its previous generation until its gates pass.

## Migration Plan

1. Instantiate the per-system package set and hand it to both hosts; remove the two package-set options from the Darwin system module.
1. Declare the development shell for every system, with the shared list and the host tools.
1. Introduce the host binding table, derive the host proof checks from it, and delete the platform booleans.
1. Add the table-consistency check.
1. Give the Linux continuous-integration leg the host's Nix.
1. Record the commit-hook installation step in the runbook.
1. Run the release gates on both systems, and confirm that the commit hook installs on the WSL host.

Rollback is a revert of the flake commit, because no host state changes. The previous generation on each host stays selectable throughout.
