# Planning Index

These files are tracked records, not an implementation queue. A permanent change starts only after it has an active OpenSpec change in the owning repository. Preserve a plan until a later review accepts, supersedes, or deletes it explicitly.

## Canonical architecture

- [Personal OMP Environment](../architecture/personal-omp-environment.md#near-term-priorities): keep the installed architecture. Prioritize real-repository OMP usability and coordinated WSL restart/network verification. Linux C# remains a failed integration. Broader refactors, project migrations, and experiments are deferred, not complete.

The canonical priority section names the six deferred OpenSpec proposals. Their retained unchecked tasks are not an implementation queue, even when the CLI lists them as `in-progress`. Optional builder recovery and peer enrollment remain separate from basic OMP and Korolev–Mac connectivity. Do not start deferred work automatically after the immediate checks pass.

## Completed record

- [DMARC Enforcement Rollout](2026-08-09-dmarc-enforcement-plan.md): complete; `p=quarantine` is the accepted end state.

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
