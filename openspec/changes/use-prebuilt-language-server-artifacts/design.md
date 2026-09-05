## Context

This section records the pre-cutover context; see **Current acceptance scope** for scheduled work. See `proposal.md` for motivation. The workstation supports `aarch64-darwin` and `x86_64-linux`. `packages/personal-omp.nix` currently overrides the .NET SDK and runtime with binary Nixpkgs variants, but Nix still compiles the Marksman and Roslyn applications. The Darwin build-plan guard only rejects the expensive compiler toolchains, so both application builds pass the gate.

Marksman's current official Linux executable is unusable, and pinning the last working binary would downgrade Markdown behavior. Markdown Oxide publishes current native release executables for both supported systems. Roslyn publishes signed, platform-specific NuGet tool packages that contain `Microsoft.CodeAnalysis.LanguageServer.dll` and its application payload. The Roslyn package remains framework-dependent and needs a .NET 10 runtime.

## Goals / Non-Goals

**Goals:**

- Keep the OMP wrapper contract while replacing the Markdown server identity without an alias or fallback.
- Make the two application payloads fixed-output downloads on both supported systems.
- Make a future return to either source-built application fail the Darwin build-plan gate.
- Keep dependency updates explicit and reviewable through versions and hashes in Nix source.

**Non-Goals:**

- Add a repository-specific binary cache or GitHub Actions cache.
- Change the OMP executable or unrelated personal-plugin behavior.
- Package unsupported architectures.
- Replace the platform-owned OMP executable.

## Current acceptance scope: 2026-09-05

