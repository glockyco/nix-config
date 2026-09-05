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

## Superseded cleanup proposals

The documentation cleanup replaced two earlier approaches. Their change directories are removed, not archived as completed. Their tasks remain unimplemented in Git history, and their proposed specification changes are not accepted requirements.

- [Documentation and fleet alignment](https://github.com/glockyco/nix-config/tree/2f51f2055bb1bcac12d25801a73347ed7cfe46c6/openspec/changes/align-documentation-with-fleet): preserves the full proposal, unchecked tasks, and unimplemented deltas. Its [retained intent](https://github.com/glockyco/nix-config/blob/2f51f2055bb1bcac12d25801a73347ed7cfe46c6/openspec/changes/align-documentation-with-fleet/design.md#retained-intent) includes frontend and persistent-memory experiments and HotRepl, Ardenfall, Ancient Kingdoms, and Erenshor migrations.
- [Planning-home consolidation](https://github.com/glockyco/nix-config/tree/2f51f2055bb1bcac12d25801a73347ed7cfe46c6/openspec/changes/consolidate-planning-home): preserves the rejected migration approach, unchecked tasks, and unimplemented delta. Its [retained intent](https://github.com/glockyco/nix-config/blob/2f51f2055bb1bcac12d25801a73347ed7cfe46c6/openspec/changes/consolidate-planning-home/design.md#retained-intent) requires separate review before moving or removing any legacy plan.

These commit-pinned records preserve the complete unresolved material, not replacement summaries. They do not authorize execution. Review current conditions and create a separate change in the owning repository before scheduling any retained work.

## Superseded historical records

- [OMP Setup Nix Consolidation Tasks](2026-08-07-omp-setup-nix-consolidation-plan.md): superseded by the accepted personal OMP architecture; do not execute.
- [OMP Setup Nix Consolidation](2026-08-07-omp-setup-nix-consolidation-spec.md): superseded by the accepted personal OMP architecture; do not implement.
