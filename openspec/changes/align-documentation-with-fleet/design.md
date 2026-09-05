## Superseded — 2026-09-05

[simplify-repository-documentation](../simplify-repository-documentation/proposal.md) replaces this cleanup approach. Do not execute this change, absorb `consolidate-planning-home`, or merge these unimplemented specification deltas.

The replacement does not create planning-policy checks, external issues, evidence files, or a replacement architecture manual. Historical unchecked tasks remain unimplemented in `tasks.md`. Their former deletion, renaming, and gate-ownership instructions are not current guidance.

Legacy plans remain distinct files in [their existing index](../../../docs/plans/INDEX.md). Existing fleet changes retain their own scheduling and acceptance contracts.

## Retained intent

These unscheduled experiments and external project migrations came from the removed architecture document. This finite record does not authorize work or create a backlog. Each owner must review current conditions before scheduling a separate change. Historical audit measurements are not current evidence.

### Frontend experiment

Owner: `omp-agent-setup`. Compare native OMP designer with Anthropic `frontend-design`, Impeccable, and StyleSeed, with persistent memory disabled.

Evaluate skills only: no candidate agents, hooks, services, private learning, live loops, or generated scaffolding. Use one new visual surface and one refinement in an existing Svelte application. Isolate each candidate in a branch or copy. Hold repository revision, OMP, model, provider, prompt, assets, and viewports constant.

Measure tool calls, changed files, checks, interaction defects, latency, and context cost. Score brief fidelity, hierarchy, distinctiveness, accessibility, responsive behavior, repository fit, maintainability, and real browser defects. Blind screenshot review is preferred where practical.

Adoption requires a clear improvement over the combined control score, with no unmanaged scaffolding, failed checks, inaccessible interaction, or framework rewrite. Remove losing candidates and artifacts. If none wins clearly, install none. Adoption requires a separate reviewed change.

### Persistent-memory experiment

Owner: `omp-agent-setup` for protocol and harness. If adopted, `nix-config` owns the host service and the plugin owns OMP integration.

Compare memory disabled, a fresh disposable Mnemopi bank, and a pinned OpenViking release with a disposable store. Do not use an optional frontend skill. The old Air memory data lacks reliable provenance and correction history and is not a valid input. Its database and SQLite-sidecar removal remains unscheduled, not completed here.

Use committed synthetic fixtures for preferences, project facts, similar facts across projects, corrections, supersession, forbidden recall, unknown answers, and deletion. Exclude real history, private documents, repositories, secrets, and old databases.

Measure correct recall, abstention, cross-project isolation, correction precedence, provenance, complete deletion, stale/irrelevant recall, injected tokens, latency, and observability. Define measurable improvement and maximum false recall before execution.

Hard gates remain:

- zero cross-project leaks and zero recall after verified deletion;
- provenance for every injected fact and correction precedence over stale facts;
- no state outside the experiment directory and no process after teardown;
- improvement over memory disabled and compliance with the predefined false-recall ceiling.

Use a temporary `HOME`, explicit OMP configuration, dedicated ports, disposable stores, and Nix-pinned sources. Exclude Docker `latest`, mutable `pip install`, interactive installers, and optional local-model installation. Use the configured cloud provider and review OpenViking's AGPLv3 boundary before adoption.

The outcome is adopt Mnemopi, adopt OpenViking, retain memory disabled, or invalidate and rerun. Adoption requires a separate reviewed change.

### External project migrations

Owners: the HotRepl, Ardenfall, Ancient Kingdoms, and Erenshor repositories. Each migration requires a separate reviewed OpenSpec change and repository-local commits. No project changes or issues were created here.

Dependency order remains: workstation base first, then HotRepl and Erenshor independently, then Ardenfall and Ancient Kingdoms independently after HotRepl. Erenshor does not depend on HotRepl consumers. Previously delivered work counts only after the owner verifies it against the migration contract.

#### Common migration boundaries

