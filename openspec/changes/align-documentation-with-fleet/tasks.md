## Scheduling — 2026-09-05

This change is deferred, not canceled or completed. It is not a prerequisite for working OMP or Tailscale. [Near-term priorities](../../../docs/architecture/personal-omp-environment.md#near-term-priorities) govern scheduling.

Small acceptance-record corrections support the current OMP and Tailscale checks. They do not authorize these tasks, broad documentation or planning-store migration, issue creation, or deletion of `consolidate-planning-home`.

OpenSpec CLI counts describe artifact and task state, not scheduling authorization. All unchecked tasks remain preserved. Execution resumes only when a concrete maintenance or use requirement warrants it and the owner schedules and reviews the plan again. That review must reconcile the two planning-home plans before either proceeds.

## 1. Absorb `consolidate-planning-home`

- [ ] 1.1 Confirm that the six earlier programme changes are archived and that `consolidate-planning-home` is the only other active change, with `openspec list` printing `align-documentation-with-fleet` and `consolidate-planning-home` alone.
- [ ] 1.2 Delete `openspec/changes/consolidate-planning-home/` and confirm with `test ! -d openspec/changes/consolidate-planning-home` and an `openspec list` that prints this change alone.

## 2. Retire `docs/plans/`

- [ ] 2.1 Create the issue for the outstanding DMARC alias action in `glockyco/nix-config` with the label `planning`, carrying the procedure from `2026-08-09-dmarc-enforcement-plan.md` lines 48-70 and the rule that the alias list is the proof, and confirm with `gh issue view <number> --json labels,title` that the label and title are present.
- [ ] 2.2 Create one `planning` issue each for the email migration, family continuity, knowledge management, and PDF toolset records, carrying the goal, constraints, open decisions, and done-when boundary of each record and none of its status metadata, and confirm with `gh issue list --label planning --json title` that five titles are listed.
- [ ] 2.3 Create one `planning` issue for the scoped WSL batch worker from `2026-08-09-multi-host-fleet-plan.md` section `Boundary on the wife's machine`. State that the structural work is superseded by `declare-typed-host-options`, `connect-fleet-over-tailnet`, and `key-fleet-by-host`. Link the separate Air offboarding issue instead of duplicating it, and confirm both issues with `gh issue view`.
- [ ] 2.4 Delete every file under `docs/plans/` including `INDEX.md`, remove the `docs/plans/` row and the `Planning index` link from `README.md`, and confirm with `test ! -d docs/plans` and `grep -rn 'docs/plans' AGENTS.md README.md docs openspec/specs` printing nothing.
- [ ] 2.5 Replace the lifecycle-table row "Planned but blocked experiment" in the architecture document with "Confirmed work without a scheduled change" that names the owning repository's issue, and confirm with `grep -c 'Confirmed work without a scheduled change' docs/architecture/personal-omp-environment.md` printing `1`.

## 3. Planning-Home Check

- [ ] 3.1 Add `packages/planning-home-check.nix` as a `writeShellApplication` that takes one tree path, fails on any file under `docs/plans/` and on any Markdown file outside `openspec/changes/` that contains `docs/plans/`, and prints each offending path; add `packages/planning-home-check-tests.nix` with the three fixture trees from design decision 10; wire the tree check and the fixture test as flake checks on every system in the layout that `key-fleet-by-host` established; confirm with `nix build .#checks.x86_64-linux.planningHome .#checks.x86_64-linux.planningHomeCommand` succeeding.
- [ ] 3.2 Confirm that the check rejects, with a temporary probe that adds `docs/plans/probe.md` and observes `nix build .#checks.x86_64-linux.planningHome` fail with that path in its output, then revert the probe.
- [ ] 3.3 Confirm that the reference rule rejects, with a temporary probe that adds a `docs/plans/` link to `README.md` and observes the same check fail naming `README.md`, then revert the probe.

## 4. Architecture Document

- [ ] 4.1 Confirm that `connect-fleet-over-tailnet` recorded the reversed `korolev` isolation decision, distinguished the durable three-machine fleet from the temporary Air research-results peer, linked the Air offboarding issue, and rewrote the `WSL work machine` ownership section. Confirm that the retired isolation sentence is absent and that `remote build`, `temporary`, and the issue URL each appear; add missing text from the archived proposal if needed.
- [ ] 4.2 Rename every backticked `nix-darwin` in the architecture document to `nix-config`, including the ownership heading, and confirm with `grep -n '`nix-darwin`' docs/architecture/personal-omp-environment.md` printing nothing while `grep -c 'nix-darwin' docs/architecture/personal-omp-environment.md` still counts the product references.
- [ ] 4.3 Delete the Resume section, the current-state table, and the sentence about `docs/plans/` historical evidence, and confirm with `grep -c 'Resume after a new session\|^## Current state\|63-task plan' docs/architecture/personal-omp-environment.md` printing `0`.
- [ ] 4.4 Delete the subsections `package-personal-omp-plugin`, `consume-personal-omp-plugin`, `adopt-nixos-wsl-host`, and `manage-windows-layer` under Workstreams, and confirm that `grep -c '^### `' docs/architecture/personal-omp-environment.md`prints`0\`.
- [ ] 4.5 Resolve the four project repositories with `gh repo list glockyco --json name`, create one issue titled `nix-development-environment` in each existing repository carrying that project's audit snapshot, `must` list, acceptance list, and non-gating follow-ups verbatim, and confirm with `gh issue view <url>` for each created issue.
- [ ] 4.6 Replace the four per-project subsections with the dependency order that links the four issues, keep the common contract and the completion rule, fold the durable sentence of `Legacy cleanup` into the completion rule, delete `Legacy cleanup`, and confirm with `grep -c '^#### HotRepl migration\|^#### Ardenfall migration\|^#### Ancient Kingdoms migration\|^#### Erenshor migration\|^### Legacy cleanup' docs/architecture/personal-omp-environment.md` printing `0`.
- [ ] 4.7 Remove the step "update this document's current-state row" from the completion rule and reword the acceptance-gate bullet that names "the WSL bootstrap" to name korolev provisioning, and confirm with `grep -c 'current-state row\|WSL bootstrap' docs/architecture/personal-omp-environment.md` printing `0`.
- [ ] 4.8 Replace the version-pinned primary references with unversioned links to the OpenSpec repository, the OpenSpec workflows document, and the three OMP documents, and confirm with `grep -c 'v1\.8\.0\|v17\.2\.15' docs/architecture/personal-omp-environment.md` printing `0` and `curl -fsSIo /dev/null <url>` succeeding for each replaced link.
- [ ] 4.9 Replace the sentence "OpenSpec active changes are not a parking lot" and its surrounding paragraph with the rule from design context: a structural programme may hold its sequential changes as active changes at once, and unscheduled work is an issue; confirm with `grep -c 'not a parking lot' docs/architecture/personal-omp-environment.md` printing `0`.
- [ ] 4.10 Update the "Last reviewed" date and the status line, and confirm with `nix fmt -- --fail-on-change docs/architecture/personal-omp-environment.md` passing.

## 5. Agent Entry Point and README

- [ ] 5.1 Rewrite the `Release gates` section of `AGENTS.md` to list every gate with the system that runs it as design decision 6 states, including `nix flake check --all-systems --print-build-logs` on `korolev` through the remote builder, and confirm with `grep -c -- '--all-systems' AGENTS.md` printing `1`.
- [ ] 5.2 State the two OpenSpec command forms and `openspec list` in `AGENTS.md` as design decision 7 states, and confirm with `grep -c 'openspec validate --all --strict\|openspec validate --archived --strict\|openspec validate <name> --strict\|openspec list' AGENTS.md` printing `4`.
- [ ] 5.3 Replace the gate command block in the README `Develop` section with a link to `AGENTS.md#release-gates`, keep the `nix develop` and hook sentences, and confirm with `grep -c 'check-darwin-build-plans' README.md` printing `0`.
- [ ] 5.4 Confirm that the README activation section states the checkout path that `modules/home/darwin/darwin-switch.nix` declares, with the string the README quotes appearing in `grep -n 'flake = ' modules/home/darwin/darwin-switch.nix`.
- [ ] 5.5 Update the README layout row for `docs/operations/` to name `korolev-provisioning.md` by content and the `Documentation` list to link the renamed runbook, and confirm with `grep -c 'wsl-omp-bootstrap' README.md` printing `0`.

## 6. Runbooks and Archived Evidence

- [ ] 6.1 Move the runbook with `git mv docs/operations/wsl-omp-bootstrap.md docs/operations/korolev-provisioning.md`, update the two links in the architecture document and the two in the README, and confirm with `grep -rn 'wsl-omp-bootstrap' AGENTS.md README.md docs` printing nothing.
- [ ] 6.2 Delete the `Ubuntu-26.04` termination steps from section 5 while keeping the `user@1000.service` gate, delete the `Distribution rollback` subsection, and confirm with `grep -c 'Ubuntu' docs/operations/korolev-provisioning.md` printing `0`.
- [ ] 6.3 Move the `Accepted evidence: 2026-09-03` table and its paragraph to `openspec/changes/archive/2026-09-03-adopt-nixos-wsl-host/evidence.md` with a first line that names task 8.3, keep the `Release evidence` procedure in the runbook, and confirm with `grep -c 'Accepted evidence' docs/operations/korolev-provisioning.md` printing `0` and `grep -c '1.11.0' openspec/changes/archive/2026-09-03-adopt-nixos-wsl-host/evidence.md` printing `1`.
- [ ] 6.4 Move the `Evidence` section of `container-runtime.md` to `openspec/changes/archive/2026-08-21-provide-colima-container-runtime/evidence.md` with a first line that names task 5.6, and confirm with `grep -c '^## Evidence' docs/operations/container-runtime.md` printing `0` and `grep -c 'jarvis-scenarios' openspec/changes/archive/2026-08-21-provide-colima-container-runtime/evidence.md` printing `1`.
- [ ] 6.5 Replace the gate commands in `container-runtime.md` `Upgrade preparation` and in the three `dependency-updates.md` update variants with a link to `AGENTS.md#release-gates`, keep the non-gate commands, and confirm with `grep -rn 'check-darwin-build-plans\|nix flake check --print-build-logs' docs/operations` printing nothing.
- [ ] 6.6 Delete the sentence "OpenSpec 1.9 adds strict task-numbering and scenario checks plus `validate --archived`" from `dependency-updates.md`, keep the sentence that the flake gate runs active and archived validation, and confirm with `grep -c 'OpenSpec 1.9' docs/operations/dependency-updates.md` printing `0`.
- [ ] 6.7 Add the language smoke procedure to `dependency-updates.md` under `Activation and smoke`: one representative project per language, diagnostics for every language, and definition, references, and rename where the server supports them; confirm with `grep -c 'rename' docs/operations/dependency-updates.md` printing at least `1`.
- [ ] 6.8 Add a container smoke step to `korolev-provisioning.md` after the real-session smoke that runs one image through the Docker command name without root and checks the exit status, and confirm with `grep -c 'docker run' docs/operations/korolev-provisioning.md` printing `1`.
- [ ] 6.9 Confirm that no runbook sentence about the tailnet, the remote builder, or the first image build was changed, with `git diff -- docs/operations/korolev-provisioning.md` showing no hunk that names `tailscale`, `buildMachines`, or `tarballBuilder`.

## 7. OpenSpec Scaffold and Workflow Comments

- [ ] 7.1 Delete `openspec/config.yaml` and confirm with `openspec status --change align-documentation-with-fleet --json | jq -r .schemaName` printing `spec-driven`.
- [ ] 7.2 Confirm that every path and check name in the comments of `.github/workflows/check.yml` resolves, with `test -f` for each named path and `nix flake show --json | jq '.checks."aarch64-darwin" | keys'` listing each named check, and correct any that an earlier change moved.

## 8. Verify the Complete Change

- [ ] 8.1 Run `nix fmt -- --fail-on-change`.
- [ ] 8.2 Run `nix flake check --all-systems --print-build-logs` on `korolev` with the Nix the host declares, and confirm that `planningHome`, `planningHomeCommand`, and `openspecContracts` are among the passing checks.
- [ ] 8.3 Run `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the Darwin host.
- [ ] 8.4 Confirm that both system derivations are unchanged, with `nix eval .#darwinConfigurations.macbook-pro.config.system.build.toplevel.drvPath` and `nix eval .#nixosConfigurations.korolev.config.system.build.toplevel.drvPath` equal to the values at the parent commit under a forced `system.configurationRevision` as `declare-typed-host-options` design decision 8 states, and that `flake.lock` is unchanged.
- [ ] 8.5 Run `openspec validate align-documentation-with-fleet --strict`, `openspec validate --all --strict`, and `openspec validate --archived --strict`.
- [ ] 8.6 Run the closure gates for the documentation: `grep -rn '`nix-darwin`' AGENTS.md README.md docs` prints nothing, `grep -rn 'docs/plans' AGENTS.md README.md docs openspec/specs` prints nothing, `grep -rn 'check-darwin-build-plans' README.md docs` prints nothing, `grep -rn 'v1\.8\.0\|v17\.2\.15\|OpenSpec 1\.9' docs` prints nothing, and `test ! -e openspec/config.yaml` succeeds.
- [ ] 8.7 Review the final diff by deletion, issue link, architecture, runbook, specification, and check, and confirm that no file under `modules/`, `hosts/`, or `packages/` other than the two planning-home files changed.
- [ ] 8.8 After archive, confirm with `grep -rn '`nix-darwin`' openspec/specs` printing nothing that the merged `personal-omp-workstation` requirement names `nix-config`.

## 9. Documentation

- [ ] 9.1 Add a dated decision-log entry that records the parking-lot reversal for the structural programme, one planning home with issues for unscheduled work, one release-gate statement in `AGENTS.md`, and release evidence in archived changes, and confirm that the entry names the date and the four invariants.
- [ ] 9.2 Update the README `Ownership` and `Layout` rows that name the architecture document and the operations runbooks so they describe the documents as this change leaves them, and confirm with `nix fmt -- --fail-on-change README.md` passing.
