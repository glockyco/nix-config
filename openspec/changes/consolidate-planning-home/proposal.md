## Scheduling — 2026-09-05

This change is deferred, not canceled or completed. It is not a prerequisite for working OMP or Tailscale. [Near-term priorities](../../../docs/architecture/personal-omp-environment.md#near-term-priorities) govern scheduling.

Small acceptance-record corrections support the current OMP and Tailscale checks. They do not start this planning-store migration, broad documentation cleanup, or creation of replacement planning owners. The proposed absorption by `align-documentation-with-fleet` is also deferred. This change and its history remain in place.

OpenSpec CLI counts describe artifact and task state, not scheduling authorization. Requirements and unchecked tasks remain preserved. Work resumes only when a concrete maintenance or use requirement warrants it and the owner schedules and reviews the plan again. That review must reconcile the two planning-home plans before either proceeds.

## Why

The repository declares OpenSpec as the source of active implementation work, but `docs/plans/` still holds eight records and an index with deferred and draft state. The canonical OMP architecture also cites superseded plans and preserves unscheduled work, so readers must still reconcile two planning systems.

## What Changes

- Declare `openspec/` as the only repository home for current planning state and accepted behavior.
- Inventory all eight legacy records, the index, and current references to them.
- Preserve the five operator-confirmed workstreams in focused OpenSpec owners: `evaluate-pdf-toolset`, `migrate-email-accounts`, `establish-family-continuity`, `replace-remnote-knowledge-base`, and `define-multi-host-fleet`.
- Move unique delivered DMARC behavior into its accepted or operational owner, then remove the completed plan.
- Reconcile the two superseded OMP records with the accepted `personal-omp-workstation` capability and the canonical architecture.
- Remove task and backlog ownership from the canonical architecture while preserving verified architecture, current state, dependency ordering, and acceptance constraints.
- Delete `docs/plans/` after every retained item has one owner and every current reference points to that owner.
- Add repository validation that rejects a second planning home and current references to the retired path.
- **BREAKING**: deferred and draft work no longer lives in a shared planning index. Each confirmed workstream has its own OpenSpec lifecycle.

## Capabilities

### New Capabilities

- `repository/planning-state`: Defines sole planning ownership, legacy-record migration, architecture boundaries, and enforcement against a second planning home.

### Modified Capabilities

None.

## Impact

The change affects eight planning records, `docs/plans/INDEX.md`, the canonical OMP architecture, repository validation, and links to the retired path. It creates planning owners but does not implement those five workstreams. It does not change the active Nix generation, OMP package, email accounts, storage, knowledge data, hosts, or installed applications.