- The repository, not the CrossOver bottle, is the migration unit. Its flake pins host tools for Apple Silicon macOS and Linux CI, plus Intel macOS where supported.
- Ecosystem lockfiles own library resolution. Shell entry must not restore dependencies or mutate Bun, pnpm, uv, NuGet locks, or tool manifests.
- Public immutable inputs outside ecosystem locks, including loader and manually restored NuGet archives, require hash-pinned Nix derivations. Runtime commands consume store artifacts rather than download them.
- Frozen checkout restoration remains cold-reachable through `nix run .#bootstrap` before dependencies exist, without global installs.
- A canonical CLI is `apps.default`. Build, deploy, launch, status, and other verbs remain subcommands, not duplicate Nix wrappers. Dedicated apps serve only necessary cold-start operations.
- Read-only `nix run . -- doctor` must report exact selected tool store paths, game discovery, Steam application/build IDs, assembly paths, loader state/version, and running-game state.
- A fast environment wrapper must verify an identity derived from the evaluated shell or current `flake.nix` and `flake.lock`. A boolean sentinel or one executable on `PATH` is insufficient.
- Loader installation is explicit, cold-reachable, and idempotent. It verifies an ownership manifest before adoption or replacement, preserves configuration/logs/saves/unowned files, and refuses unknown proxies, layouts, and partial installs.
- Deployment copies atomically, refuses replacement of an open game DLL, and records game build, loader, source revision, artifact hashes, and deployed paths in ignored repository-local state.
- Bottle names, game paths, credentials, outputs, and ports remain ignored machine-local state. Default discovery can use `CROSSOVER_BOTTLE=Steam` and the Steam manifest but must reject ambiguity.
- Proprietary game assemblies remain verified external inputs, never committed, copied into the Nix store, or described as reproducible packages.
- CrossOver, Steam authentication, game installation/updates, loader installation, mod deployment, launch, and bottle deletion remain mutable runtime operations. Workstation activation cannot perform them. It can install CrossOver and create an empty bottle.
- CI proves game-independent behavior in the flake environment. Local acceptance proves discovery, loader compatibility, deployment, launch, and one real runtime operation from a clean checkout.

After acceptance, each project owns its commands and invariants in its specs, README, and agent guidance. Remove replaced host paths, ambient-tool fallbacks, retired-tool calls, and sibling-checkout defaults. Preserve ignored local state and durable ownership of non-gating findings. Archive only the verified project change, never this unimplemented cleanup delta.

#### HotRepl

Pin Bun 1.3.14, .NET SDK 10, and the tools used by hooks and CI. Keep CSharpier 1.3.0 in the tool manifest and commitlint in the frozen Bun workspace unless a command requires otherwise.

Export a shell, formatter, game-independent checks, and packages for the protocol, SDK, CLI, MCP server, and test helpers. Replace ambient Homebrew, `~/.bun`, and `/usr/local` tool discovery with the common environment wrapper, including GUI hooks. Keep `bun install --frozen-lockfile` and `dotnet tool restore` as checkout bootstrap operations.

Publish a downstream loader-host build contract from a pinned HotRepl flake revision. Consumers supply verified game/Unity references at invocation time and write outputs to a writable project cache. MelonLoader consumers also supply its path and generated IL2CPP references. No sibling checkout or `bin`/`obj` write under immutable sources is permitted.

Acceptance requires exact runtimes, frozen restoration, format/TypeScript/site/C#/package/hook-parity checks on Linux and Apple Silicon macOS, and packages without proprietary DLLs. One loader host must build, deploy through its game repository, and answer a real HotRepl command.

#### Ardenfall

Pin Bun compatible with `>=1.3.13`, .NET SDK 10, dotnet tools, lefthook, and current workflow tools. Route GUI hooks through the common wrapper. Remove retired `omp-plans` coupling after replacement OpenSpec checks work.

Pin HotRepl and replace `HOTREPL_REPO`, `HOTREPL_CORE_OUT`, and `HOTREPL_BEPINEX_OUT` with the downstream build contract and writable local artifacts. Preserve the existing controller's safe deployment rather than add a parallel Nix deployment script.

Discover Steam application 1837770 and verify `Ardenfall_Data/Managed`. Keep only genuine local overrides in `.env`. Provide canonical doctor, build, deploy, launch, and export operations plus a reviewed hash-pinned BepInEx 5 installer. Do not infer the loader release from another game. Pin the decompiler through a tool manifest or Nix.

HotRepl remains on `127.0.0.1` by default. Remote access requires explicit opt-in and the remote-code-execution warning.

Acceptance requires frozen restoration and the existing lint/type/controller/pipeline/site/fixture/mod checks. Doctor reports the actual installed build. Installer re-entry changes no owned files. The pinned host and mod build without a sibling checkout, deploy the expected plugins/configuration, launch through CrossOver, and produce a validated export snapshot and pipeline artifact.

#### Ancient Kingdoms

