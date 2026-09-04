## Why

The documentation describes a repository that no longer exists. The 2026-09-04 documentation audit found the drift, and every finding was re-verified against the current tree.

The architecture document names this repository `nix-darwin` in eleven places (`docs/architecture/personal-omp-environment.md:13,40-43,91,155,358,397,403,411,664,703`), and the accepted specification repeats the name (`openspec/specs/personal-omp-workstation/spec.md:11`). The repository is `nix-config` (`README.md:1`, `docs/operations/dependency-updates.md:9-10`). The current-state table (`personal-omp-environment.md:34-50`) marks `manage-omp-with-homebrew` and `manage-windows-layer` as `active`, but both are archived under `openspec/changes/archive/2026-09-04-*`. The Resume procedure (`personal-omp-environment.md:15-21`) tells a new session to open the active change from that table, so it routes work to archived changes. The document states that it owns no implementation tasks (`personal-omp-environment.md:11`) and then carries numbered `must` lists and acceptance criteria for four other repositories (`personal-omp-environment.md:448-586`).

The release gates are stated four times with drift: `AGENTS.md:24-29`, `README.md:59-64`, `docs/operations/container-runtime.md:101-105`, and three variants in `docs/operations/dependency-updates.md:106-130`. None names the Linux gate that CI runs with the host's Nix (`.github/workflows/check.yml:55-59`). The primary references pin OpenSpec v1.8.0 and OMP v17.2.15 (`personal-omp-environment.md:744-748`), while the WSL runbook records OpenSpec 1.11.0 and OMP 18.0.10 (`docs/operations/wsl-omp-bootstrap.md:490-491`).

Two planning homes exist. `docs/plans/INDEX.md` mixes one complete, two deferred, three draft, and two superseded records, `README.md:42,161` advertises it, and `AGENTS.md:9` says `openspec/changes/` owns active work. The change `consolidate-planning-home` was created on 2026-08-20 to resolve this and has 0 of 41 tasks complete. Its design creates five new active OpenSpec changes for unscheduled work, which the 2026-08-08 decision forbids (`personal-omp-environment.md:670`), and it blocks on a live Fastmail verification.

Three specification scenarios describe verification that no check performs. "Exercise the matrix" (`personal-omp-workstation/spec.md:66-71`) describes diagnostics, definition, references, and rename, while the check runs `command -v` for seven servers (`flake.nix:299-305`). "Generator output changes" (`spec.md:158-161`) describes a tracked adapter that this repository does not track, because the adapters ship in the plugin (`personal-omp-environment.md:321`). "Run a container" (`spec.md:258-262`) is backed by option assertions alone (`flake.nix:440-446`). `batch-ssh/spec.md:66-77` shows the accepted form: one daemon-free scenario for the check and one live scenario for the documented procedure.

The runbooks hold one-time evidence and finished cutover steps. `wsl-omp-bootstrap.md:79-105` and `:414-421` describe the `Ubuntu-26.04` cutover that archived task 7.5 of `adopt-nixos-wsl-host` completed, and `:477-495` records the accepted values of one release. `container-runtime.md:185-209` records digests and a checkpoint of another repository. `openspec/config.yaml` contains one setting and thirty lines of comments. The OpenSpec commands differ between `AGENTS.md:12`, `personal-omp-environment.md:19`, and the change task lists.

This is the last of the seven structural changes. The six earlier changes each added a decision-log entry and README rows for their own behavior. This change aligns everything else.

## What Changes

- Absorb `consolidate-planning-home`. Delete its directory, carry its intent into this change, and re-decide the fate of every record under `docs/plans/`. Superseded and complete records are deleted. Confirmed but unscheduled work moves to one GitHub issue per record in the owning repository. The tree and its index are deleted.
- Add a `planning-home` check with fixture tests that rejects a tracked file under `docs/plans/` and a current Markdown reference to that path.
- Rewrite the architecture document: rename every repository reference to `nix-config`, delete the current-state table and the Resume procedure, delete the per-change delivered-work subsections, move the four per-project migration plans to issues in their owning repositories and keep only the dependency order and the common contract, replace the version-pinned primary references with unversioned links, distinguish durable fleet hosts from the temporary Air research-results peer, and record the decisions of this session.
- Make `AGENTS.md` the one statement of the release gates, including the system that each gate runs on and the remote-builder path that `connect-fleet-over-tailnet` established. Every other document links to it. Unify the OpenSpec command forms across `AGENTS.md`, the architecture document, and change task lists.
- Rename `docs/operations/wsl-omp-bootstrap.md` to `docs/operations/korolev-provisioning.md`, delete the `Ubuntu-26.04` cutover and distribution-rollback steps, and move the accepted release evidence to `evidence.md` in the archived change `2026-09-03-adopt-nixos-wsl-host`. Move the container-runtime evidence to `evidence.md` in `2026-08-21-provide-colima-container-runtime`.
- Label the three prose-only specification scenarios as live procedures with a named documented home, remove the adapter-freshness requirement that has no subject in this repository, and name the Darwin build-plan gate in the `darwin-dependency-builds` scenario that says "the repository checks fail".
- Delete `openspec/config.yaml`. Confirm every path and check name in the `.github/workflows/check.yml` comments resolves. Remove the `docs/plans/` rows and links from `README.md`.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `repository-quality-gates`: adds the requirement that OpenSpec is the sole planning home and that repository validation rejects a second planning tree, and adds the requirement that the release gates have one statement in the agent entry point.
- `personal-omp-workstation`: names the repository `nix-config` in the pinned-inputs requirement, splits the language-server matrix and the WSL container runtime into one checked scenario and one live scenario each, and removes the generated-adapter freshness requirement.
- `darwin-dependency-builds`: names the Darwin build-plan gate as the gate that fails when an output gains a source-built toolchain.

## Impact

The change affects `AGENTS.md`, `README.md`, `docs/architecture/personal-omp-environment.md`, `docs/operations/wsl-omp-bootstrap.md` (renamed), `docs/operations/container-runtime.md`, `docs/operations/dependency-updates.md`, every file under `docs/plans/` (deleted), `openspec/config.yaml` (deleted), `openspec/changes/consolidate-planning-home/` (deleted), two archived changes that receive an `evidence.md`, the comments in `.github/workflows/check.yml`, and the three specifications named above. It adds `packages/planning-home-check.nix`, `packages/planning-home-check-tests.nix`, and one flake check.

It changes no host behavior, no module, no package that a host installs, and no input. Both system derivations are unchanged, and `flake.lock` does not change while the change is open. It creates issues in `glockyco/nix-config` and in the four project repositories that the architecture document names.

Explicit non-goals: the `~/.config/nix-darwin` checkout path in `modules/home/darwin/darwin-switch.nix:9` is code and stays as the earlier changes left it, and the README states whatever that module declares. The `flake.nix:2` description string and the check names in the workflow comments belong to `key-fleet-by-host`. The `WSL work machine` ownership section and the decision-log entry for the reversed `korolev` isolation decision belong to `connect-fleet-over-tailnet`, which archives before this change starts. This change verifies that both are present and consistent.
