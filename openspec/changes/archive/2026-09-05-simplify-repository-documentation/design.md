## Context

See `proposal.md` for motivation. The documentation mixes human instructions, implementation inventories, historical evidence, and unresolved plans. Design is necessary because removal crosses document owners and can lose recovery instructions or pending intent.

The two earlier cleanup proposals are deferred and disagree on where unscheduled work belongs. Neither is a prerequisite for this change.

## Goals / Non-Goals

**Goals:** Make ordinary use possible from the README, reduce maintained prose rather than relocate it, and preserve essential safety information.

**Non-Goals:** Replace OpenSpec, change accepted runtime contracts, introduce helper commands or generators, automate external provisioning, or execute deferred work.

## Decisions

### 1. Start from reader tasks, not the old document outline

Write a fresh README around purpose, hosts, development/checks, activation, bootstrap, and recovery. Target about 100 lines of readable Markdown, including commands; this is a review target, not a machine-enforced limit. Never meet it through long paragraphs, collapsed sections, or removed safety warnings.

Link to declarations and existing commands for configuration details. Omit exhaustive package lists, directory inventories, implementation walkthroughs, and release snapshots. Keep important ownership boundaries in a few sentences.

Alternative: shorten each existing section. Rejected because it preserves an outline that tries to describe the entire implementation.

### 2. Keep only information that the implementation cannot reasonably supply

For each current document, identify unique operator instructions, rationale, pending intent, and duplicate or historical content before removal. Record the result briefly in the implementation review, not a new permanent inventory.

Keep rationale beside the affected declaration when it explains a non-obvious choice. Link to upstream documentation for standard product procedures. Do not copy configured versions, keys, package lists, or workflow internals into a second reference table. Necessary invocation examples remain appropriate.

Delete `docs/architecture/personal-omp-environment.md` after moving its unique current safety boundaries and rationale to their appropriate owners. Git retains the historical narrative and release evidence; do not manufacture evidence files merely to preserve old prose.

Alternative: generate an architecture manual. Rejected because generated volume still burdens readers and creates tooling to maintain.

### 3. Require concrete justification for an operating-procedure exception

Keep operating documentation minimal. This rule does not apply to unfinished plans under `docs/plans/`. Retain a focused file under `docs/operations/` only if it contains necessary repository-specific bootstrap or recovery steps that make the README unclear. State its task and prerequisites, link it from the README, and keep no duplicated command sequence.

Review WSL import, Windows administrator boundaries, builder credentials, external authorization, and destructive container recovery explicitly. Preserve required ordering, backup conditions, account scope, and manual steps. Do not turn these operations into activation logic to eliminate prose.

Routine update instructions belong in the README or upstream references. Move instructions for another repository to a link to its existing owner; do not change that repository or create an issue here.

Alternative: require literally one file regardless of safety. Rejected because a short entry point must not hide prerequisites for recovery.

### 4. Separate human guidance, agent instructions, and behavioral contracts

The README owns human-facing command instructions and release-gate guidance. `AGENTS.md` contains only repository-specific agent constraints, OpenSpec workflow instructions, and links to the README and relevant declarations. Preserve all applicable release gates and their platform limitations; do not replace them with a link to CI alone.

Review every accepted spec and active change for current references and redundant implementation narrative. Preserve requirement names, behavioral meaning, acceptance conditions, and unrelated scheduling decisions. Do not remove a behavioral guarantee because it lacks a test. Such a correction needs a separate behavior change.

OpenSpec remains the planning workflow, not a destination for the deleted manual. Do not rewrite archived artifacts for current paths or wording. Remove empty template commentary from `openspec/config.yaml` only if it carries no actual configuration guidance; preserve functional settings.

Alternative: exempt OpenSpec and agent files from review. Rejected because readers would still encounter competing current explanations.

### 5. Retire competing cleanup instructions without losing pending work

During implementation, read all artifacts of `align-documentation-with-fleet` and `consolidate-planning-home`. Mark their approach superseded by this change, keeping unchecked tasks visibly unimplemented rather than falsely completed. Do not run an archive operation that merges their unimplemented spec deltas.

Keep every legacy planning file and the existing index. Unfinished plans remain distinct and discoverable, outside the README’s everyday operating path. Do not replace them with summaries inside superseded changes. Reconcile only obsolete references; preserve their decisions, open questions, and unfinished work.

Planning migration requires a separate reviewed change. That review must choose an authoritative home, reconcile existing owners, and verify each complete replacement before removing its original. Exploratory plans need not become implementation-ready proposals. No migration, new planning change, external issue, or live Fastmail action is authorized here.

Preserve unique experiments and external-project intent from the removed architecture in the existing record until that separate review.

Alternative: migrate every record into issues or complete OpenSpec proposals. Rejected because that expands work and creates external state without improving the README.

### 6. Verify usefulness rather than enforce document shape

Review the rendered README and any exception procedure. Walk through locating the correct host activation, release gates, bootstrap prerequisites, and rollback boundaries without opening an architecture manual or archive.

Check current local links and source references. Historical paths in archived changes are not current broken links. Run strict OpenSpec validation and the existing formatter. Do not add line-count tests, forbidden-directory checks, new test fixtures, or documentation generators.

For this documentation-only change, validate command spellings against their actual declarations or CLI help. Do not activate hosts, import distributions, rotate credentials, or execute destructive commands to test documentation. If a rendered surface is unavailable, report that limitation and inspect the Markdown structure directly.

## Risks / Trade-offs

- [Useful recovery knowledge disappears] → Read each affected procedure fully and preserve its necessary prerequisites before deleting its source.
- [The README becomes another manual] → Review against reader tasks and the approximate length target; justify every exception separately.
- [Old plans remain executable-looking] → Add explicit notices to competing cleanup approaches. Preserve distinct unfinished plans and their status without treating them as execution authorization.
- [A prose edit changes a contract] → Compare affected requirements for semantic equivalence; defer behavior changes rather than hide them in cleanup.
- [Documentation reflects concurrent implementation changes incorrectly] → Read the current declarations during implementation and leave unrelated changes untouched.

## Migration Plan

Inventory current documents and unique retained information, then replace the human entry point and migrate essential content. Reconcile agent/spec references and competing plans in the same cutover. Remove obsolete files only after their necessary content has a current owner.

Verify the rendered reading paths, links, command references, formatting, and OpenSpec validity before creating atomic documentation commits. No host activation is involved. Rollback is a revert of the documentation commits, not a Nix-generation rollback.
