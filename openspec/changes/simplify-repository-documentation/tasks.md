## 1. Establish retained information

- [x] 1.1 Read every current document under `docs/`, the README, agent guidance, accepted specs, and active change artifacts. Record each document's removal or retained purpose briefly in the review; verify coverage includes both older cleanup proposals and every legacy plan.
- [x] 1.2 Identify essential bootstrap, external-authorization, and recovery instructions against current declarations. Verify the retained set includes account scope, required ordering, backup conditions, and mutable-state boundaries before deleting any source.

## 2. Replace the human entry point

- [x] 2.1 Rewrite `README.md` around the reader tasks in design decision 1, targeting about 100 readable lines. Verify both hosts, development, applicable release gates, activation, bootstrap, and rollback are discoverable without an architecture manual.
- [x] 2.2 Migrate indispensable operating instructions into the README or justified focused procedures. Verify each remaining `docs/operations/` file has a concrete bootstrap or recovery purpose, one README link, and no duplicated procedure.
- [x] 2.3 Preserve unique implementation rationale in nearby comments and remove the architecture manual and redundant operating documents. Verify each removed document's necessary content has a current owner and no configuration inventory replaces it elsewhere.

## 3. Reconcile guidance and planning

- [x] 3.1 Reduce `AGENTS.md` to repository-specific agent instructions and links; remove unused OpenSpec template commentary. Verify human-facing command guidance has one README owner and all safety and workflow constraints remain available.
- [x] 3.2 Mark the two earlier cleanup approaches superseded, preserving unfinished task status and unique unresolved intent as design decision 5 specifies. Retain every distinct legacy plan and its index, remove duplicated legacy-plan summaries, and defer migration to a separate reviewed change. Verify no pending action is falsely completed and no external issue or speculative change is created.
- [x] 3.3 Update current references throughout documentation, accepted specs, active changes, and source comments. Remove redundant narrative only where meaning is unchanged; verify requirement names, acceptance conditions, and unrelated work remain intact, with archives left historical.

## 4. Verify the documentation cutover

- [x] 4.1 Inspect the rendered README and retained procedures, then walk the host-selection, check, activation, bootstrap, and rollback reading paths. Verify current local links and command references; report any unavailable rendering capability without running destructive operations.
- [x] 4.2 Run `nix fmt -- --fail-on-change`, `openspec validate simplify-repository-documentation --strict`, and `openspec validate --all --strict`. Distinguish unrelated existing failures; verify the completed change contains only documentation, comments, and planning edits, with no runtime or dependency changes.
- [x] 4.3 Review the final maintained prose and justify each exception to README-only documentation. Verify no generator, documentation-policy check, replacement manual, or permanent inventory was added; create atomic commits containing only verified task-owned changes.
