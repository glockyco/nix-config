# Implementation evidence

## Scope and release boundary

The user authorized local implementation in `nix-config`, the companion `omp-agent-setup` repository, and a local upstream Plannotator checkout. Nothing has been published, merged, or activated. External release and native-host acceptance tasks remain incomplete until their stated gates pass.

## Upstream annotation-only cancellation

- Checkout: `/home/user/src/github.com/backnotprop/plannotator`.
- Base: upstream tag `v0.27.12`, commit `96313ab228ede843203d38d9d2a86e1c87e18c81`.
- Local fix: `420ee6c`, branch `fix/annotation-only-client-lease`.
- Change: enable the existing client lease for local direct JSON annotation without requiring approval mode. Hook, plaintext, remote, and tailnet-published sessions retain their exclusions.
- Dependencies: `bun install --frozen-lockfile` passed with Bun 1.4.0.
- Build: `bun run build:review`, `bun run build:hook`, and standalone CLI compilation passed. The local binary reports `0.27.12-local-annotate-lease` through its version interface.
- Focused tests: 94 passed, 0 failed, 366 assertions across the annotation-output, shared lease, editor lease, annotation-server, and real CLI lease test files.

### Browser reproduction and confirmation

Both runs used the actual annotation editor in managed Linux Chromium against a local CLI. These checks do not constitute the Windows-browser or macOS native acceptance gates.

1. The pinned baseline package displayed the document without approval controls. After unloading its tab, its listener still returned HTTP 200 after 74 seconds.
1. The patched runtime advertised `mode=annotate`, `gate=false`, `approvalNotesSupported=false`, and a client lease with a 30,000 ms reconnect grace.
1. A two-second disconnect followed by reconnection kept the patched review available beyond the original disconnect deadline.
1. Closing the final managed browser tab caused the patched CLI to emit exactly `{"decision":"dismissed"}` and exit successfully. Its listener was no longer reachable afterward.
1. The input document remained byte-for-byte unchanged.

The lease starts after the server detects the last connected client disconnecting. CLI settlement adds its existing 1.5-second delay. A browser that never connects still requires explicit cancellation. A separate run with browser opening disabled remained available after 47 seconds without a client lease connection, then was explicitly stopped.

### Protocol observation

The annotation-only UI's **Done** button returned `{"decision":"annotated","feedback":"User reviewed the document and has no feedback."}` with exit code 0. This is ordinary upstream feedback, not an approval signal. The adapter must not infer semantics from this wording.

## Companion plugin change

The companion change is `omp-agent-setup/openspec/changes/add-plannotator-visual-feedback`. Its artifacts were created before adapter source edits. The implementation checkpoint is `0e39f18` in the local companion repository; it has not been published.

Validation passed on `x86_64-linux`:

- `nix develop --command bun run ci`: Biome, TypeScript, Knip, production dependency audit, and 28 Bun tests passed. The audit found no vulnerabilities.
- `nix flake check --print-build-logs`: all applicable Linux checks passed, including 28 immutable-payload Bun tests, 9 Python tests, package shape, OpenSpec contracts, and generated-adapter freshness. Native Darwin checks were not run.
- `openspec validate add-plannotator-visual-feedback --strict`: passed.

The retained behavior tests cover source changes, missing sources, visible response selection, navigation races, concurrent sessions, process-group cancellation, preparation cancellation, protocol errors, and unavailable inputs. Existing `personal_commit` tests still create real commits with hooks enabled.

### Real OMP and browser smoke

A temporary Nix wrapper combined the local upstream binary with the immutable companion package. This override was used only for verification; no local checkout path entered a production lock.

