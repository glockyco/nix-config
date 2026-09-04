## Context

See `proposal.md` for the motivation. This is the seventh change of the structural programme. It assumes that `declare-typed-host-options`, `connect-fleet-over-tailnet`, `key-fleet-by-host`, `separate-platform-baseline-from-roles`, `package-user-programs`, and `derive-windows-check-from-declaration` are archived when it starts. `consolidate-planning-home` is still active when it starts. The facts that shape the approach:

- `docs/plans/` holds eight records and `INDEX.md`. The index classifies one record as complete, two as deferred, three as draft, and two as superseded (`docs/plans/INDEX.md:5-27`). `README.md:42,161` links the index. The architecture document calls the two superseded records historical evidence (`personal-omp-environment.md:13`).
- `consolidate-planning-home` was created on 2026-08-20 and has 0 of 41 tasks complete. Its design creates five active OpenSpec changes as owners for unscheduled work (`consolidate-planning-home/design.md:38-50`), blocks one record on a live Fastmail alias verification (`design.md:52-58`), adds the capability `repository/planning-state` under a new domain level while every accepted capability is flat, and names this repository `nix-darwin` (`design.md:95`). Its multi-host fleet owner is now the structural programme itself.
- The DMARC record states one outstanding action: make the `dmarc@glockyco.com` alias explicit in Fastmail (`2026-08-09-dmarc-enforcement-plan.md:48-70,134-135`). Its DNS rationale already lives in `dns/dnsconfig.js:21-49`. The multi-host fleet record excludes the Air and schedules the removal of its SSH surface (`2026-08-09-multi-host-fleet-plan.md:44-68`). `connect-fleet-over-tailnet` joins the Air to the tailnet instead, so that part of the record is contradicted by an accepted decision.
- The lifecycle table assigns "Planned but blocked experiment" to the owning repository's GitHub issue and "Historical rationale" to archived OpenSpec changes and superseded plan files (`personal-omp-environment.md:309-317`). The 2026-08-08 decision keeps active OpenSpec changes actionable and uses issues for planned work (`personal-omp-environment.md:670`).
- This session, the owner reversed "OpenSpec active changes are not a parking lot" (`personal-omp-environment.md:52`) for the structural programme alone: seven sequential and actionable changes exist at once. Unscheduled work is still not an active change.
- `connect-fleet-over-tailnet` reverses the 2026-09-03 decision that `korolev` holds no shared secret and drives no other host. Its proposal records the reversal, the tailnet ownership boundary, and the node-join procedure in the architecture document and the `korolev` runbook (`connect-fleet-over-tailnet/proposal.md:20`), and its delta rewrites the isolation requirement (`connect-fleet-over-tailnet/specs/personal-omp-workstation/spec.md`). Its `repository-quality-gates` delta lets the Linux host build every Darwin check through the remote builder and runs the build-plan inspection on the Darwin host over the tailnet.
- The flake check `openspecContracts` runs `openspec validate --all --strict --no-interactive` and `openspec validate --archived --strict --no-interactive` through the plugin's `lib.openspecCheck` (pinned plugin source `flake.nix:158-159`). OpenSpec resolves the `spec-driven` schema without `openspec/config.yaml`: a copy of the tree without that file reports `schemaName: spec-driven` and validates a change.
- The archived change `2026-09-03-split-home-modules-by-platform` keeps its acceptance record in `baseline.md` beside `tasks.md`. Archived task 5.6 of `provide-colima-container-runtime` and task 8.3 of `adopt-nixos-wsl-host` point at the evidence sections that now sit in the runbooks.
- `docs/` contains no `.local` name and no LAN address. `connect-fleet-over-tailnet` owns every runbook sentence about the tailnet, the remote builder, and which machine builds the first image.
- The structural checks `moduleImports` and `fleetSurface` are the accepted pattern for a check on the repository tree: a program in `packages/<x>-check.nix`, fixture tests in `packages/<x>-check-tests.nix`, and one flake check that runs the program on `./.`.

## Goals / Non-Goals

**Goals:**

