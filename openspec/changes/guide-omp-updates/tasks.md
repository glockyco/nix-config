## 1. Authored skill and procedures

- [ ] 1.1 Add `.agents/skills/omp-update/SKILL.md` with explicit metadata, ordinary update and conflict-recovery triggers, concise workflow decisions, and checkout-root procedure references. Review it against `omp://skills.md`; verify it needs no global configuration, plugin release, hard-coded release identity, or duplicate manual.
- [ ] 1.2 Extend `docs/operations/dependency-updates.md` with actionable preflight, routine update, isolated patch refresh, non-conflict failure, publication, pin integration, activation, acceptance, and recovery procedures. Verify every specification scenario has a corresponding decision path, including unchanged inputs, stale installed pins, missing permissions, and an empty remaining patch range; derive command facts from the current updater and README.
- [ ] 1.3 Link the skill from the README update section without duplicating host commands or changing their ownership. Verify links resolve from the checkout root and guidance preserves the runtime, mutable-state, authorization, and existing migration boundaries.

## 2. Real discovery and bounded workflow verification

- [ ] 2.1 Start a fresh wrapped OMP session through Herdr in the repository on Korolev. With a read-only ordinary update request and no supplied skill body, verify discovery of `omp-update`, the resolved authored path, correct procedure reads, and current-host scope; also verify explicit `/skill:omp-update` invocation without running a production update.
- [ ] 2.2 Repeat fresh-session discovery and explicit invocation on macbook-pro in a checkout containing the skill, without global installation, activation, or runtime selection. Record actual host evidence separately and leave this task incomplete if the required runtime or access is unavailable.
- [ ] 2.3 Rehearse successful, unchanged, stale-pin, and non-conflict preparation-failure paths in fresh tool-restricted model sessions with disposable fixtures. Verify the agent selects the appropriate next actions and completion evidence without unnecessary patch changes, repeated failure confirmation, or premature success claims.
- [ ] 2.4 Rehearse an actual Git conflict fixture through isolated range repair and review, then the publication and activation boundaries. Include an upstreamed-patch case and the empty-range limitation. Verify maintained behavior, diagnostic preservation, permission requests, and continuation through the authorized remaining steps; prohibit real publication, activation, and credential changes in the rehearsal.
- [ ] 2.5 Rehearse unavailable publication permission, administrator access, and rejected post-selection smoke with and without a previous generation. Verify precise blockers, authorized source recovery, preserved state, and distinct updated, unchanged, recovered, and blocked reports rather than fabricated completion.

## 3. Release gates and evidence

- [ ] 3.1 Run `openspec validate guide-omp-updates --strict` and the README's applicable release gates with sequential Nix evaluations. Record fresh-session and scenario evidence with this change, distinguishing fixtures from actual host results; verify the skill implementation does not modify updater semantics or close any `maintain-patched-omp` acceptance task.