- Corrected plugin output: `/nix/store/s2m8w0ck6gwnl1kq732xhnch476b9krj-personal-omp-plugin-0.1.0`.
- Corrected smoke wrapper: `/nix/store/nwj5rw11w7b2rgdfizmw3d14sbcvmnmr-omp`.
- OMP used the existing host-local source generation. A throwaway observer recorded branch messages and native `local://` mappings without adding model tools or editing managed configuration.
- Two simultaneous real OMP sessions resolved `local://annotation-smoke.md` to different session directories and displayed their respective contents in the actual browser editor.
- A source-linked replacement suggestion returned once after an active OMP turn. The feedback identified the captured response, session, branch anchor, and snapshot hash.
- Cancelling one concurrent review removed its private snapshot while the other review still returned HTTP 200 and retained its snapshot.

The initial real idle-session check found a host integration bug: explicit `sendUserMessage` follow-up delivery left feedback queued without starting a turn. The adapter now uses user-attributed `sendMessage` with `deliverAs: "followUp"` and `triggerTurn: true`.

The corrected package passed fresh idle and busy round trips in one real OMP session. Exactly two feedback messages were recorded, and the assistant responses appeared in this order:

```text
Idle feedback received.
Busy turn finished.
Queued feedback received.
```

The document remained byte-for-byte unchanged. `/plannotator-last` displayed the completed visible response with `gate=false` and `sharingEnabled=false`.

A separate real session inherited port `9999`, enabled sharing, a tailnet URL host, and invalid browser overrides. Its child instead listened on `127.0.0.1:37629`, with sharing and gate mode disabled. Explicit cancellation removed its private snapshot. The selected data directory remained isolated test data.

The browser interactions used managed Linux Chromium. Although the adapter invokes upstream's native browser launcher, these observations do not prove the Windows-browser/Herdr or macOS release gates.

## Workstation wrapper checks

The wrapper, verifier, and shared host composition now accept Plannotator as a separate runtime dependency, not as a language server. Formatting passed for the changed Nix files.

The ordered repository gates also passed on `x86_64-linux`: `nix fmt -- --fail-on-change`, then `nix flake check --print-build-logs`. The latter built the Korolev system closure and passed all applicable Linux checks. It omitted `aarch64-darwin`, so the both-host release task remains incomplete.

The following Linux checks passed against the currently pinned executable and plugin:

- `personalOmpGeneration`: pinned Plannotator wins over a conflicting caller executable, while arguments, working directory, nested OMP resolution, and source/application state remain correct.
- `personalOmpVerification`: the explicit verifier reports and validates the Plannotator package version and executable path alongside OMP generation, plugin, and Herdr identity.
- `personalOmpShape`: required existing plugin and language capabilities remain present without assuming exactly one extension.
- `ompBrowserRuntime`: the wrapper still contains no Nix-packaged browser.

Darwin wrapper evaluation and dry-run build planning passed. The plan needs one wrapper derivation and cached Plannotator/ICU paths, not a local Plannotator source build. This is not native Darwin runtime acceptance.

The evaluated OMP activation entry on both hosts invokes only the existing `reconcile-herdr-omp` command. No annotation launch or preparation was added. Korolev still evaluates with empty allowed TCP/UDP port lists and OpenSSH disabled. The existing source-update and Herdr ownership boundaries remain unchanged.

The compatible upstream and companion plugin pins have not been published or selected. These checks prove the wrapper changes, not the complete visual-feedback installation.

## Pending release evidence

The local upstream commit has no published package revision yet. A local checkout path is not a substitute for a reviewed cross-host package pin. The production locks therefore remain unchanged.

Release remains blocked on:

- Authorized upstream publication/submission and a reviewed `llm-agents.nix` package containing the fix for both host systems.
- Authorized companion publication and selection of both compatible production pins. Wrapper argument plumbing is implemented, but task 3.1 remains incomplete until it selects the compatible package on both hosts.
- Review, merge, activation authorization, both hosts' native release gates, Windows-browser/Herdr and macOS browser round trips, tailnet ingress refusal, and rollback checks.
- Completion and synchronization of `maintain-patched-omp`, whose Mac acceptance and final routing tasks remain unchecked.

The workstation current-state manuals and accepted specs remain unchanged. Their update and archive tasks require the pending native acceptance. Task-owned smoke processes, scripts, and temporary data are removed after verification; the upstream source checkout and its committed fix are retained.
