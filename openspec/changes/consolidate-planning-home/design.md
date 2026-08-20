## Context

See `proposal.md` for motivation and `specs/repository/planning-state/spec.md` for the contract.

The legacy tree contains eight records plus `INDEX.md`. Five records describe work the operator confirmed remains intended. One DMARC record is marked complete but still contains an outstanding alias action. Two OMP records are explicitly superseded by the accepted workstation architecture.

The canonical OMP architecture states that it does not own repository implementation tasks. It still cites the superseded plans, says project migrations remain planned, and carries resumable future-work detail. The cleanup must preserve architecture and coordination constraints without leaving a parallel backlog.

Direct Fastmail alias verification was attempted through the actual settings URL. No authenticated browser session was available. The operator believes the alias exists, but that is not evidence of current state.

## Goals / Non-Goals

**Goals:**

- Give every legacy record one verified disposition.
- Give all five confirmed workstreams focused OpenSpec owners before removing their source records.
- Preserve delivered behavior and architecture in current owners.
- Remove the planning index and legacy tree.
- Make a second planning home fail under `nix flake check`.

**Non-Goals:**

- Implement any of the five confirmed workstreams.
- Change DNS, Fastmail, storage, hosts, applications, or the active Nix generation.
- Convert the canonical architecture into a task tracker.
- Edit project repositories or `omp-agent-setup` from this change.

## Decisions

### 1. Build a disposition ledger before migration

Create `disposition.md` under this change. Give each of the eight records one row with its status, inbound references, retained intent, evidence, disposition, destination, and verification. Add separate rows for planning statements removed from `INDEX.md` and the canonical architecture.

A status label does not prove delivery or current intent. The operator's explicit confirmation does prove intent for the five selected workstreams.

**Alternative:** Trust the classifications in `INDEX.md`. Rejected because the index mixes complete, deferred, draft, and superseded records while still acting as shared current state.

### 2. Create five focused planning owners

Create complete OpenSpec changes with these names before deleting the corresponding records:

- `evaluate-pdf-toolset`
- `migrate-email-accounts`
- `establish-family-continuity`
- `replace-remnote-knowledge-base`
- `define-multi-host-fleet`

Each change receives only the intent, constraints, decisions, and acceptance criteria of its source workstream. It does not inherit historical status metadata or implementation steps that current evidence contradicts. None of the five changes is implemented as part of this cleanup.

**Alternative:** Keep one deferred-work index or create one backlog change. Rejected because unrelated work would share status, dependencies, and completion semantics.

### 3. Verify the DMARC alias in Fastmail before disposition

Open Fastmail's alias settings in an authenticated session and confirm whether `dmarc@glockyco.com` exists as an explicit alias. A test message is not proof because the catch-all accepts it.

If the alias exists, move the stable DNS and operating facts to their current owner and remove the plan. If it does not exist, create a focused owner for the outstanding action before removal. Do not mark the action complete from memory.

**Alternative:** Accept the operator's recollection. Rejected because the plan itself explains why indirect delivery can hide a missing alias.

### 4. Reconcile superseded OMP records against accepted owners

Compare both OMP records with `openspec/specs/personal-omp-workstation/spec.md` and `docs/architecture/personal-omp-environment.md`. Preserve only unique current architecture or acceptance constraints. Remove mutable deployment, `omp-plans`, `omp-skill`, source patching, and retired wrapper assumptions.

**Alternative:** Keep the records as historical evidence. Rejected because Git already preserves them and current architecture cites them from an always-current document.

### 5. Keep architecture separate from planning state

The canonical architecture keeps system boundaries, observed current state, dependency ordering, experiment protocols, and acceptance constraints. It removes resumable task sequences, deferred backlogs, and claims that it owns planned repository work.

A future action with an owning change is replaced by a link to that change. A future action without an owner is not presented as active implementation work. Cross-repository dependency order can remain when it explains architecture, but task detail stays in the owning repository.

**Alternative:** Move the complete architecture into OpenSpec. Rejected because stable cross-repository boundaries and observed current state are documentation, not one implementation change.

### 6. Delete the legacy tree instead of moving it

After every ledger row has an owner or a removal reason, delete all eight records and `INDEX.md`. Do not create `docs/history/plans/`. Git history remains the historical source.

**Alternative:** Retain only completed and superseded records. Rejected because the path remains a second apparent authority and an attractive destination for new planning.

### 7. Enforce the boundary as a pure flake check

Add a `planningHome` check beside the existing repository checks. It rejects a `docs/plans/` tree, current references to that path, and guidance or architecture that declares another task owner. Exclude OpenSpec history because migration records and removal requirements must name the retired path.

The check includes synthetic rejected and allowed fixtures before it scans the repository source. This proves that an empty result is meaningful. `nix flake check` remains the single validation entry point.

**Alternative:** Add a standalone script that no existing gate invokes. Rejected because it can drift or never run.

## Risks / Trade-offs

- **A focused owner loses a binding decision from its source plan.** → Read the complete source and carry constraints, rejected alternatives, and acceptance boundaries before deletion.
- **The DMARC alias cannot be verified during implementation.** → Block that ledger row and finish the other seven. Do not delete the plan until direct verification succeeds.
- **Architecture pruning removes a real cross-repository constraint.** → Preserve boundaries and dependency ordering, and remove only task ownership or duplicate steps.
- **Five new changes appear active although implementation is deferred.** → Keep their status honest and independent. Do not claim scheduling or implementation.
- **The flake check rejects historical OpenSpec text.** → Exclude OpenSpec change history and test allowed removal language explicitly.
- **One repository cleanup is mistaken for fleet completion.** → Report `nix-darwin`, `omp-agent-setup`, and project repositories separately.

## Migration Plan

1. Create the eight-record ledger and inventory planning statements in the index and canonical architecture.
1. Generate and validate the five focused OpenSpec owner changes without implementing them.
1. Verify the DMARC alias directly and resolve its delivered or outstanding state.
1. Migrate unique delivered DMARC and OMP content to accepted or operational owners.
1. Remove task and backlog ownership from the canonical architecture while preserving architecture and coordination constraints.
1. Add the pure flake planning-home check and prove its rejected and allowed fixtures.
1. Delete all eight records and `INDEX.md` after every ledger row is complete.
1. Run `nix fmt -- --fail-on-change`, `nix flake check --print-build-logs`, the system build, and `openspec validate --all --strict`.

Rollback is a normal commit revert because this change does not activate a generation or mutate external services. Keep validated focused owner changes and verified content migrations if the final cutover must be reverted.
