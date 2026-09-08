## Context

See `proposal.md` for motivation. This design resolves skill discovery, procedure ownership, authorization, and acceptance boundaries before implementation.

`packages/omp-dev-update.nix` declares the upstream and patch inputs. `packages/omp-dev-update.py` already resolves the latest stable release, replays the pinned range, prepares host-native dependencies, verifies the candidate, and promotes it. It exposes `--status` and `--rollback`; there is no public prepare-only or resume-candidate option. Failed candidates remain available, and unchanged inputs produce a no-op.

The updater already owns frozen dependency installation, native builds, package checks, patch regressions, native loading, and plugin-aware CLI checks. Its Git/state behavior has coverage in `packages/omp-dev-update-tests.py`. The skill must orchestrate these existing interfaces rather than duplicate them.

README owns host commands and release gates. `docs/operations/dependency-updates.md` owns authorization, release smoke, and recovery. The active `maintain-patched-omp` delta describes source updates; the main workstation spec still describes the previous installer workflow. Its remaining acceptance tasks are outside this change.

OMP's `omp://skills.md` documents `.agents/skills/<name>/SKILL.md` discovery, explicit metadata, lazy loading, and name-based precedence. `omp://tools/manage_skill.md` describes a separate mutable managed-skill facility. This authored repository workflow does not use that facility.

## Goals / Non-Goals

**Goals:** Make an ordinary update request actionable without prior conversation history. Keep a short skill entry point, one authoritative procedure, and an evidence-based completion decision.

**Non-Goals:** Change updater semantics, add an executable or scheduler, install a global skill, release the personal plugin, generate OpenSpec adapters, update hosts during skill verification, or close the source migration's outstanding gates.

## Decisions

### Use native repository discovery, not plugin deployment

Create `.agents/skills/omp-update/SKILL.md` with `name: omp-update` and a description that covers updating, upgrading, and repairing failed personal OMP updates in this repository. Leave the skill available for model selection and explicit invocation. Do not hide it, force it into every task, or add discovery configuration.

A global plugin skill would require a separate release and could trigger in unrelated projects. A managed skill would be mutable user state rather than reviewed repository content. Repository discovery matches the requested fresh-session behavior and keeps ownership with the updater.

Keep metadata and the main workflow concise. Reference the detailed repository procedure only when needed. Resolve README and operation-document paths against the checkout root, not the skill asset directory. Do not use `skill://` parent traversal; that protocol prohibits escaping the skill directory. Do not copy the manual into skill assets.

### Keep existing command and procedure ownership

Add the detailed procedure to the existing dependency operations document. Extend the README update entry with a short skill-discovery link; retain its existing activation and release-gate commands as the authoritative command reference.

The procedure needs actionable steps, decision conditions, and completion evidence for these paths:

| Observed state                                               | Next action                                                                                                                                          |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| Installed pins differ from reviewed repository pins          | Review and verify the configuration, obtain missing activation authorization, activate, then use the updated installed command.                      |
| Updater succeeds or reports unchanged inputs                 | Verify the selected generation and perform the applicable fresh-session smoke.                                                                       |
| Patch replay conflicts                                       | Inspect diagnostics, refresh the maintained range separately, verify it, publish with permission, integrate pins, and resume the normal update path. |
| Another preparation phase fails                              | Diagnose and repair that cause without suppressing the failure or replacing the updater.                                                             |
| Fresh-session acceptance fails after selection               | Report rejection and perform authorized source rollback when available, followed by verification.                                                    |
| An approval, credential, or real prerequisite is unavailable | Complete reachable safe work and report the exact blocked operation and runtime state.                                                               |

The skill should continue through authorized steps without unnecessary confirmation at every phase. It must not reinterpret a preparation failure as a publication problem or repeatedly run a reported failing command merely to confirm it.

### Derive the patch refresh from live inputs

Read the installed updater configuration, repository declarations, current status, and failed-candidate metadata. Resolve exact upstream release and patch identities using the existing fetch and ancestry rules. Do not embed today's versions, patch count, or developer checkout paths in the skill.

Refresh a separate maintained worktree, leaving both the failed candidate and active generation intact. Inspect conflicts semantically and compare the old and new ranges. Check that every intended fix remains effective; retire an upstreamed patch only with behavior evidence. Review changelog placement and unintended changes even when replay reports no conflicts.

