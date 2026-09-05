## Current scope: 2026-09-05

Follow [near-term priorities](../../../docs/architecture/personal-omp-environment.md#near-term-priorities). The prebuilt cutover is deployed; acceptance is incomplete. Keep the installed architecture and artifact selection while checking OMP in actual repositories. Linux C# remains a specific failed integration, not a blocker for separately verified OMP file/shell use or Tailscale connectivity.

No upstream patches, dependency forks, platform-executable patches, protocol adapters, hidden retries, or workstation-generated solution files are scheduled. Inspect the actual C# repository first and use its existing solution if present. A direct Roslyn diagnostic control is not wrapped-session acceptance. Do not replace packages or project structure merely to make a fixture pass. Preserve all language acceptance gates and keep this change open until they pass; optional fleet work and deferred refactors are not prerequisites.

## 1. Personal Plugin Cutover

- [x] 1.1 In `glockyco/omp-agent-setup`, create and apply a change that disables OMP's built-in `marksman` server and defines `markdown-oxide` for Markdown files, then verify the plugin package contains both declarations and no Marksman fallback.
- [x] 1.2 Run the plugin repository checks and exercise Markdown diagnostics, definition, references, and rename with Markdown Oxide against a fixed representative project, then publish the verified plugin revision.

## 2. Fixed-Output Language Servers

- [x] 2.1 Add a Markdown Oxide package that selects the official `aarch64-apple-darwin` or `x86_64-unknown-linux-gnu` release artifact by system, installs it as `markdown-oxide`, and verify its version command on both supported systems.
- [x] 2.2 Add a Roslyn package that selects the official `roslyn-language-server.osx-arm64` or `roslyn-language-server.linux-x64` NuGet tool package by system, launches its DLL with the binary .NET 10 runtime as `Microsoft.CodeAnalysis.LanguageServer`, and verify initialization on both supported systems.
- [x] 2.3 Advance the personal-plugin pin and replace the Nixpkgs source-built Marksman and Roslyn selections in `packages/personal-omp.nix` with the fixed-output packages, then build the wrapper shape checks for both systems and confirm that Markdown Oxide and Roslyn resolve while Marksman does not.

## 3. Build-Plan and Operations Integration

- [x] 3.1 Extend `check-darwin-build-plans` to reject source-built Markdown Oxide and Roslyn derivations, add live positive controls for both Nixpkgs packages, and verify the controls fail if each application pattern is removed.
- [x] 3.2 Update the overlapping `align-documentation-with-fleet` delta with the combined release-gate wording and application exclusions, then run strict validation for both active changes.
- [x] 3.3 Document the official artifact sources, version-and-hash update boundary, personal-plugin release boundary, and required post-update language smoke in the dependency update procedure, then verify the procedure names both packages and both supported systems.

## 4. Verification

- [x] 4.1 Run the focused package, wrapper-shape, Markdown smoke, C# smoke, and Darwin build-plan checks on their native systems and confirm no build plan reaches a source-built Markdown Oxide or Roslyn derivation.
- [x] 4.2 Run `nix fmt -- --fail-on-change`, `nix flake check --print-build-logs`, `nix run .#check-darwin-build-plans`, and `nix build .#darwinConfigurations.macbook-pro.system` on the applicable native hosts.
- [ ] 4.3 Complete the activated C# and Markdown smoke through the installed OMP wrapper on both hosts, using existing project structure from actual repositories. Require diagnostics, cross-file definition, references, rename, and repeated post-edit diagnostics without failed-request retries or hidden restarts. Recover the reported Darwin smoke evidence or run a clearly labeled new acceptance session. Record host, repository, executable/plugin/server versions, requests, results, and file edits. Merge and activation have occurred; do not reactivate an unchanged generation. Keep the previous generation until acceptance passes.
- [ ] 4.4 Separately verify ordinary OMP use in an actual repository on each host: inspect files, make a controlled edit, and run the repository's normal verification command in its existing development environment. Record the command and result, preserve unrelated work, and remove only the verification edit. Report this result separately from LSP acceptance; do not require remote building or a project-environment migration.

## Acceptance evidence: 2026-09-05

Revision `ef77458c062a9969bd9a0366cac35f005d979f21` passed the native Linux flake check and all four native Darwin release commands. The Darwin guard inspected 34 outputs without a forbidden source build. Package version, Roslyn initialization, and wrapper-shape checks passed for both supported systems.

Fresh wrapped OMP sessions used OMP `18.1.10`, Markdown Oxide `0.25.12`, Roslyn `5.8.0-1.26252.1`, and a restored `net10.0` project with SDK `10.0.302`. Markdown diagnostics, definition, references, and note rename passed on both hosts. Each C# operation also returned its expected result, but initialization and post-rename failures prevent clean acceptance.

A sequential Linux reproduction used a transparent protocol relay around the unchanged official Roslyn payload. Roslyn advertised `textDocumentSync.change = 2` for incremental updates. After rename, OMP sent `contentChanges: [{ "text": "..." }]` without a range. Roslyn threw `NullReferenceException` in `ProtocolConversions.RangeToLinePositionSpan` through `DidChangeHandler` and terminated with `SIGABRT`. The relay observed subprocess status `-6`; OMP's shared transport reported exit code `0` instead. A later request started a new server, which explains the successful retries.

The trace also captured an initial diagnostic cancellation before project loading completed. OMP cancelled the pull after approximately 3.6 seconds; project loading took approximately 20.9 seconds.

The initial conclusion that a new OMP client change was required was too narrow. Roslyn already fixed whole-document updates in PR #84714. The user approved selecting official package `5.12.0-1.26426.8`, whose source contains that fix, without changing OMP. The new pin passed the pre-activation checks below, including post-edit diagnostics and cold-start behavior. This was not activated acceptance. Review, merge, and host activation later occurred, but 4.3 remains open because the activated Linux C# workflow failed. Do not add a retry wrapper, suppress errors, or patch the platform-owned executable.

### Compatible artifact acceptance

Revision `e7a7b310e26f3e7b9e3d3261f1d76c5d68d5effa` selects Roslyn `5.12.0-1.26426.8` without changing OMP, the .NET 10 runtime, or the package layout. The existing native check now initializes Roslyn, opens a C# document, sends a whole-document replacement, and requires the updated symbol from the same process. The old payload fails after the replacement. The selected payload passes on both supported systems. This check needs no SDK.

Fresh wrapped sessions passed Markdown and C# diagnostics, definition, references, and rename on both Linux and Darwin. Each session also returned the original C# compiler error on two sequential post-rename diagnostic requests, then resolved the renamed symbol. No request failed or required a retry, and no restart was reported. No startup or cache warning appeared in the tool output. Direct file checks confirmed the expected LSP edits and preserved both intentional errors. The disposable fixtures were removed.

The all-system flake check passed on Linux. All four release commands passed natively on Darwin at that revision. The build-plan guard inspected 34 outputs without a forbidden source build, and the full Darwin system built successfully. These are pre-activation results, not evidence that the later activated smoke passed. Gate 4.3 remains open for the failure recorded below.

### Activated outcome and bounded next check

PR #20 was rebase-merged as `75b2c7a568ea1e3d727774b76aef113c7712f78c`. Both hosts subsequently activated the corrected configuration at `dd445b76ad2444dbea81b00af696554ecf136ce1`. Both installed-wrapper verifiers passed with OMP `18.1.10`.

The activated Linux session passed Markdown operations and the managed-browser smoke. Its C# requests lacked the expected CS0029 diagnostic and cross-file definition, and rename was incomplete. No later diagnostic control changes that failed result. The activated Darwin session reported successful Markdown and C# operations, but subsequent independent retrieval of its preserved evidence failed. Recover that evidence or record a new acceptance session before closing the gate.

The pinned Roslyn source captures a pooled project list in a background task before its enclosing scope disposes the list. A lifetime experiment against the installed DLL demonstrated that a deferred read after disposal loses the discovered project. A separate solution-loading control loaded the same project and returned CS0029. These experiments isolate a discovery defect; they do not prove the complete OMP editing workflow or select a production workaround.

The next check uses the actual repository's existing project/solution structure through the installed wrapper. Do not add a solution merely to manufacture acceptance. Keep Linux C# unresolved if this path fails. An upstream contribution is not a prerequisite, and no replacement dependency version has been accepted.
