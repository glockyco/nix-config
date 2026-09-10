## Why

The managed OMP setup lacks a visual way to comment on documents and assistant responses. Upstream Plannotator now supplies a standalone annotation interface, so this capability does not require restoring the old Pi-extension fork.

## What Changes

- Supply the unmodified vendor Plannotator package on macbook-pro and korolev through the commit-pinned `plannotator-packages` input.
- Retain on-demand package advancement through `pin-plannotator-on-demand`, without a downstream client-lease patch or custom CI caching.
- Consume a reviewed `omp-agent-setup` plugin revision that provides `/plannotator-annotate <document>` and `/plannotator-last`.
- Open document or response snapshots in the browser and return submitted feedback once to the originating OMP conversation.
- Register Windows executable interoperability through the supported NixOS-WSL module so local browser launch does not depend on a missing startup registration.
- Treat dismissal and cancellation as cancellation, never as approval or an instruction to implement.
- Support `/plannotator-cancel` when tab closure leaves a review pending. Cancel reviews on session navigation and shutdown.
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
- Dependencies: the commit-pinned vendor input supplies Plannotator 0.27.12 with its existing recipe, packaging patches, and dependencies. No local override, custom cache, extra updater, installer, maintained source fork, or third repository is required.
- Approved supersession (2026-09-08): the user dropped the client-lease patch and custom CI cache as disproportionate. Historical patch evidence remains in `evidence.md`. Automatic tab-close settlement is no longer required. No approval mode, new timeout, or fallback replaces it.
- Spec integration: `maintain-patched-omp` already changes the default wrapper contract but is not archived. This delta uses its source-generation contract and must be synchronized after that change, without restoring the older platform-installer wording.
- Acceptance: native browser feedback round trips on both supported hosts, including cancellation and session isolation, are required. No installation or browser verification has occurred during proposal preparation.