- One planning home, one release-gate statement, one repository name, and one OpenSpec command form, each with a command that proves it.
- Every record under `docs/plans/` has one stated fate, and `consolidate-planning-home` has one stated fate.
- The architecture document owns boundaries, decisions, dependency order, and protocols, and nothing that a change or an issue owns.
- Runbooks hold procedures. Evidence of one release lives in the archived change that accepted it.
- Every specification scenario is either backed by a check or labelled as a live procedure with a documented home.

**Non-Goals:**

- Any change to a host closure, a module, an installed package, or `flake.lock`.
- The `darwin-switch` checkout path in `modules/home/darwin/darwin-switch.nix:9`. The README states what the module declares.
- The `flake.nix` description string and the check names in the workflow comments, which `key-fleet-by-host` owns.
- The reversed `korolev` isolation decision, the `WSL work machine` ownership section, and every runbook sentence about the tailnet or the remote builder, which `connect-fleet-over-tailnet` owns.
- Implementing any workstream that moves to an issue.

## Decisions

### 1. Absorb `consolidate-planning-home` and delete its directory

This change carries the intent of `consolidate-planning-home`: one planning home, verified disposition of every record, an architecture document that owns no tasks, and a check that guards the boundary. The directory `openspec/changes/consolidate-planning-home/` is deleted in this change, not archived, because none of its tasks ran and an archive would record work that did not happen.

Executing it first was rejected for four reasons. Its plan creates five active changes for unscheduled work, which the 2026-08-08 decision forbids and which the owner's reversal of the parking-lot rule does not cover. Its multi-host fleet owner is superseded by the six programme changes that precede this one. It blocks the DMARC record on a live Fastmail verification that no repository check can observe. Its delta adds a domain level to the flat specification layout and names this repository `nix-darwin`, so every artifact would need a rewrite before its first task.

Its planning-home contract moves into `repository-quality-gates`, where the structural fleet requirements live, without the requirement that repository validation detects "guidance that declares another task owner". That rule has no mechanical form.

### 2. One fate per record under `docs/plans/`

| Record                                            | Fate                                                                                                                                                                                  |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `INDEX.md`                                        | Delete. OpenSpec and issues replace the index.                                                                                                                                        |
| `2026-08-07-omp-setup-nix-consolidation-plan.md`  | Delete. Superseded by the accepted `personal-omp-workstation` capability. Git history keeps it.                                                                                       |
| `2026-08-07-omp-setup-nix-consolidation-spec.md`  | Delete. Same reason.                                                                                                                                                                  |
| `2026-08-09-dmarc-enforcement-plan.md`            | Delete after one issue in `glockyco/nix-config` holds the outstanding alias action with the procedure from lines 48-70. The DNS rationale already lives in `dns/dnsconfig.js`.        |
| `2026-08-08-email-migration-plan.md`              | Move to one issue in `glockyco/nix-config` that carries the goal, ordering, external-service boundary, and done-when boundary. Delete the record.                                     |
| `2026-08-08-family-backup-storage-plan.md`        | Move to one issue in `glockyco/nix-config` that carries the goal, principles, open decisions, and done-when boundary. Delete the record.                                              |
| `2026-08-09-knowledge-management-plan.md`         | Move to one issue in `glockyco/nix-config` that carries the decision, the zero-maintenance constraint, the open export and location questions, and the done-when boundary. Delete it. |
| `2026-08-09-multi-host-fleet-plan.md`             | Superseded by the six programme changes and `connect-fleet-over-tailnet`. The Air-removal plan is contradicted by the tailnet decision. One issue keeps the scoped WSL worker intent. |
| `2026-08-13-pdf-reader-editor-evaluation-plan.md` | Move to one issue in `glockyco/nix-config` that carries the goal, the gates, the corpus rule, and the done-when boundary. Delete the record.                                          |

The owning repository for the five issues is `glockyco/nix-config`. Each record concerns the operator's personal infrastructure that this repository configures: DNS and mail live in `dns/`, applications live in the Darwin modules, and the fleet lives in `hosts/`. Each issue receives the label `planning` so `gh issue list --label planning` enumerates unscheduled work. An issue carries current intent and the acceptance boundary. It does not carry the record's historical status or the steps that current evidence contradicts.

