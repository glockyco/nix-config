## Scheduling — 2026-09-05

This change is deferred, not canceled or completed. It is not a prerequisite for working OMP or Tailscale. [Near-term priorities](../../../docs/architecture/personal-omp-environment.md#near-term-priorities) govern scheduling.

Small acceptance-record corrections support the current OMP and Tailscale checks. They do not authorize these migration tasks, broad documentation cleanup, or creation of replacement planning owners. The proposed absorption by `align-documentation-with-fleet` is also deferred. This change and its history remain in place.

OpenSpec CLI counts describe artifact and task state, not scheduling authorization. All unchecked tasks remain preserved. Execution resumes only when a concrete maintenance or use requirement warrants it and the owner schedules and reviews the plan again. That review must reconcile the two planning-home plans before either proceeds.

## 1. Establish the Disposition Ledger

- [ ] 1.1 Create `disposition.md` with one row for each of the eight legacy records; include status, inbound references, retained intent, evidence, disposition, destination, and verification.
- [ ] 1.2 Add ledger entries for `INDEX.md` and every task or backlog statement in `docs/architecture/personal-omp-environment.md`.
- [ ] 1.3 Prove that the ledger path set equals the tracked `docs/plans/` record set and that every current retired-path reference is recorded.
- [ ] 1.4 Record the accepted specs, operational documents, and future focused changes that can own retained content.

## 2. Verify Every Legacy Record

- [ ] 2.1 Read the complete PDF evaluation record and verify its constraints, rejected alternatives, and acceptance boundary before migration.
- [ ] 2.2 Read the complete email migration record and verify its address policy, ordering, external-service boundaries, and acceptance boundary before migration.
- [ ] 2.3 Read the complete family continuity record and verify its privacy, identity, device, retention, and legal-decision boundaries before migration.
- [ ] 2.4 Open authenticated Fastmail alias settings and directly verify whether `dmarc@glockyco.com` exists; do not use test delivery or memory as proof.
- [ ] 2.5 Verify the DMARC DNS state and operating procedure against `dns/dnsconfig.js`, current documentation, and observed external state.
- [ ] 2.6 Read the complete knowledge-management record and verify its zero-scheduled-maintenance constraint, export boundary, and acceptance criteria before migration.
- [ ] 2.7 Read the complete multi-host fleet record and verify its host, identity, decryption, network, and deployment boundaries before migration.
- [ ] 2.8 Verify `2026-08-07-omp-setup-nix-consolidation-plan.md` against the accepted workstation spec and current architecture.
- [ ] 2.9 Verify `2026-08-07-omp-setup-nix-consolidation-spec.md` against the accepted workstation spec and current architecture.

## 3. Create Focused OpenSpec Owners

- [ ] 3.1 Scaffold `evaluate-pdf-toolset` and generate its proposal, capability delta, design, and tasks from verified current intent.
- [ ] 3.2 Scaffold `migrate-email-accounts` and generate its proposal, capability delta, design, and tasks from verified current intent.
- [ ] 3.3 Scaffold `establish-family-continuity` and generate its proposal, capability delta, design, and tasks from verified current intent.
- [ ] 3.4 Scaffold `replace-remnote-knowledge-base` and generate its proposal, capability delta, design, and tasks from verified current intent.
- [ ] 3.5 Scaffold `define-multi-host-fleet` and generate its proposal, capability delta, design, and tasks from verified current intent.
- [ ] 3.6 Validate all five changes strictly and confirm that none implements or owns another workstream.
- [ ] 3.7 Record each focused owner in the disposition ledger before removing its source record.

## 4. Migrate Delivered Behavior and Architecture

- [ ] 4.1 If the DMARC alias exists, move unique stable DNS and operating facts to their current owner and mark the record delivered.
- [ ] 4.2 If the DMARC alias is missing, create and validate a focused OpenSpec owner for the outstanding action before removing the record.
- [ ] 4.3 Reconcile both superseded OMP records with `personal-omp-workstation` and the canonical architecture; migrate only unique current constraints.
- [ ] 4.4 Remove mutable deployment, retired commands, source patching, and obsolete wrapper assumptions from current architecture references.
- [ ] 4.5 Audit the canonical architecture for resumable tasks, deferred backlogs, and unowned future actions.
- [ ] 4.6 Replace each owned future action with a link to its named OpenSpec change, without duplicating tasks.
- [ ] 4.7 Remove unowned planning statements while preserving system boundaries, observed current state, dependency ordering, experiment protocols, and acceptance constraints.
- [ ] 4.8 Resolve every ledger row and verify every retained destination exists before deletion.

## 5. Guard and Cut Over

- [ ] 5.1 Add a pure `planningHome` flake check that rejects `docs/plans/`, current retired-path references, and a second task owner in guidance or architecture.
- [ ] 5.2 Add synthetic rejected fixtures for each conflict class and allowed fixtures for OpenSpec history and explicit removal requirements.
- [ ] 5.3 Confirm that `AGENTS.md` names only `openspec/changes/` and `openspec/specs/` for planning and accepted behavior.
- [ ] 5.4 Remove every current reference to `docs/plans/` after its replacement owner exists.
- [ ] 5.5 Delete all eight legacy records and `docs/plans/INDEX.md`; do not create another history directory.
- [ ] 5.6 Run the planning-home check against the cut-over repository and confirm that it reports no conflict.

## 6. Verify the Complete Change

- [ ] 6.1 Prove that the eight-record ledger covers every removed path and that all retained destinations exist.
- [ ] 6.2 Run `nix fmt -- --fail-on-change`.
- [ ] 6.3 Run `nix flake check --print-build-logs` and inspect the `planningHome` check output.
- [ ] 6.4 Run `nix build .#darwinConfigurations.macbook-pro.system` without activating the result.
- [ ] 6.5 Run `openspec validate --all --strict` and validate all five focused owner changes.
- [ ] 6.6 Review the final diff by owner, architecture, guard, and deletion; remove incidental changes.
- [ ] 6.7 Report this repository separately from `omp-agent-setup` and project cleanup changes.
