## Context

See `proposal.md` for motivation and the delta specifications for behavior. This is a cross-repository integration with a process-lifecycle and network boundary, so a design artifact is required.

Observed during the initial investigation (implementation evidence is recorded separately in `evidence.md`):

- `packages/personal-omp.nix` loads an immutable plugin and supplies language servers through its wrapper-local `PATH`. It selects a host-local OMP source generation.
- The locked `llm-agents.nix` revision `b1c9a31450a814e50cddc3ab683b05c1dff7bb01` packages upstream Plannotator 0.27.12 for both host systems. The package builds the browser assets into the executable.
- `omp-agent-setup/plugin/package.json` currently declares only `personal-commit.ts`. Both repositories have checks that assume exactly one extension.
- The plugin repository keeps a deliberately narrow OMP type surface in `types/omp.d.ts`; its existing plugin-loading test uses a minimal registration host.
- OMP 18.1.13 exposes command registration, session and branch events, follow-up messages, and `localProtocolOptions`. Its exported `internal-urls` package includes `resolveLocalUrlToFile`, which checks containment and resolves against the supplied session context.
- Upstream `annotate --json` returns `annotated` feedback or `dismissed`. The `--gate`, `--hook`, and strict approval flags are not needed for visual feedback.
- In 0.27.12, `supportsAnnotateClientLease` requires `gate && json && !hook && !isRemote`. Therefore plain annotation does not yet satisfy our automatic tab-close cancellation contract.

Source references:

- [Pinned Nix package](https://github.com/numtide/llm-agents.nix/blob/b1c9a31450a814e50cddc3ab683b05c1dff7bb01/packages/plannotator/package.nix)
- [CLI arguments](https://github.com/backnotprop/plannotator/blob/v0.27.12/apps/hook/server/cli.ts)
- [Annotation outcomes and client-lease eligibility](https://github.com/backnotprop/plannotator/blob/v0.27.12/apps/hook/server/annotate-output.ts)
- [Browser launch handling](https://github.com/backnotprop/plannotator/blob/v0.27.12/packages/server/browser.ts)

## Goals / Non-Goals

**Goals:**

- Keep the agent-specific integration at the executable boundary rather than importing Plannotator's server or Pi orchestration.
- Retain source identity, isolate concurrent sessions, and make cancellation independent of model execution.
- Reuse the existing plugin release and workstation pinning process.

**Non-Goals:**

- General URL, HTML, folder, PDF, or arbitrary internal-resource annotation. The selected inputs are UTF-8 text/Markdown files, native `local://` files, and the last visible response.
- Remote browser access, ACP/RPC interaction, browser automation features, or a Windows-native Plannotator installation.
- New agent tools that start reviews autonomously, keyboard shortcuts, planning commands, approval buttons, or automatic source edits.
- A separate adapter repository or a maintained Plannotator fork.

## Decisions

### Keep this change as the workstation integration contract

This change records the end-to-end contract in `nix-config`. A separately authorized companion change in `omp-agent-setup` must deliver the adapter before workstation acceptance. Its implementation must use the contracts here; this change does not expand the CLI's repo-local edit boundary.

The external deliverable includes `plugin/extensions/plannotator.ts`, its manifest registration, the narrow type additions, behavioral regression coverage, and user documentation. It exports the existing plugin package rather than a second flake or deployment mechanism.

Alternative: put the adapter in `nix-config`. Rejected because it would split personal agent behavior between repositories. A third repository adds an unnecessary release boundary.

### Extend the existing packaged executable downstream

The default delivery path does not depend on an upstream contribution. Keep the reviewed annotation-only client-lease patch in `nix-config`, recording its upstream base and originating local commit `420ee6c`. Extend `llmAgents.plannotator` with `overrideAttrs` and append the patch to its existing patches. Preserve the source pin, dependency lock, offline dependency handling, and upstream build recipe. Do not copy the recipe or fetch a patch from a mutable branch or PR URL at build time.

Define the patched package once and pass it into `packages/personal-omp.nix` in both host compositions. Add it to wrapper runtime inputs without classifying it as a language server. The adapter invokes the command name; it contains no Nix paths or installation code.

Extend explicit verification to report the selected Plannotator version and path. Replace incidental exact-one-extension assertions in both repositories with discovery checks for the required capabilities. Preserve existing `personal_commit`, LSP, and generated OpenSpec behavior.

Use the existing dependency-update review process. Each package update must verify patch applicability and annotation-only behavior. A rejected or unsubmitted upstream contribution does not block release; retain and maintain the downstream patch. Remove it only when the selected package provides equivalent behavior and the applicable native checks pass.

Upstream submission is deferred until downstream delivery and acceptance are complete, and remains optional afterward. Do not publish a branch, open a PR, or work on upstream submission as a prerequisite. Companion plugin publication is a separate workstation dependency operation, not an upstream contribution; existing explicit publication and activation authorization boundaries remain in force.

Do not run upstream's installer or change `omp-dev-update`, activation ownership, Herdr's generated extension, or mutable OMP configuration.

### Use one annotation-only subprocess path

Both annotation commands create a private temporary Markdown snapshot and invoke `plannotator annotate <snapshot> --json`, without approval or hook flags. This makes the last-response path independent of Plannotator's session-log detection and keeps the outcome protocol identical for both commands.

Use argv-based process launch with no shell interpolation. A per-review child environment selects local mode, a random local port, and no automatic publication. Keep the browser selection platform-native; upstream already detects WSL and macOS. Do not set a Linux executable as `PLANNOTATOR_BROWSER` on WSL: that upstream branch invokes it through `cmd.exe`.

A direct subprocess API is appropriate here because `pi.exec` has no per-child environment option. The extension must retain cancellation ownership, drain stdout and stderr, validate the final JSON decision, and distinguish process failure from a negative user outcome. Unknown decisions, including an unexpected `approved`, are errors rather than authorization.

Only non-empty `annotated` feedback is delivered. Empty submissions and `dismissed` outcomes produce a user-visible completion/cancellation notice without a model turn. The extension does not interpret text inside annotations as a control protocol.

### Bind reviews to an exact session and source

Capture the session identity and current branch anchor when starting a review. Use the session's branch entries for `/plannotator-last`, selecting the latest completed assistant entry with visible text. Exclude private thinking and tool content.

Resolve ordinary paths against `ctx.cwd`. Resolve `local://` through the host's exported `resolveLocalUrlToFile` and `ctx.localProtocolOptions`, not a copied URI parser. Reject other schemes explicitly. This avoids the old fork's newest-session-directory heuristic and its incomplete resource discovery.

Keep the original target or response identity, snapshot bytes, and a content hash for the review lifetime. The feedback envelope includes the source identity and snapshot hash, and preserves the annotation excerpts. For document inputs, compare current content before delivery and warn if it changed or disappeared. Never overwrite the source from browser suggestions.

Deliver a visible, user-attributed `plannotator-feedback` message with `sendMessage`, `deliverAs: "followUp"`, and `triggerTurn: true`. The host queues it during active work and starts a turn when idle. Explicit `sendUserMessage` follow-up delivery alone does not start an idle turn. This resumes conversation handling without forcing edits or a planning transition. Session switches and branch navigation cancel the review before any late result can be delivered. A one-time settlement guard prevents duplicate delivery.

### Own the complete review lifetime

One session may hold one active review. A second request reports the existing review instead of replacing it. Different sessions use separate snapshot directories, child processes, and random ports.

Register `/plannotator-cancel` and expose pending review status. Command handlers must not hold the command interface until the browser closes; the user must remain able to cancel. Cancel on session shutdown or navigation. Terminate only the owned process and its descendants, then remove owned temporary files. Do not delete Plannotator history or preferences.

The selected package must provide annotation-only client leases without enabling `--gate`. Deliver the verified local fix through the checked-in downstream patch. It must distinguish tab closure from brief reconnects and produce `dismissed` after a finite grace period. Verify that grace period with the final Nix-built package in the real browser and document it.

Acceptance depends on verified package behavior, not upstream submission or acceptance. Do not ship a gate-mode workaround, inject a private browser script, or silently weaken the cancellation requirement. Explicit cancellation remains necessary for browser-launch failure and other cases where no client ever connects.

### Preserve the network and runtime boundaries

Require local interactive invocation. Do not provide remote mode or Tailscale Serve arguments. Confirm that the actual child binds only to loopback and that the local Windows browser reaches WSL without a firewall change. If that path fails, the release remains blocked; do not widen the listener.

Plannotator's upstream UI may retain unrelated product features. The adapter must not expose their commands, invoke sharing, or enable approval mode. Removing unrelated upstream UI elements is not part of this change.

The existing WSL specification literally prohibits every listener. The delta narrows that wording only for temporary local annotation while preserving refusal of all tailnet ingress. No tailnet policy or credential changes are proposed.

### Reconcile the pending wrapper specification in order

The accepted main spec still describes Homebrew and standalone OMP ownership. `maintain-patched-omp` contains the source-generation contract already implemented by the current wrapper. The modified default-command requirement here includes that pending contract and adds Plannotator.

Synchronize this delta only after `maintain-patched-omp` has passed its own acceptance and its default-command delta is synchronized. Do not mark that change complete or edit its artifacts as part of this proposal. Recheck the shared requirement before archival so later synchronization cannot remove Plannotator or restore obsolete update routing.

## Risks / Trade-offs

- **Downstream patch maintenance:** The local fix passed focused tests and managed-browser smoke, but the final Nix-built package still needs native acceptance. Review conflicts and behavior on every dependency update. Upstream rejection does not remove the patch or weaken the contract.
- **Personal plugin API types can drift:** Extend only used host declarations and verify through the real wrapped OMP runtime, not registration doubles alone.
- **Feedback can arrive after navigation:** Cancel on navigation and verify captured ownership again before delivery.
- **The source can change during review:** Keep an immutable snapshot and identify stale feedback rather than attributing it to newer content.
- **WSL browser launch can fail silently upstream:** Keep explicit cancellation available and require a Windows-browser round trip before acceptance.
- **The patch changes the package derivation:** Expect new builds on both architectures rather than cache hits for the unmodified package. Inspect both build plans and retain the Darwin build-plan gate. Reuse the existing recipe instead of introducing a second packaging route.
- **Other unmanaged plugin consumers may lack the executable:** Report an actionable missing-command error on invocation without preventing normal OMP startup. Never install it automatically.

## Migration Plan

1. Package the reviewed local client-lease fix as a checked-in patch on the existing pinned `llm-agents.nix` derivation. Build and verify it on both supported systems without upstream publication.
1. Deliver the separately authorized plugin change and run its existing CI, flake checks, and real OMP command smoke. Record the reviewed revision; publication remains an explicit authorized operation.
1. Select the patched executable and reviewed companion plugin together in `nix-config`. Retain the existing executable-package input unless a verified build requirement needs an update. Do not advance unrelated inputs.
1. Run the existing repository release gates in their documented order. Run the extra Darwin build-plan and system-build gates on macbook-pro.
1. After review and merge, activate each host, inspect activation output, run `verify-personal-omp`, and perform the real wrapped-session annotation matrix. Keep evidence with this change.
1. Update existing usage and release documentation after the smoke proves the behavior. Remove throwaway verification data, not user history.
1. Retain previous Nix generations until both hosts pass. Nix rollback restores the previous wrapper, executable, and plugin without changing the selected OMP source generation or mutable user state.
1. Synchronize the overlapping wrapper specification in the required order and archive only after every task and native acceptance gate passes.