The lifecycle table row "Planned but blocked experiment" becomes "Confirmed work without a scheduled change", so the rule covers these issues and the existing experiment issues alike.

**Alternative rejected:** keep the drafts in the repository under another path. Any tracked path becomes a second planning home and an attractive destination for new plans.

### 3. Delete `openspec/config.yaml`

The file holds `schema: spec-driven` and thirty lines of template comments. OpenSpec applies `spec-driven` by default, and every change records its schema in its own `.openspec.yaml`. A populated `context` would repeat `AGENTS.md`, which the audit identified as the pattern that causes drift. The file is deleted.

### 4. The architecture document keeps boundaries and drops execution state

The document keeps: status and authority, goals, non-goals, decisions, ownership, personal policy, STE, research, commit workflow, language intelligence, lifecycle, the two experiment protocols, the cross-repository dependency order, the common project migration contract, the completion rule, activation and rollback, acceptance gates, the decision log, and the primary references.

The document drops:

- the Resume procedure. `AGENTS.md` is the entry point, and `openspec list` names the active changes;
- the current-state table. `openspec list` and `openspec/changes/archive/` are the record of this repository's work, and per-repository state for other repositories lives in their issues;
- the per-change subsections `package-personal-omp-plugin`, `consume-personal-omp-plugin`, `adopt-nixos-wsl-host`, and `manage-windows-layer`. The archived changes and the ownership section hold that content;
- the audit snapshots, `must` lists, acceptance lists, and non-gating follow-ups for HotRepl, Ardenfall, Ancient Kingdoms, and Erenshor. Each moves to one issue titled `nix-development-environment` in its owning repository, and the document links the four issues from the dependency order;
- the `Legacy cleanup` section. Its one durable sentence, that each project migration owns that repository's host paths and retired-tool calls, moves into the completion rule;
- the sentence that calls the `docs/plans/` records historical evidence.

Every backticked `nix-darwin` in `AGENTS.md`, `README.md`, `docs/`, and `openspec/specs/` names this repository and becomes `nix-config`. An unbackticked `nix-darwin` names the product and stays. The gate is `grep -rn '`nix-darwin`' AGENTS.md README.md docs openspec/specs`, which must print nothing.

The primary references become unversioned links to the OpenSpec and OMP documentation. The pinned versions are in `flake.lock`, and the dependency-update runbook already shows the commands that print them.

**Alternative rejected:** derive the current-state table from `openspec list` on each review. A table that a human must refresh drifts, as the audit found, and a generated table duplicates the command output.

### 5. Decision-log ownership for the two session decisions

`connect-fleet-over-tailnet` owns the entry that reverses the 2026-09-03 isolation decision and the rewrite of the `WSL work machine` ownership section. It changes that behavior, and the brief requires every change to record its own invariants at archive time. This change verifies both at its start and reconciles any gap, because it is the last change and the final arbiter of the document.

This change owns the entry that records the parking-lot reversal for the structural programme, and the entry for its own invariants: one planning home, one release-gate statement, and evidence in archived changes.

### 6. `AGENTS.md` is the one statement of the release gates

`AGENTS.md` lists every gate with the system that runs it:

- on either host: `nix fmt -- --fail-on-change`;
- on `korolev`: `nix flake check --all-systems --print-build-logs`, which builds the Darwin checks on the Mac through the remote builder;
- on `macbook-pro`: `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system`;
- the sentence that CI runs each leg with the Nix that its host runs.

`README.md`, `container-runtime.md`, and `dependency-updates.md` link to `AGENTS.md#release-gates` at the point where the gates run and repeat no gate command. The gate is `grep -rn 'check-darwin-build-plans' README.md docs`, which must print nothing.

### 7. One OpenSpec command form per purpose

`AGENTS.md` states two forms and nothing else states a form: `openspec validate <name> --strict` while a change is open, and `openspec validate --all --strict` plus `openspec validate --archived --strict` as the repository gate, which `nix flake check` runs. `openspec list` names the active changes. Change task lists use the first form.

### 8. Runbooks hold procedures, archived changes hold evidence