Use the resolved upstream development environment, frozen dependency installation, native build, relevant checks, and behavior regressions before publication. Reuse the existing updater's phase definitions as the verification reference, not a second permanently copied command list. Isolate candidate application state and avoid aggregate setup commands that install global links. Native artifacts remain host-local.

If all patches become unnecessary, the current updater rejects an empty range. Report that contract limitation and propose a separately reviewed updater change; do not invent a dummy commit or bypass input validation.

Publish a new versioned branch to the declared fork only with explicit permission. Verify exact commit retrieval and ancestry independently from both supported hosts, without using the other host's checkout as the patch source. Update the exact base and tip in nix-config, stage only owned changes, and commit through the personal commit policy. Review applicable Nix gates and activation output before rerunning the installed updater. Configuration publication is a separate authorization from patch publication.

### Define the authorization and completion record

At the start, identify the current host, requested operation, granted permissions, selected generation, and recoverable previous generation. Do not update another host merely because the same repository supports it. Network access for a build or fetch does not authorize remote activation.

Request missing permissions for concrete operations and destinations. Preserve unrelated work and never activate an unreviewed mixed configuration. If administrator interaction is unavailable, provide the exact applicable command without asking for secret contents. Resume after the operator supplies the result; do not claim activation occurred from a build result alone.

Completion means the selected runtime passed `verify-personal-omp` and the documented release smoke, including a fresh wrapped session, immutable personal plugin, current Herdr integration, harmless commit preview, and WSL browser checks when applicable. A previous session can still use an older generation. Report updated, already current, recovered, or blocked distinctly, with exact identities and observed checks. A patch branch, successful build, or version string alone is not an updated-runtime deliverable.

### Verify the guidance in its actual host

Verify metadata discovery in a fresh wrapped OMP session rooted in the repository on each supported host. Ask an ordinary update-related question with an explicit read-only constraint, without supplying the skill body or naming it. Confirm that the session discovers the authored skill, reads the correct repository procedures, and identifies local scope and authorization boundaries. Also verify explicit `/skill:omp-update` invocation. Record the resolved skill path and any discovery warnings; do not solve collisions by installing another copy or rewriting user configuration.

Exercise the decision paths in fresh, tool-restricted model sessions using disposable fixtures. Cover successful and unchanged results, stale installed pins, an actual Git conflict fixture, a non-conflict build failure, missing publication permission, unavailable administrator access, and rejected post-selection smoke with and without a previous generation. Include the no-patches-left boundary. Judge observable decisions and stopping conditions, not exact wording. Restrict these rehearsals from production publication, activation, runtime selection, and credential changes.

These rehearsals validate guidance, not a newly installed production runtime. Distinguish fixture evidence from host runtime evidence. The existing updater tests need no changes or duplicate coverage unless implementation unexpectedly changes their contract. Keep one-off verification scripts disposable rather than adding source-text or mock-echo tests. Run strict OpenSpec validation and the README's applicable release gates. Record evidence with this change.

## Risks / Trade-offs

- Procedure drift: read current declarations and upstream commands at execution time; maintain one detailed operations document.
- Skill shadowing or disabled discovery: verify the resolved skill path in fresh sessions rather than relying on file existence.
- Excessive procedural context: keep the entry point short and load repair details only after a relevant failure.
- Partial success mistaken for completion: require selected-runtime smoke and explicit updated, unchanged, recovered, or blocked outcomes.
- Model rehearsals are not deterministic runtime tests: preserve transcripts and their limits; use real wrapped-session discovery and existing updater evidence separately.
- The source migration is not fully accepted on the Mac: leave its tasks untouched and report any resulting verification blocker without weakening this change's gates.

## Migration Plan

1. Add the skill and extend the existing procedures without changing updater or host configuration.
1. Verify repository discovery and invocation in fresh wrapped sessions on both supported hosts, then complete the bounded decision rehearsals and release gates.
1. Commit the verified repository changes. Publication remains a separately authorized operation; a fresh session in a checkout containing the skill needs no skill installation or activation.
1. Keep verification evidence with this change and archive only after its own acceptance tasks pass. Do not archive or synchronize `maintain-patched-omp` as part of this work.

To withdraw the guidance, revert its repository changes and start a fresh session. This does not select an older OMP runtime or change mutable application state.
