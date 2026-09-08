# Verification evidence

## Scope

Verified on 2026-09-08. This change adds repository guidance, not an updater implementation or a production OMP release. No patch publication, nix-config push, host activation, production runtime selection, credential change, or source-migration task completion was performed.

## Fresh wrapped sessions

Both sessions started through the installed `omp` command under Herdr, with the immutable personal plugin. Tools were restricted to `read`, `grep`, and `glob`. The ordinary request asked about updating OMP without naming the skill or supplying its body; an explicit read-only restriction prevented update operations.

- **Korolev:** session `01a0800b-02e5-70fb-9bc1-cc91e389ea0e` discovered `skill://omp-update` from this checkout's `.agents/skills/omp-update/SKILL.md`, read the README and operations procedure, and selected the local WSL host scope. Explicit `/skill:omp-update` invocation rendered the authored skill card and distinguished unchanged inputs from installing a generation. It reported verifier and fresh-session checks as unobserved rather than inventing success.
- **macbook-pro:** session `01a08010-251e-7542-a129-5a858077f3ca` used an owned snapshot checkout in a named Herdr session. It discovered the repository skill, read the required procedures, selected Darwin scope, and excluded the WSL browser check. Explicit invocation distinguished a reviewed local pin commit from installed pins and stated that local activation does not require a repository push.

The normal OMP session histories retain the full interactive transcripts. No global skill was installed, no discovery setting was changed, and no second skill copy was added to a user profile.

The standalone `omp read skill://omp-update` command reported no discovered skills. It was not used as discovery proof. The actual wrapped sessions discovered and invoked the skill successfully.

The Mac SSH key denied SSH PTY allocation. The supported named headless Herdr session provided its own application panes without changing SSH policy. Herdr also returned `agent_prompt_stalled` for completed prompts on both hosts. Terminal reads showed the actual responses; the prompts were not repeated based only on that status. The misleading status was reported through automated QA.

## Bounded decision rehearsals

[Recorded fixture inputs and responses](verification.json) cover nine fresh, tool-disabled model decisions: selected but not verified, unchanged, stale pins, native-build failure, publication denial, unavailable administrator interaction, rejected smoke with a previous generation, completed recovery, and rejected first installation.

Initial responses listed potentially redundant pin integration and publication steps. The guidance was clarified to reuse an existing reviewed pin commit and not require a nix-config push for local activation. Two decision rechecks and the Mac explicit invocation exercised that clarification. The initial responses remain in the evidence.

Additional fresh decisions covered model-proposed conflict resolution, the authorized publication-to-acceptance sequence, and partially or fully upstreamed patches. The authorized sequence continued through both-host patch retrieval, local pin integration, Korolev activation, updater selection, verifier, and fresh-session/WSL smoke; it excluded a nix-config push and other-host activation.

These model responses are rehearsals, not evidence that production publication, activation, or runtime acceptance occurred. The real operations below used only disposable local fixtures.

## Real Git and behavior checks

A disposable Git repository contained two maintained fixes and an overlapping upstream change. Rebase failed with a real conflict. A fresh model proposed the combined source for a separate maintenance worktree. That repair retained the upstream `file://` prefix and maintained space encoding. Continuing the rebase retained the independent readable-label fix.

The consumer check failed against the old fixture and passed against the refreshed result. Complete range comparison was inspected. The active and failed fixture worktrees retained identical HEADs, status, and source hashes before and after repair.

A second replay dropped an already-upstream encoding fix and retained one independent label fix; consumer checks passed. A third replay found both fixes upstream and left zero commits. The actual `Updater.fetch_inputs` implementation, using isolated state and local Git sources, rejected that empty range with `The pinned patch range is empty`. No dummy patch or updater bypass was introduced.

`verification.json` retains the relevant Git identities, comparison output, protection checks, model repair, and empty-range result. This change does not modify updater tests or production code.

## Release gates and cleanup

The following commands returned success before final staged-diff review:

- `openspec validate guide-omp-updates --strict`.
- `nix fmt -- --fail-on-change`.
- `nix flake check --all-systems --print-build-logs`: both systems evaluated and the local checks passed.
- Darwin system build: `/nix/store/c8cr1h2pyvq2pg4cwh0snc9lxikpi7pk-darwin-system-26.05.c3e90c8`.
- Native Darwin execution of the packaged `check-darwin-build-plans` for the reviewed snapshot: 37 outputs, none reaching a forbidden source build. The guard package was `/nix/store/4r48s67l00pdkck30r3nc4j6j1cgawg2-check-darwin-build-plans`.

Final staged-diff review found that `nix fmt` converted the skill's YAML frontmatter into Markdown. The original `treefmt.nix` enabled GFM support but not frontmatter support. The authored YAML was restored and acceptance paused for scope approval. The user then approved adding the existing `mdformat-frontmatter` plugin and repeating verification; no formatter exclusion or lock update was introduced.

## Approved formatter repair

`mdformat-frontmatter` 2.0.10 preserved the skill's name and description exactly through the repository formatter. A second pass was byte-identical; the formatted skill SHA-256 was `e14c35724b0343c0fdb5f7b863ca29a13469022e92e46355aa61ea93587b3d1d`.

Fresh formatted-skill sessions repeated automatic discovery and explicit invocation successfully:

- Korolev: `01a08032-a562-737b-b689-9a1d7cbb742f`, using the repository checkout.
- macbook-pro: `01a08033-a8d9-755c-a82a-0e82ea37d671`, using an owned snapshot checkout.

Both sessions read the formatted authored skill and its procedures, selected their local host scope, and respected the read-only verification restriction. Explicit invocation retained the intended distinction between reviewed local pins and repository publication.

A repository-wide formatting run encountered a concurrent change to the unrelated Plannotator evidence file. No unrelated changes were staged. Subsequent gates used the frozen task-owned tree `d7098532e3deb4b1a57d757df51328bf129a70d1`, excluding concurrent unstaged work. Formatting, strict OpenSpec validation, and the all-systems flake check passed on that snapshot. Native Darwin formatting preserved the same skill bytes, and the Darwin treefmt check passed over all 284 selected files. The build-plan guard again checked 37 outputs without forbidden source builds. The repeated Darwin system build produced `/nix/store/lah3w1950wkdhwil397wikymb6scsp0v-darwin-system-26.05.c3e90c8`. These results close the formatter acceptance blocker; they do not validate concurrent unrelated edits.

Nix evaluations were sequential. The owned Korolev pane and named Mac verification session were closed. The Mac session record, temporary checkout, local Git worktrees, isolated updater state, and temporary rehearsal outputs were removed. Repository evidence and normal OMP session histories were retained. No production generation or unrelated session was removed.