`docs/operations/wsl-omp-bootstrap.md` becomes `docs/operations/korolev-provisioning.md`. The name follows the title "Provision the korolev NixOS WSL host" and the README wording "korolev provisioning". Section 5 keeps the gate `systemctl is-active user@1000.service` and drops the `Ubuntu-26.04` termination steps. The `Distribution rollback` subsection is deleted. The accepted-evidence table and its paragraph move to `openspec/changes/archive/2026-09-03-adopt-nixos-wsl-host/evidence.md`. The `Release evidence` procedure stays.

`container-runtime.md` loses its `Evidence` section to `openspec/changes/archive/2026-08-21-provide-colima-container-runtime/evidence.md`.

`evidence.md` beside `tasks.md` follows the `baseline.md` precedent. `openspec validate --archived` parses `tasks.md` for checkboxes, and a prose table does not belong in that file.

The dependency-update runbook loses the sentence "OpenSpec 1.9 adds strict task-numbering and scenario checks plus `validate --archived`" and keeps the sentence that the flake gate runs active and archived validation.

### 9. Prose-only scenarios become checked plus live pairs

`batch-ssh/spec.md:66-77` is the accepted form. The language-server matrix splits into "Resolve every server", which the package-shape check proves with `command -v`, and "Exercise the matrix", a live procedure. The container runtime splits into "Declare the runtime", which the `korolevContainerRuntime` assertions prove, and "Run a container", a live procedure. Neither live procedure can run in a sandbox: one needs a model-backed session, the other a running WSL distribution.

Each live scenario names a documented home. The language smoke lives in `dependency-updates.md` under `Activation and smoke`, beside the wrapped-session smoke. The container smoke becomes a step in `korolev-provisioning.md` after the real-session smoke, as archived task 6.8 of `adopt-nixos-wsl-host` ran it.

The adapter-freshness requirement is removed. This repository tracks no adapter, and the one assertion behind it stays in the package-shape check under the pinned-inputs requirement.

The `darwin-dependency-builds` scenario says "the repository checks fail" while the mechanism is `nix run .#check-darwin-build-plans`, outside `nix flake check`. The requirement now states that the inspection is a release gate on the Darwin host, and the scenario names that gate.

### 10. The planning-home check is a program with fixture tests

`packages/planning-home-check.nix` is a `writeShellApplication` that takes one tree path. It fails when a file exists under `<tree>/docs/plans/` or when a Markdown file outside `<tree>/openspec/changes/` contains `docs/plans/`. It prints each offending path and exits 1. `packages/planning-home-check-tests.nix` runs the program against three fixture trees: one with a record under `docs/plans/`, one with a README that links the retired path, and one whose only reference sits under `openspec/changes/`. The first two must fail, the third must pass. The flake check runs the program on `./.`, wired like `moduleImports` in the layout that `key-fleet-by-host` established.

The check scans Markdown only. The program and its tests are Nix files that contain the pattern, so a scan of every file would need a self-exclusion list.

### 11. Workflow comments are swept, not rewritten

The comments in `.github/workflows/check.yml` name files and check names. This change confirms that each named path exists and each named check is a flake check output, and corrects any that the earlier changes moved. It does not rewrite the comments otherwise.

## Risks / Trade-offs

- [An issue loses a binding constraint from its record] → The task that creates each issue reads the complete record and carries the constraints, rejected alternatives, and done-when boundary. The record is deleted in the same commit that links the issue.
- [A project repository does not exist under the expected name] → `gh repo list glockyco` resolves the name before the issue is created. A repository that does not exist gets no issue, and the architecture document says so at the dependency order.
- [The DMARC alias is still implicit] → The issue keeps the action open. The record is not proof either way, and the DNS record is unaffected.
- \[`connect-fleet-over-tailnet` did not record its decision\] → Task 4.1 checks for the entry and the rewritten ownership section and adds them from the archived proposal if absent.
- \[`evidence.md` in an archived change fails `openspec validate --archived`\] → `baseline.md` already exists in an archived change and the gate passes. Task 6.6 runs the archived validation.
- [A gate command in a runbook is useful in place] → A link is one click away, and the four copies drifted. The runbooks keep their non-gate commands.
- [The planning-home check rejects this change's own artifacts] → The check excludes `openspec/changes/`, and the third fixture proves that exclusion.
