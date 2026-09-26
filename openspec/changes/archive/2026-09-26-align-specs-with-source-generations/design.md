## Context

The wrapper resolves `$HOME/.local/share/omp-dev/current` at run time and rejects `omp update` (`packages/personal-omp.nix:24-35,104-120`). The updater is a Nix-supplied command (`packages/omp-dev-update.nix:32-45`); activation only reconciles Herdr (`modules/home/omp.nix:24-36`). The host options have `name` and `username`, but no OMP executable option (`modules/fleet/host.nix:7-16`). The WSL procedure initializes OMP after Nix activation (`docs/operations/wsl-omp-bootstrap.md:99-112`).

## Goals / Non-Goals

**Goal:** Align accepted requirement ownership and OMP operations with the running declarations.

**Non-goals:** Change code, run host activation, or replace live acceptance evidence.

## Decisions

1. Modify all four affected `dependency-update-automation` requirements. Nix input automation and review gates stay intact. The explicit source-generation updater owns OMP selection and rollback; Nix rollback restores immutable integrations only (`README.md:84-122`; `docs/operations/dependency-updates.md:185-198`). An installer-owned model would conflict with the wrapper and updater.
1. Keep `One typed host declaration per host` but require `host.name` and `host.username` only. A consumer reads a typed option; omission fails evaluation, and no value travels as an untyped argument (`modules/fleet/host.nix:7-16`; `hosts/korolev/default.nix:25-32`; `modules/nixos/system.nix:8-12`). The alternative of retaining executable path scenarios would require nonexistent options.
   OpenSpec rejects a `MODIFIED` requirement that removes existing scenarios. Express the typed declaration cutover as an internal rename to `Obsolete typed host declaration`, removal of that temporary name, and addition under the original name. Archive applies rename, removal, then addition; the accepted requirement keeps its original name and drops only the obsolete scenarios.
1. Move these requirements to `wsl-host`: `Declarative WSL host configuration`, `WSL host activation and rollback`, `WSL host network isolation`, `Declared host defaults`, `Explicit WSL prerequisite boundary`, `Signed Linux binary cache`, `WSL-local mutable runtime state`, `Repository-specific Git identity`, `WSL release proof through a real session`, `Managed browser compatibility on WSL`, `On-demand authenticated browser relay`, and `Declarative WSL Windows interoperability` (`modules/nixos/default.nix:5-13`; `hosts/korolev/default.nix:20-64`). Correct installer wording in the prerequisite and browser scenarios. The `wsl-host` purpose names WSL provisioning and host acceptance.
1. Move `Container runtime on the WSL host` to `container-runtime` (`modules/nixos/containers.nix:2-16`). Move `OpenSpec package consistency`, `Generated OpenSpec adapter freshness`, and `Archived change completeness` to `repository-quality-gates` (`openspec/specs/personal-omp-workstation/spec.md:242-267`). Keep names and scenarios unless the current generation model makes a phrase false.
1. The destination specs have no same-named or equivalent requirement: `container-runtime` covers the Mac Colima runtime (`openspec/specs/container-runtime/spec.md:9-110`), and `repository-quality-gates` covers other repository gates (`openspec/specs/repository-quality-gates/spec.md:9-180`). `fleet-tailnet` governs tailnet policy and the Darwin builder (`openspec/specs/fleet-tailnet/spec.md:9-151`); `WSL host network isolation` additionally governs host services, local annotation, and its credential boundary. No moved requirement is deleted as a duplicate. Use full `REMOVED` entries with a reason and migration target.

## Risks / Trade-offs

The delta repeats moved text in two capability files until archive sync. Strict validation and a post-sync stale-term search guard the cutover. No live host verification is needed because this change alters contracts, not behavior.