The migration below is deployed, not a new execution queue. Retain the current package selection and installed configuration while completing tasks 4.3 and 4.4. Follow [near-term priorities](../../../docs/architecture/personal-omp-environment.md#near-term-priorities).

Ordinary wrapped OMP file editing and project-command execution have their own recorded result. They do not depend on remote building or on every LSP integration passing. Linux C# remains failed until its actual editing workflow passes; package initialization and direct-server diagnostic controls cannot close that gate.

Use the actual C# repository's existing project structure and development environment. A real project-owned solution is a supported entry point, not a generated workstation artifact. Do not introduce one solely to make a fixture pass. No upstream patches, forks, new protocol adapters, or package replacements are scheduled. If the supported path fails, record the failure and select a bounded correction from evidence rather than expanding this change automatically.

The older candidate's whole-document update crash and the current package's project-discovery defect are different failures. Keep both historical records, and do not treat the former fix as proof of the latter's acceptance. Preserve the full C# and Markdown operation matrix on both hosts and the previous generations. No new activation is needed to exercise the unchanged installed wrapper.

## Decisions

### Replace Marksman with Markdown Oxide

Marksman is present only because OMP selects it as the built-in Markdown language server. Its current `2026-02-08` Linux release executable crashes before command parsing because the trimmed single-file payload cannot construct its root command. The last working official artifact is `2025-12-13`, which predates the current math, table-of-contents, and Unicode fixes. Do not downgrade it or retain its source build.

Use Markdown Oxide `0.25.12` as the primary Markdown server. It provides the required diagnostics, definition, references, and rename behavior and publishes current executables for `aarch64-apple-darwin` and `x86_64-unknown-linux-gnu`. Add a repository-owned fixed-output package that selects the matching official GitHub release asset for the host system.

OMP has no built-in Markdown Oxide definition. In `glockyco/omp-agent-setup`, add a complete `markdown-oxide` server definition for `.md` and `.markdown`, disable the built-in `marksman` server, and verify the Markdown smoke before publishing the plugin revision. Advance the `personal-omp-plugin` lock here, then remove Marksman from the wrapper closure. Do not install a `marksman` executable that forwards to Markdown Oxide; the command and server identity change cleanly.

### Package Roslyn from its official tool payload

Roslyn uses the official `roslyn-language-server.osx-arm64` and `roslyn-language-server.linux-x64` NuGet tool packages. The package extracts the payload for its runtime identifier and installs a `Microsoft.CodeAnalysis.LanguageServer` wrapper that runs the downloaded DLL with Nixpkgs' binary .NET 10 runtime. This avoids patching the platform apphost and retains the runtime needed for framework-dependent deployment.

Alternatives rejected:

- Nixpkgs `markdown-oxide` and `roslyn-ls`: both compile the applications from source.
- Marksman `2025-12-13`: its binaries work, but the downgrade discards newer Markdown behavior.
- A `marksman` compatibility wrapper: it hides a different server behind the obsolete identity and preserves legacy configuration.
- The C# VS Code extension: it does not contain the normal Roslyn payload and would introduce unrelated proprietary editor and debugger files.
- GitHub Actions caching: it adds cache upload, restore, eviction, and trust complexity while leaving cache misses expensive. Fixed-output upstream artifacts remove the expensive build instead.
- A private Cachix cache: unnecessary infrastructure for artifacts their publishers already distribute.

### Use a compatible published Roslyn tool version

Pin Roslyn `5.12.0-1.26426.8` for both supported runtime identifiers. Both official NuGet packages identify source revision `3aeb96c9ecc56a5ee483558f9e648e33e7bfe756` and require the existing .NET 10 runtime. This is a published prerelease, as was the initial `5.8.0-1.26252.1` candidate.

The initial candidate was chosen for proximity to the source-built version. Wrapped acceptance exposed a crash when OMP sent a whole-document update after rename. Roslyn already fixed that case in [PR #84714](https://github.com/dotnet/roslyn/pull/84714), and the selected package source contains that fix. Select for verified client compatibility rather than version proximity. Do not modify OMP, insert a protocol adapter, or add retries.

Accept the version only after fresh wrapped sessions exercise initialization, diagnostics, definition, references, rename, and repeated diagnostics after edits on both hosts. Record cold-start cancellation separately; the post-edit fix does not establish that startup behavior is correct.

### Detect application source builds explicitly

Extend the Darwin build-plan guard's forbidden derivation pattern to match the Nixpkgs source-built `markdown-oxide` and `roslyn-ls` derivations. Name the repository packages as binary packages so the guard distinguishes fixed-output extraction from application compilation.

Use direct source-derivation controls for .NET VMR, its stage0 VMR, unwrapped Swift, Markdown Oxide, and Roslyn. Each control must match its own derivation name through the shared detector. Dependencies from another forbidden class must not hide a missing detector branch. A renamed upstream derivation must fail its control.

The app receives `self.outPath` and inspects that immutable snapshot regardless of its working directory. Resolve the selected Nixpkgs input through the lock graph's root input, not a fixed node name. Evaluate control derivations at runtime so the app does not retain their compiler closures. Continue enumerating all Darwin checks, packages, and development shells from that snapshot. Propagate store-query and inspection errors; only a successful inspection with no match is a clean result.

Run this guard immediately after Nix setup in Darwin CI, before `nix flake check` builds the repository outputs. A guard that runs after compilation cannot prevent the expensive build it detects.

### Preserve one language-server selection point

`packages/personal-omp.nix` remains the only list that selects the wrapper's language-server packages. It receives the two binary packages through normal package arguments or `callPackage`; no overlay or second package scope is needed. The independently pinned plugin remains the only source of personal LSP overrides.

### Reconcile the overlapping active delta

`align-documentation-with-fleet` also modifies `Source-free Darwin build plans` to name the external release gate. Update that delta to contain both its release-gate clarification and this change's application-level exclusions. Otherwise, archiving the documentation change later could restore the weaker contract.

## Risks / Trade-offs

- [Roslyn's NuGet layout changes] → Assert the expected DLL during the package build and fail before producing an executable wrapper.
- [An upstream artifact changes in place] → Fixed cryptographic hashes make the build fail; dependency updates must change the version and hash together.
- [The Roslyn update changes LSP behavior] → Run the existing C# language smoke on Linux and Darwin before merge.
- [The Markdown Oxide macOS asset stops supporting Apple Silicon] → Execute its version command on `aarch64-darwin`; do not add Rosetta as a fallback.
- [The plugin selects Markdown Oxide before the wrapper provides it] → Publish the plugin first, then advance its pin and replace the package set in one workstation commit.
- [Binary packages have larger downloads than source archives] → Accept the bounded download because it replaces minutes of compilation and remains cacheable by Nix.

## Migration Plan

1. Add the Markdown Oxide override and Marksman disablement to `omp-agent-setup`, run its Markdown smoke, and publish the plugin revision.
1. Add and expose both fixed-output packages on supported systems.
1. Advance the plugin pin and switch the OMP wrapper's language-server list from Marksman to Markdown Oxide and binary Roslyn in one cutover.
1. Extend the build-plan guard and its controls.
1. Run package-level command checks, language smokes, the Darwin build-plan gate, and repository release gates.
1. Activate only after review and merge. Roll back with the previous Nix generation if a live language-server smoke fails.