Keep the existing flake authoritative. Pin pnpm 10.34.5 exactly, Python 3.14, .NET SDK 10, and `ilspycmd` 10.1.1.8388. Decompiler and game-version updates remain separate reviewed changes. Add workflow tools, including SteamCMD where licensing/platform support permit it, and the common GUI-hook/bootstrap wrapper.

Export real packages/apps/checks for the Python pipeline, build tool, game-independent mod compilation, and website. Pin HotRepl and use its MelonLoader contract. `HOTREPL_REPO_PATH` can remain an explicit development override, never the clean-checkout default.

Keep game/export paths in `Local.props`. Doctor and noninteractive setup derive and verify normal CrossOver values. A hash-pinned MelonLoader installer can adopt the historical 0.7.3 Open-Beta layout only after manifest verification. Preserve `UserData`, `Mods`, generated IL2CPP assemblies, configuration, and logs.

Server-reference updates use pinned tools while retaining `SNAPSHOT.toml`, assembly hashes, versioned backups, and citation-drift checks.

Acceptance requires frozen pnpm/uv/dotnet restoration and build-tool/pipeline/mod/website checks. Doctor verifies application 2241380, current build, Unity version, loader layout, and generated references. Installer re-entry is a no-op and deployment preserves unowned state. The pinned HotRepl host and mods must build/deploy, launch must reach loader/HotRepl readiness, and a compendium export must produce verified artifacts.

#### Erenshor

Keep the existing four-system flake, uv2nix, cold bootstrap, lockfile-safe shell entry, and Nix-based CI. Preserve Python 3.14, .NET SDKs 9/10, Node 22, pnpm 10, AssetRipper, SQLite, and gitleaks where current workflow contracts require them.

Split the packaged runtime from development/test dependencies. Export the real CLI as `packages.default` and `apps.default`. Use one canonical package version and decide explicitly whether Python 3.13 is a separately tested minimum. The wrapper uses a verified environment identity with direnv first and `nix develop` fallback, including bare GUI hooks.

Pure flake checks cover the CLI, `--help`, Python unit tests, and Python-only contract tests. Maps and native .NET leaves remain CI commands in `nix develop`, not sandboxed-derivation requirements. Offline `node_modules` or NuGet vendoring is not required.

Add read-only doctor and hash-pinned BepInEx/Lunaris installers through the CLI. Adoption of historical BepInEx 5.4.23.5 requires a matching owned-file manifest. Preserve loader status, activation, deployment, CrossOver launch, `mod setup` compile references, and `mod dev-setup` optional plugins. Keep Unity Hub/licensing, Steam authentication, and game payloads external. Materialize Unity Editor NuGet payloads with hash-pinned derivations, not `extract packages` downloads.

NuGet restoration must preserve both loader graphs:

- Replace floating references with exact versions in root `Directory.Packages.props` using Central Package Management. BepInEx.Core must match the intended runtime surface, and Fleck affects published ILRepack bytes.
- Commit ordinary `packages.lock.json` files. For the five loader-conditional production mods, set `NuGetLockFilePath` once in `src/mods/Directory.Build.props` to `packages.$(ModLoader).lock.json`.
- Commit both BepInEx and Lunaris locks before strict restoration. A framework-only lock cannot represent property-selected loader graphs.
- Add explicit `--locked-mode` project restoration for every native project and both variants, separately from manifest-pinned `dotnet tool restore`.
- Enable local lock generation, condition `RestoreLockedMode` on `ContinuousIntegrationBuild`, and set that property explicitly in CI. Tests consume the completed restore.
- Document intentional lock refresh. Renovate must refresh every affected ordinary/per-loader lock in the same update. Stale locks or only one updated loader graph must fail.
- CI maps/native leaves require frozen pnpm installation and the explicit locked project restore first.

Acceptance requires the runtime-only packaged CLI with canonical version and measured closure split, scoped pure checks, and the complete existing local/CI matrix. A representative dependency update must refresh all affected locks, while stale and single-variant updates fail. Bare GUI hooks must select the pinned environment. Doctor reports application 2382520, current build, available/active loaders, and launch plan. Both installers are idempotent and refuse unknown proxy DLLs. A maintained mod must build/deploy/activate/launch under BepInEx, and a dual-loader mod must also build/deploy under Lunaris. One complete CLI data operation must succeed.

Non-gating intent remains unscheduled: make MapTileCapture loopback-only by default with explicit remote configuration and a security warning, audit duplicate/stale repository skills, and remove retired `omp-plans` hook/agent guidance first in the migration. Historical project plan files can remain after the owner converts or archives active plans. These findings do not block acceptance of the scoped environment migration.
