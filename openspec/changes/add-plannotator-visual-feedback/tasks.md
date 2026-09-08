## 1. External delivery prerequisites

These artifacts authorize planning only. Applying this repo-local change does not authorize edits or publication in `omp-agent-setup` or upstream Plannotator. Tasks in sections 1 and 2 record required external deliverables; keep them incomplete until separately authorized work supplies evidence. Adapter development can proceed independently of upstream lifecycle work, but workstation acceptance requires both.

- [ ] 1.1 Deliver a separately authorized companion OpenSpec change in `omp-agent-setup` for the adapter contract in this change; verify its proposal, specs, design, and tasks pass strict validation and link its identity here.
- [ ] 1.2 Obtain upstream annotation-only client-lease support without `--gate`; verify in the actual browser that closing a local `annotate --json` tab returns `dismissed` after a finite documented grace period, while a brief reconnect does not cancel it.
- [ ] 1.3 Identify the reviewed `llm-agents.nix` package revision containing that upstream support; verify the package version, source identity, and availability for `aarch64-darwin` and `x86_64-linux`, and record them here. Do not publish or update unrelated inputs without authorization.

## 2. Companion plugin delivery

- [ ] 2.1 Add `/plannotator-annotate`, `/plannotator-last`, and `/plannotator-cancel` through `plugin/extensions/plannotator.ts` and the plugin manifest; verify discovery in a real OMP session and confirm no planning, approval, code-review, or PR commands are registered by this adapter.
- [ ] 2.2 Implement document snapshots using session-relative filesystem paths and the native `local://` resolver; verify a path containing spaces, two sessions with different `local://` contents, unsupported targets, and source-file immutability.
- [ ] 2.3 Implement last-response selection from the active branch; verify the selected visible response excludes thinking, tool data, hidden messages, and other branches, and that an empty conversation launches no review.
- [ ] 2.4 Implement the annotation-only subprocess protocol and narrow host type declarations; verify a real `annotate --json` feedback round trip without gate flags and verify missing executable, startup failure, malformed JSON, and unexpected decision errors inject no feedback.
- [ ] 2.5 Bind feedback to the captured session, branch, and source snapshot; verify queued follow-up delivery while OMP is busy, duplicate-result rejection, cancellation on navigation, and a stale-source warning after an external edit.
- [ ] 2.6 Implement pending status, explicit cancellation, one review per session, and independent concurrent sessions; verify command access remains available while reviewing and cancellation releases only that review's process, listener, and temporary files.
- [ ] 2.7 Constrain the child to local interactive use and loopback networking; verify noninteractive/remote invocation fails clearly and inherited environment settings cannot silently publish the review or enable approval mode.
- [ ] 2.8 Replace affected incidental one-extension assertions in `plugin/tests/plugin-load.test.ts` and `flake.nix`; retain behavioral regressions for cancellation races, session isolation, source identity, and errors. Verify `personal_commit` still works and the existing plugin CI and flake checks pass.
- [ ] 2.9 Deliver the reviewed plugin revision and existing-document updates describing the three commands, supported inputs, cancellation, and non-goals; verify the package includes the adapter and record release evidence here. Publication requires explicit authorization.

## 3. Workstation composition

- [ ] 3.1 Pass the compatible Plannotator package through every `packages/personal-omp.nix` call site and add it to wrapper-local runtime inputs, separately from language servers; verify both host evaluations and inspect their build plans without adding another packaging route.
- [ ] 3.2 Advance only the required executable-package and `personal-omp-plugin` pins to the reviewed compatible revisions; verify the locked source identities match the external delivery evidence.
- [ ] 3.3 Extend `verify-personal-omp` to report the selected Plannotator path and version without starting a browser; verify it still reports the source-generation identity, immutable plugin, and current Herdr integration.
- [ ] 3.4 Update affected wrapper and plugin-discovery checks in `flake.nix`; verify pinned Plannotator takes precedence over a conflicting caller executable while argument forwarding, working directory, nested OMP resolution, and parent-shell isolation remain unchanged.
- [ ] 3.5 Verify evaluated activation declarations contain no Plannotator invocation, installer, generated extension copy, mutable OMP configuration rewrite, firewall opening, or tailnet publication; preserve the existing source-update and Herdr ownership contracts.

## 4. Release and native acceptance

- [ ] 4.1 Run `nix fmt -- --fail-on-change` and then `nix flake check --print-build-logs` in the documented order; verify applicable checks on both native systems and record results with this change.
- [ ] 4.2 On macbook-pro, run `nix run .#check-darwin-build-plans` and then `nix build .#darwinConfigurations.macbook-pro.system`; verify both gates pass without depending on the borrowed Air.
- [ ] 4.3 After review and merge, activate each host, inspect activation output, and run `verify-personal-omp` plus the existing real wrapped-session release smoke; record both immutable package paths and confirm normal personal plugin behavior remains available.
- [ ] 4.4 In a real local OMP session through Herdr on korolev, annotate a document and the last response in the Windows browser; submit highlighted comments and replacement suggestions, and verify correct source attribution, one feedback delivery, no source edits, and no approval controls.
- [ ] 4.5 Repeat the document and last-response feedback round trips in a real wrapped OMP session and local browser on macbook-pro; record the observed browser surface and feedback in that session.
- [ ] 4.6 On both hosts, exercise dismissal, tab closure, brief reconnect, explicit cancellation, a browser that never connects, session/branch navigation, and two simultaneous sessions; verify the documented close grace period, no cross-session delivery, and owned process/listener/snapshot cleanup.
- [ ] 4.7 Verify the live review listeners bind only to loopback and that another tailnet node cannot reach korolev's review; confirm the local Windows browser still works with no firewall or tailnet policy change.
- [ ] 4.8 Verify Nix rollback restores the previous wrapper, plugin, and Plannotator selection while preserving OMP source-generation selection and mutable OMP/Plannotator data; retain the previous generation until both hosts pass acceptance.

## 5. Documentation and specification integration

- [ ] 5.1 After native smoke passes, update the existing workstation README and dependency operations release smoke with command usage, ownership, cancellation, and recovery; verify instructions name no planner, gate, PR feature, installer, or extra updater. Remove only task-owned throwaway verification data.
- [ ] 5.2 Record upstream, plugin, package, browser, lifecycle, and platform evidence with this change; verify every external prerequisite and acceptance task has concrete evidence rather than inferred success.
- [ ] 5.3 After `maintain-patched-omp` passes its own acceptance and synchronizes its default-command delta, reconcile this delta against the resulting main spec; verify no source-generation contract is reverted and the Plannotator runtime addition survives synchronization.
- [ ] 5.4 Run `openspec validate add-plannotator-visual-feedback --strict` and archive only after all tasks pass; verify the resulting main specs preserve annotation-only behavior and the no-inbound network boundary.
