## Context

See `proposal.md` for motivation. The workstation supports `aarch64-darwin` and `x86_64-linux`. `packages/personal-omp.nix` currently overrides the .NET SDK and runtime with binary Nixpkgs variants, but Nix still compiles the Marksman and Roslyn applications. The Darwin build-plan guard only rejects the expensive compiler toolchains, so both application builds pass the gate.

Marksman publishes native release executables for both supported systems. Roslyn publishes signed, platform-specific NuGet tool packages that contain `Microsoft.CodeAnalysis.LanguageServer.dll` and its application payload. The Roslyn package remains framework-dependent and needs a .NET 10 runtime.

## Goals / Non-Goals

**Goals:**

- Keep the current language-server command names and OMP wrapper contract.
- Make the two application payloads fixed-output downloads on both supported systems.
- Make a future return to either source-built application fail the Darwin build-plan gate.
- Keep dependency updates explicit and reviewable through versions and hashes in Nix source.

**Non-Goals:**

- Add a repository-specific binary cache or GitHub Actions cache.
- Change OMP, plugin, or language-server configuration behavior.
- Package unsupported architectures.
- Replace the platform-owned OMP executable.

## Decisions

### Package official release artifacts directly

Add small repository-owned packages for Marksman and Roslyn instead of overriding their Nixpkgs source builds. Each package selects one URL and hash from the host system.

Marksman uses the upstream GitHub release executable: `marksman-macos` on `aarch64-darwin` and `marksman-linux-x64` on `x86_64-linux`. The macOS artifact is the upstream asset intended for macOS; no local compilation or architecture translation is added.

Roslyn uses the official `roslyn-language-server.osx-arm64` and `roslyn-language-server.linux-x64` NuGet tool packages. The package extracts the payload for its runtime identifier and installs a `Microsoft.CodeAnalysis.LanguageServer` wrapper that runs the downloaded DLL with Nixpkgs' binary .NET 10 runtime. This avoids patching the platform apphost and retains the runtime needed for framework-dependent deployment.

Alternatives rejected:

- Nixpkgs `marksman` and `roslyn-ls`: both compile the applications from source.
- The C# VS Code extension: it does not contain the normal Roslyn payload and would introduce unrelated proprietary editor and debugger files.
- GitHub Actions caching: it adds cache upload, restore, eviction, and trust complexity while leaving cache misses expensive. Fixed-output upstream artifacts remove the expensive build instead.
- A private Cachix cache: unnecessary infrastructure for artifacts their publishers already distribute.

### Use the nearest common published Roslyn tool version

Pin Roslyn `5.8.0-1.26252.1`, the nearest official platform-package release after the current source-built `5.7.0-1.26220.12`. The exact current revision has no official NuGet tool package. Both supported runtime identifiers publish this version.

The version change is accepted only after the existing C# language smoke exercises initialization, diagnostics, definition, references, and rename through the wrapper.

### Detect application source builds explicitly

Extend the Darwin build-plan guard's forbidden derivation pattern to match the Nixpkgs source-built `marksman` and `roslyn-ls` derivations. Name the repository packages as binary packages so the guard distinguishes fixed-output extraction from application compilation.

Add positive controls for both Nixpkgs application derivations, beside the existing .NET and Swift controls. A renamed upstream derivation must fail the control instead of silently weakening the gate. Continue enumerating all Darwin checks, packages, and development shells from flake outputs.

### Preserve one language-server selection point

`packages/personal-omp.nix` remains the only list that selects the wrapper's language servers. It receives the two binary packages through normal package arguments or `callPackage`; no overlay or second package scope is needed.

### Reconcile the overlapping active delta

`align-documentation-with-fleet` also modifies `Source-free Darwin build plans` to name the external release gate. Update that delta to contain both its release-gate clarification and this change's application-level exclusions. Otherwise, archiving the documentation change later could restore the weaker contract.

## Risks / Trade-offs

- [Roslyn's NuGet layout changes] → Assert the expected DLL during the package build and fail before producing an executable wrapper.
- [An upstream artifact changes in place] → Fixed cryptographic hashes make the build fail; dependency updates must change the version and hash together.
- [The Roslyn update changes LSP behavior] → Run the existing C# language smoke on Linux and Darwin before merge.
- [The Marksman macOS asset stops supporting Apple Silicon] → Execute its version command on `aarch64-darwin`; do not add Rosetta as a fallback.
- [Binary packages have larger downloads than source archives] → Accept the bounded download because it replaces minutes of compilation and remains cacheable by Nix.

## Migration Plan

1. Add and expose both fixed-output packages on supported systems.
1. Switch the OMP wrapper's language-server list to the new packages in one cutover.
1. Extend the build-plan guard and its controls.
1. Run package-level command checks, language smokes, the Darwin build-plan gate, and repository release gates.
1. Activate only after review and merge. Roll back with the previous Nix generation if a live language-server smoke fails.
