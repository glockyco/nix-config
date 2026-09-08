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

## Initial release blockers (superseded by downstream-first delivery)

The local upstream commit has no published package revision yet. A local checkout path is not a substitute for a reviewed cross-host package pin. The production locks therefore remain unchanged.

Release remains blocked on:

- Authorized upstream publication/submission and a reviewed `llm-agents.nix` package containing the fix for both host systems.
- Authorized companion publication and selection of both compatible production pins. Wrapper argument plumbing is implemented, but task 3.1 remains incomplete until it selects the compatible package on both hosts.
- Review, merge, activation authorization, both hosts' native release gates, Windows-browser/Herdr and macOS browser round trips, tailnet ingress refusal, and rollback checks.
- Completion and synchronization of `maintain-patched-omp`, whose Mac acceptance and final routing tasks remain unchecked.

The workstation current-state manuals and accepted specs remain unchanged. Their update and archive tasks require the pending native acceptance. Task-owned smoke processes, scripts, and temporary data are removed after verification; the upstream source checkout and its committed fix are retained.

## Downstream-first package delivery

The revised contract supersedes the initial upstream-publication blockers above. No upstream branch or PR is required or submitted. The existing `llm-agents` and companion input locks remain unchanged during this package work.

`packages/plannotator.nix` appends `packages/plannotator-client-lease.patch` through `overrideAttrs`. Both wrapper compositions use this shared override. The existing recipe, packaging patches, upstream source, and dependency handling are retained. The checked-in patch includes the reviewed lifecycle regressions.

- Base: `v0.27.12`, commit `96313ab228ede843203d38d9d2a86e1c87e18c81`.
- Originating fix: `420ee6c0bca735eece1d623aa7bfe25445c82771`.
- Patch SHA-256: `c1773bb47f9f84f40cc3bfcdc1356661b8469977a3d5df3201da39285afbc892`.
- Linux output: `/nix/store/a7vjjwsnwwmqjy4zl2rj5a7vlwl63czl-plannotator-0.27.12`.
- Darwin output: `/nix/store/7li8lm8h96v92h17iygzn09yknpixn2a-plannotator-0.27.12`.
- Darwin derivation: `/nix/store/cmhw2xbsfg8k8jp6h8hwpmn9blp3j9n9-plannotator-0.27.12.drv`.

The Linux build initially planned 2,245 derivations. Its 20-minute command deadline expired during dependency preparation, not a reported compiler failure. Resuming with completed store outputs finished in 138.40 seconds. The executable reports `plannotator 0.27.12`; the patch and output identity distinguish this downstream build.

The distributed Darwin attempt was cancelled during slow SSH input transfer. The same staged repository tree (`c0bd4947ecc387b1e63a2faecf6b28e932061022`) was then copied to a temporary Mac directory. A Mac-local `nix build` succeeded in 11 minutes 51 seconds using the installed Determinate Nix. It produced the same Darwin derivation identity that the local evaluation selected. No package recipe, input pin, credential, service, or activation policy changed to perform this build.

The final Linux package passed an actual managed-Chromium check: `gate=false`, `sharingEnabled=false`, and client lease grace `30000` ms. A two-second disconnect followed by reconnection kept the review available beyond the original disconnect deadline. Closing the final tab produced exactly `{"decision":"dismissed"}` with exit code 0. The listener became unreachable and the source document remained unchanged. This proves the Nix-built Linux lifecycle, not the pending native Windows/Herdr or macOS browser gates.

The dependency operations runbook now documents patch review, both-platform builds, lifecycle verification, and removal only after equivalent native behavior passes. The package smoke process exited and its temporary local data was removed.

The configured Home Manager package on each host was evaluated and asserted equal to its flake package’s Plannotator selection. Korolev selected wrapper `/nix/store/j8cjbvvabspqjkvvvac5lc14x0m07nk9-omp`; macbook-pro selected `/nix/store/rxxan032px9vv2z3qkshas0z4bn5hkhp-omp`. Both selected the patched output listed above. The two wrapper dry-run plans evaluated successfully. The Linux store does not contain the Mac-local outputs, so its Darwin dry-run still listed those derivations; this is not evidence that the Mac must rebuild them.

Ordered Linux formatting and all 27 applicable flake checks passed with the patched package, including the Korolev system and Home Manager closures. The command explicitly omitted Darwin. Final both-host release acceptance remains incomplete until the companion selection and native browser gates pass.

The Mac then checked staged tree `f0a1dc82db19e162a1953073f35013152733713f` in the same temporary directory. Ordered formatting and all eight applicable native flake checks passed. `check-darwin-build-plans` inspected 37 outputs and found no forbidden source build. The subsequent Darwin system build passed and produced `/nix/store/871jzk0rlar4x9mkqbzafdb0mfjpyzhh-darwin-system-26.05.c3e90c8`. These are package-integration checks with the unchanged companion lock, not acceptance of the final adapter selection. Tasks 4.1 and 4.2 remain unchecked for that final selection. No activation occurred. The task-owned Mac snapshot was removed after the commands completed; no store outputs or previous generations were deleted.

At this package checkpoint, companion `main` still named `4707024f3c20031a3650dc98db74940f0ae9a648`. Publication and final selection were not yet authorized. The following verification supersedes that blocker.

## Published companion and final pin verification

The user authorized publication of the reviewed companion commits and selection of that revision, without host activation or Plannotator upstream submission.

- Published `0e39f18` and `e6f340d` to `glockyco/omp-agent-setup` main. [Companion CI passed](https://github.com/glockyco/omp-agent-setup/actions/runs/34222449063).
- Selected revision: `e6f340d7ba02aeee91d36204913e20e2245985a0`.
- Selected source hash: `sha256-UEc9YGKOzpwvkSr9keStn7sUEsv/yus/UsTHDmerkzA=`.
- Comparing parsed lock nodes before and after the update found only `personal-omp-plugin` changed. The `llm-agents` input remained unchanged.
- The downstream patch SHA-256 remained `c1773bb47f9f84f40cc3bfcdc1356661b8469977a3d5df3201da39285afbc892`.
- Final Linux plugin: `/nix/store/i8wicgnzcnd3afxkvl3v4wc87sndgbvv-personal-omp-plugin-0.1.0`.
- Final Linux wrapper: `/nix/store/z1pa0mzl20j3iskghnfgj88lqhh8yi8v-omp`.

Ordered formatting and all 27 applicable Linux flake checks passed with the final pin, including the Korolev system build. The Mac checked staged tree `8bb5f6ca2a69cd1d2d37fafb7e17701af090eba6`. Ordered formatting and all eight applicable Darwin flake checks passed. The subsequent build-plan guard inspected 37 outputs without a forbidden source build. The final Darwin system build produced `/nix/store/zcpavv0mp30h3lrg6lc72ncdsgg9hpsd-darwin-system-26.05.c3e90c8`. These checks complete tasks 4.1 and 4.2 for the final selection.

The candidate Linux `verify-personal-omp` passed against the existing selected source generation. It reported OMP 18.1.14, commit `16a6bd10e859ca26a0011ed5ba26d4c260e2b754`, the final plugin above, patched Plannotator 0.27.12, and current Herdr integration v8. A real candidate-wrapper TUI session recognized `/plannotator-cancel` and reported no pending review. `/plannotator-last` correctly rejected its empty conversation. This startup and command smoke does not replace the native browser feedback matrix.

The smoke process stopped and the task-owned Mac snapshot was removed. No activation, source-generation update, upstream submission, or Nix store deletion occurred. The workstation commit remains local. Native browser, network, rollback, and specification integration gates remain open.
