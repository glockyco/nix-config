## Why

The managed OMP setup lacks a visual way to comment on documents and assistant responses. Upstream Plannotator now supplies a standalone annotation interface, so this capability does not require restoring the old Pi-extension fork.

## What Changes

- Supply upstream Plannotator through the existing locked `llm-agents.nix` input on macbook-pro and korolev.
- Consume a reviewed `omp-agent-setup` plugin revision that provides `/plannotator-annotate <document>` and `/plannotator-last`.
- Open document or response snapshots in the browser and return submitted feedback once to the originating OMP conversation.
- Treat dismissal, browser closure, and cancellation as cancellation, never as approval or an instruction to implement.
- Keep adapter behavior in `omp-agent-setup`, executable selection in `nix-config`, and preferences, history, and temporary files in writable runtime storage.
- Preserve the no-inbound network boundary: annotation servers are temporary and loopback-only, with no tailnet publication or firewall change.
- Exclude plan mode, approval gates, automatic edits, code review, pull requests, sharing, and the full Pi extension.

## Capabilities

### New Capabilities

- `omp-visual-feedback`: Document and last-response annotation, feedback delivery, cancellation, and the cross-repository executable/adapter contract.

### Modified Capabilities

- `personal-omp-workstation`: Add the pinned annotation executable to the normal wrapper environment and clarify the loopback-only annotation exception to WSL network isolation.

## Impact

- `nix-config`: `packages/personal-omp.nix`, the wrapper composition and checks in `flake.nix`, the `personal-omp-plugin` lock, and existing usage/release documentation.
- `omp-agent-setup`: a dedicated extension under `plugin/extensions/`, its manifest entry, the narrow host API declarations, affected plugin checks, and command documentation. This repository's apply scope does not authorize edits there; delivery requires a separately authorized companion change and reviewed plugin revision.
- Dependencies: the current `llm-agents` pin already supplies Plannotator 0.27.12. No extra updater, installer, source fork, or third repository is proposed.
- Spec integration: `maintain-patched-omp` already changes the default wrapper contract but is not archived. This delta uses its source-generation contract and must be synchronized after that change, without restoring the older platform-installer wording.
- Acceptance: native browser feedback round trips on both supported hosts, including cancellation and session isolation, are required. No installation or browser verification has occurred during proposal preparation.
