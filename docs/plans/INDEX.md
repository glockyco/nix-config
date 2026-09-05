# Planning Index

These files are tracked records, not an implementation queue. A permanent change starts only after it has an active OpenSpec change in the owning repository. Preserve a plan until a later review accepts, supersedes, or deletes it explicitly.

## Planning boundaries

These plans remain distinct records while a separate planning migration awaits review. Do not replace them with summaries or delete an original before its complete replacement is reviewed.

[Existing OpenSpec changes](../../openspec/changes/) own their scheduling and acceptance records. Their unchecked tasks do not authorize execution, even when the CLI reports `in-progress`. Read the owning change before scheduling work; this index is not a live workstation status report.

## Completed record

- [DMARC Enforcement Rollout](2026-08-09-dmarc-enforcement-plan.md): rollout complete; `p=quarantine` is the accepted end state. Explicit `dmarc@glockyco.com` alias verification remains unresolved.

## Deferred evaluations

- [PDF Reader and Editor Evaluation](2026-08-13-pdf-reader-editor-evaluation-plan.md): deferred; PDF Expert remains the installed baseline.
- [Email Migration and Account Cleanup](2026-08-08-email-migration-plan.md): deferred until the infrastructure backlog is complete.

## Draft decisions, not scheduled

- [Family Backup, Storage, and Continuity](2026-08-08-family-backup-storage-plan.md): directional draft; products, capacity, retention, and legal arrangements remain undecided.
- [Knowledge Management](2026-08-09-knowledge-management-plan.md): draft; the RemNote export and repository location remain open.
- [Multi-Host Fleet Architecture](2026-08-09-multi-host-fleet-plan.md): draft; network, account, and deployment details remain open.

## Superseded historical records

- [OMP Setup Nix Consolidation Tasks](2026-08-07-omp-setup-nix-consolidation-plan.md): superseded by the accepted personal OMP architecture; do not execute.
- [OMP Setup Nix Consolidation](2026-08-07-omp-setup-nix-consolidation-spec.md): superseded by the accepted personal OMP architecture; do not implement.
