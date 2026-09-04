# Personal OMP Environment Architecture

## Status and authority

Status: stable workstation base implemented; project migrations and controlled experiments remain planned.

Last reviewed: 2026-09-04.

This document is the canonical cross-repository record for the personal OMP environment. It owns the target architecture, ownership boundaries, accepted decisions, experiment protocols, migration order, and cross-session recovery procedure.

It does not own repository implementation tasks. An active OpenSpec change in the affected repository owns those tasks. After a change is archived, that repository's OpenSpec specifications and normal documentation own the delivered behavior.

The legacy OMP consolidation spec and 63-task plan under `docs/plans/` are historical evidence. They are superseded because they put the personal plugin inside `nix-darwin`, retained mutable deployment machinery, and predate the decisions in this document.

## Resume after a new session or compaction

1. Read this document, starting with **Current state** and **Workstreams**.
1. Open the active repository named in the current-state table.
1. Run `openspec list` and `openspec status --change <name>` if that repository has been initialized for OpenSpec.
1. Read the active change's `proposal.md`, delta specifications, `design.md`, and `tasks.md` before editing code.
1. Inspect the repository worktree. Preserve unrelated user changes.
1. Continue from the first incomplete task whose dependencies are complete.

Before ending a session that changed the implementation:

1. Update the active OpenSpec task checkboxes immediately.
1. Record a new architectural decision here only if ownership, scope, or a permanent invariant changed.
1. Put durable repository facts in that repository's specifications, `AGENTS.md`, or normal documentation. Do not put them in a session diary.
1. Record verification as exact commands or scenarios in the active change. Do not paste transient logs into this document.
1. Update the current-state table only when a workstream changes state.

Session transcripts, OMP memory, chat summaries, and issue comments are supporting evidence. None is a source of truth.

## Current state

| Workstream                           | State    | Durable execution record                                                                                                | Dependency                              |
| ------------------------------------ | -------- | ----------------------------------------------------------------------------------------------------------------------- | --------------------------------------- |
| Delete the old Air Mnemopi state     | complete | explicit maintenance operation; no migration artifact                                                                   | none                                    |
| Package the personal OMP plugin      | complete | archived `omp-agent-setup` OpenSpec change `package-personal-omp-plugin`                                                | none                                    |
| Consume the plugin from `nix-darwin` | complete | archived `nix-darwin` OpenSpec change `consume-personal-omp-plugin`                                                     | verified plugin output contract         |
| Decouple OMP executable updates      | active   | `nix-darwin` OpenSpec change `manage-omp-with-homebrew`                                                                 | platform-owned prebuilt executables     |
| Adopt the NixOS WSL host             | complete | `nix-darwin` OpenSpec change `adopt-nixos-wsl-host` and `docs/operations/wsl-omp-bootstrap.md`                          | accepted WSL release evidence           |
| Manage the Windows layer             | active   | `nix-darwin` OpenSpec change `manage-windows-layer` and `docs/operations/wsl-omp-bootstrap.md`                          | adopted NixOS WSL host                  |
| Migrate HotRepl                      | ready    | future HotRepl OpenSpec change `nix-development-environment`                                                            | workstation base                        |
| Migrate Ardenfall                    | blocked  | future Ardenfall OpenSpec change `nix-development-environment`                                                          | HotRepl and workstation base            |
| Migrate Ancient Kingdoms             | blocked  | future Ancient Kingdoms OpenSpec change `nix-development-environment`                                                   | HotRepl and workstation base            |
| Migrate Erenshor                     | ready    | existing flake, bootstrap, and Nix-based CI; future OpenSpec change `nix-development-environment`                       | workstation base                        |
| Evaluate frontend skills             | planned  | `omp-agent-setup` issue, then OpenSpec change when scheduled                                                            | stable base; memory disabled            |
| Evaluate persistent memory           | planned  | `omp-agent-setup` issue, then OpenSpec change when scheduled                                                            | stable base; no optional frontend skill |
| Remove the legacy OMP deployment     | complete | immutable plugin repository, removed global shims and managed payloads, and archived mutable-deployment planning record | verified workstation cutover            |

HotRepl is the next migration. Erenshor may proceed independently on the stable workstation base. Planned experiments remain issues until their dependencies are complete. OpenSpec active changes are not a parking lot.

## Goals

- One consistent personal OMP environment for one user on each supported host: Apple Silicon macOS and `x86_64` WSL 2.
- One independently packaged personal OMP plugin.
- Platform-managed prebuilt OMP executables with explicit updates outside Nix activation.
- Nix-managed wrappers, Herdr, OpenSpec, language-server executables, and plugin revisions.
- Mutable OMP authentication, preferences, sessions, history, and caches remain under OMP ownership.
- Project-specific toolchains, commands, facts, and domain skills remain in their repositories.
- CrossOver and Steam remain the mutable Windows runtime. Nix and project commands automate around that boundary.
- Every permanent capability has one owner and an observable acceptance gate.

## Non-goals

The target contains no:

- personal specialist agents or generated agent bundle;
- local-model installation, configuration, or evaluation;
- Nix installation inside a CrossOver bottle;
- OMP source patching, executable fallback, or `PATH`-based wrapper resolution;
- repository-owned mutable global package installers;
- YAML surgery against OMP-owned configuration;
- fleet-wide repository scanner;
- custom planning runtime, `omp-plans`, or `omp-skill`;
- desktop-control integration or automatically started browser relay;
- globally enabled security scan;
- compatibility shims after cutover.

These are exclusions, not deferred work.

## Decisions

| Area                            | Decision                                                                                                       |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| OMP                             | Use the official prebuilt platform executable; update it explicitly outside Nix activation                     |
| Supported hosts                 | Activate complete nix-darwin and NixOS/WSL hosts; use the wrapped WSL OMP environment from Windows Zed         |
| Linux binary cache              | Configure the signed Numtide cache in NixOS system scope for Herdr, OpenSpec, and other cached packages        |
| Personal behavior               | Load one Nix-pinned plugin from `omp-agent-setup`                                                              |
| Plugin location                 | Keep the source and flake in `omp-agent-setup`; do not copy it into `nix-darwin`                               |
| Mutable OMP state               | Leave it writable and under OMP ownership                                                                      |
| Global policy                   | Keep only personal deviations from OMP defaults                                                                |
| STE                             | Retain the complete ASD-STE100 relationship and auditable 53-rule map                                          |
| Literature acquisition          | Retain publisher OA, Sci-Hub, green OA, arXiv, and manual acquisition in that order                            |
| Commit messages                 | Retain a structured OMP commit tool and repository hook authority                                              |
| Language intelligence           | Install executables with Nix; use OMP defaults unless a representative smoke test proves an override necessary |
| Durable implementation planning | Use pinned OpenSpec in each repository that needs a multi-session change                                       |
| Frontend design                 | Run the planned controlled comparison before installing a permanent skill                                      |
| Persistent memory               | Delete the old database; run a planned clean comparison after the base is stable                               |
| Image generation                | Use OMP's native tool only after a real provider smoke test                                                    |
| Browser and desktop             | Run managed Chromium headlessly on WSL; use a dedicated Brave relay on demand; keep desktop control disabled   |
| Secret obfuscation              | Keep it mutable and disabled initially                                                                         |
| Security review                 | Invoke it explicitly for a scoped review; do not enable it globally                                            |
| CrossOver                       | Preserve the bottle as mutable runtime state; mutate loaders and mods only through explicit project commands   |

## Ownership

### `omp-agent-setup`

This repository owns reusable personal OMP behavior:

- one short always-applied personal policy rule;
- `simplified-technical-english`;
- one consolidated research and evidence skill;
- `commit-policy` and a structured commit extension;
- only those LSP overrides that pass representative repository tests;
- evaluation fixtures and harnesses for frontend skills and memory.

The target plugin is a capability bundle, not an installer. Its flake exports an immutable plugin directory with a normal OMP package manifest. It exports no agents and no model support.

Repository and output shape:

```text
flake.nix
flake.lock
plugin/
  package.json
  rules/
    personal-policy.md
  skills/
    simplified-technical-english/
      SKILL.md
      references/
        standard.md
        rules.md
        checklist.md
        use-cases.md
    research-evidence/
      SKILL.md
      scripts/
        fetch_pdf.py
    commit-policy/
      SKILL.md
  extensions/
    personal-commit.ts
  lsp.json
  tests/
```

The default flake package copies `plugin/` into one immutable directory. Tests remain in the package so the Darwin and Linux checks exercise the exact delivered bytes.

Do not create empty directories. `lsp.json` contains only proven overrides. A frontend skill is added only if its evaluation selects one.

### `nix-darwin`

This repository owns the workstation contract:

- pinned Herdr, OpenSpec, and personal-plugin revisions;
- the OMP wrapper, platform executable paths, and immutable launch policy;
- a curated language-server executable path;
- Herdr's supported integration reconciliation;
- the signed Numtide substituter contract;
- the `korolev` NixOS WSL host, its checks, and the operator runbook;
- CrossOver and Rosetta prerequisites;
- checks that the selected packages and wrapper compose correctly.

It does not copy personal-plugin source. It consumes the plugin's flake output. It must not parse, merge, replace, back up, or symlink mutable OMP databases and configuration.

### WSL work machine

Windows owns Windows Terminal, WSL enablement, employer policy, native application state, and the editor runtime. This repository owns the reviewed Windows declaration and uses Nix to render it; the operator applies that artifact with WinGet and DSC. The declaration installs pinned, user-scope Brave only for browser relay, while Zen remains the interactive browser. The NixOS host `korolev` owns the Linux system scope, user scope, OMP wrapper and plugin, Chromium shared-library ABI, Herdr, OpenSpec, and language tools. The official oh-my-pi installer owns the user-local OMP executable. OMP owns its downloaded Chromium, caches, profiles, relay extension, and other mutable runtime state. Repositories stay under the Linux home directory, not `/mnt/c`.

The root flake exposes `nixosConfigurations.korolev` for `x86_64-linux`. `nixos-rebuild switch --flake .#korolev` provides ordered activation, generation replacement, failure rollback, and a retained rollback target. The host declares no SSH server, no other inbound service, and no secret.

The Git identity is declarative. The host declares the employer address globally, and a conditional include declares the GitHub no-reply address for every clone under the personal tree. Activation writes no repository-local configuration.

For a user who has never started OMP, the reconciliation helper can create the missing `~/.omp/agent` directory. Herdr remains the only writer of its generated extension. Activation does not create authentication, configuration, sessions, or databases.

### OMP

Platform installers own the OMP executable: Homebrew on Darwin and the official binary installer in NixOS/WSL. OMP owns:

- provider authentication and OAuth state;
- `~/.omp/agent/config.yml`;
- model, theme, and interaction preferences;
- sessions, blobs, history, and usage databases;
- caches and browser runtime state.

Nix supplies the executable wrapper, plugin path, personal extension path, language-server executables, and the shared-library ABI for foreign Linux binaries. The wrapper invokes one explicit platform path and never searches `PATH` or falls back to a Nix OMP package. Nix does not package Chromium or overlay or rewrite OMP configuration. User preferences remain mutable.

### Project repositories

Each repository owns:

- its flake and ecosystem lockfiles;
- architecture and domain invariants;
- build, test, generation, deployment, and launch commands;
- project-specific MCP and LSP exceptions;
- game-path discovery and loader requirements;
- domain skills whose correctness depends on project code or data;
- its OpenSpec changes and accepted specifications.

A repository does not repeat the personal prose or commit policy unless it intentionally overrides it.

### CrossOver and Steam

CrossOver and Steam own the bottle, games, authentication, saves, registry, caches, loader configuration, and logs. These are mutable runtime state, not Nix store inputs.

Nix owns CrossOver installation and bottle prerequisites. A repository with a canonical CLI exposes runtime operations through its default app:

```text
nix run . -- doctor
nix run . -- install-loader
nix run . -- mod deploy
nix run . -- launch
```

A dedicated app remains appropriate for a cold-start operation such as `nix run .#bootstrap`. An installer consumes a hash-pinned store artifact, inspects mutable state before mutation, adopts an existing installation only when its version and owned-file manifest match, preserves configuration and logs, stops on unknown layouts, and never overwrites unknown DLLs.

## Personal policy

The global policy remains short:

- Apply Simplified Technical English principles to technical prose.
- Verify an interface in its actual host: browser for web, application/editor/game for non-web.
- Use the structured personal commit tool for commit and amend operations.
- Require every commit body to explain why the change exists.

OMP already supplies broad engineering rules. Do not repeat them globally.

## Simplified Technical English

ASD-STE100 Issue 9, dated January 2025, is the authority. STE is a controlled natural language made from 53 writing rules in nine sections, a controlled dictionary, and allowances for subject-specific technical nouns and technical verbs.

The skill must retain:

- the identity, date, owner, and official source of the standard;
- a faithful paraphrase and identifier for every one of the 53 rules;
- the relationship between the rules and controlled dictionary;
- procedural and descriptive modes, including their different sentence limits;
- technical-term handling for code, identifiers, commands, paths, product names, and quotations;
- strict and pragmatic modes;
- the non-affiliation and non-compliance disclaimer;
- the requirement for the official dictionary and human review when strict compliance matters.

Migration rules:

1. Preserve the current skill before editing it.
1. Obtain the official Issue 9 PDF through the ASD/STEMG request process.
1. Audit every rule number and paraphrase against that copy.
1. Record the official document checksum locally in the traceability reference. Do not commit the copyrighted PDF or reproduce the complete dictionary.
1. Make a test require exactly the expected 53 rule identifiers.
1. Make every checklist citation resolve to `references/rules.md`.
1. Describe default output as STE-based unless a qualified human has confirmed compliance.

The current checklist refers to a missing `rules.md`; the packaged skill must correct this instead of weakening traceability. The official STEMG AI guidance makes the standard primary and requires human oversight.

## Research and evidence

Consolidate literature search, paper retrieval, evidence reading, citation verification, and BibTeX formatting into one workflow:

```text
search -> screen -> acquire -> read -> verify metadata -> register
```

Retain these invariants:

- Do not fabricate metadata.
- Use authoritative metadata from Crossref, OpenAlex, DBLP, the publisher, or the paper.
- Do not characterize a paper without reading the relevant text.
- Validate a downloaded PDF by its `%PDF-` header before saving it.
- Update all citation callsites when changing a BibTeX key.

Retain this acquisition order:

1. publisher-hosted open-access published version;
1. Sci-Hub published version;
1. repository or green-open-access manuscript;
1. arXiv;
1. manual author or institutional copy.

Package the existing Sci-Hub viewer parsing and relative-URL resolution. Require an explicit `UNPAYWALL_EMAIL`. Automated tests use deterministic HTTP fixtures and never depend on live mirrors. A release smoke may exercise live configured mirrors. A mirror change is a reviewed source revision.

## Commit workflow

Keep semantic guidance and mechanical transport separate:

- `commit-policy` explains useful Conventional Commit subjects and causal bodies.
- `personal-commit` accepts structured `commit`, `amend`, and `preview` input.
- Repository hooks and CI remain authoritative for repository-specific types and scopes.

The extension must require a body, reject literal `\\n`, preserve paragraph boundaries, wrap ordinary prose without splitting URLs or code tokens, write one temporary message file, and invoke `git commit -F` or `git commit --amend -F`. It never stages, pushes, uses `--no-verify`, or depends on `omp-plans` or `bunx`.

Tests include a real disposable repository and prove that hooks still run.

## Language intelligence

Nix installs only the language-server executables used by active repositories. Project shells continue to own SDKs, libraries, compilers, formatters, linters, and test runners.

Use OMP's built-in definitions first. Retain the acceptance requirements from the old setup, not the old override file. The fixed smoke matrix covers definition, references, rename where supported, and diagnostics for representative Python, C#, TypeScript/Svelte, Nix, Markdown, LaTeX, and BibTeX repositories.

Do not declare an override or server supported until its representative scenario passes.

## Durable planning and documentation lifecycle

Use one durable home for each information class:

| Information                                                                          | Canonical home                                                 |
| ------------------------------------------------------------------------------------ | -------------------------------------------------------------- |
| Cross-repository target, ownership, decisions, experiment protocols, migration order | this document                                                  |
| Planned but blocked experiment                                                       | owning repository's GitHub issue, linking to the protocol here |
| Active multi-session implementation                                                  | repository-local OpenSpec change                               |
| Accepted observable behavior                                                         | repository-local `openspec/specs/` after archive               |
| Current commands and maintainer invariants                                           | repository README, `AGENTS.md`, and normal documentation       |
| Current-session execution                                                            | OMP todo state                                                 |
| Historical rationale                                                                 | archived OpenSpec change and superseded plan files             |

Use OpenSpec's released core profile. Do not create a workstation-specific global workflow profile. Invoke validation and any needed verification explicitly. OpenSpec-generated adapters remain under OpenSpec ownership.

The generated workflow adapters are machine-level, not repository content. They are identical everywhere and describe no repository, so the personal plugin ships the only tracked copy and every repository loads it. A repository keeps its own `openspec/` directory, because specifications and changes are repository content. Do not run `openspec init` in a consuming repository. Regenerate the adapters in `glockyco/omp-agent-setup`, then advance `personal-omp-plugin` here.

A repository may still define a command or skill whose name matches one the plugin provides. The repository definition wins there and nowhere else. Use that only for a deviation the repository actually needs.

Lifecycle:

1. Explore without artifacts only while the direction is uncertain.
1. Create a proposal when the work is accepted and actionable.
1. Review proposal, delta specifications, design, and tasks.
1. Apply one repository-local change.
1. Verify the observable acceptance criteria.
1. Archive only after verification passes.
1. Merge stable behavior into specifications and normal documentation.

Do not use active OpenSpec changes for blocked experiments. Do not duplicate their task lists in this document.

## Planned frontend-skill experiment

Owner: `omp-agent-setup`.

Control and candidates:

- native OMP designer;
- Anthropic `frontend-design`;
- Impeccable;
- StyleSeed.

Evaluate skills only. Do not install candidate agents, hooks, remote services, private learning, live loops, or generated project scaffolding.

Use one new visual surface and one refinement in an existing Svelte application. Hold the repository commit, OMP version, model, provider, prompt, assets, and viewport set constant. Run each candidate from an isolated branch or copy. Record tool calls, changed files, checks, interaction defects, latency, and context cost. Score brief fidelity, hierarchy, distinctiveness, accessibility, responsive behavior, repository fit, maintainability, and defects found during real browser interaction. Review screenshots without candidate labels where practical.

A winner must beat the combined control score without unmanaged scaffolding, failing checks, inaccessible interactions, or a framework rewrite. Remove all losing candidates and their artifacts. If none clearly beats native OMP, install none.

Run this experiment with persistent memory disabled.

## Planned persistent-memory experiment

Owner: `omp-agent-setup` for the protocol and harness. If a backend is adopted, `nix-darwin` owns its host service and the plugin owns its OMP integration.

The old Air Mnemopi data is not an input. Delete its databases and SQLite sidecars. Preserve only this rationale: 124 of 129 inspected working memories had unknown veracity; none had expiry, supersession, or validation; 292 of 515 extracted facts used a degenerate `fact / entity` form; duplicates and truncated contradictory fragments were present. This data is below the threshold for automatic context injection.

Compare three fresh isolated conditions:

1. memory disabled;
1. a new disposable Mnemopi bank;
1. a pinned OpenViking release with a disposable store.

Use committed synthetic fixtures and controlled sessions containing stable preferences, project-local facts, similarly named facts in two projects, superseded facts, corrections, facts that must not be recalled, questions with no stored answer, and deletion requests. Do not ingest real history, repositories, private documents, secrets, or the old database.

Measure correct recall, refusal when no fact exists, cross-project isolation, correction precedence, source provenance, deletion completeness, irrelevant and stale recall, injected tokens, latency, and operator observability.

Hard gates:

- zero cross-project leaks;
- zero recall after verified deletion;
- provenance for every injected fact;
- corrected facts always supersede stale facts;
- no state outside the experiment directory;
- no process after teardown;
- a predefined measurable improvement over memory disabled;
- a predefined maximum false-recall rate.

Run under a temporary `HOME`, explicit OMP configuration, dedicated ports, and disposable stores. Pin all sources through Nix. Do not use Docker `latest`, mutable `pip install`, interactive installers, or OpenViking's optional local-model installation. Use the configured cloud provider. Record OpenViking's AGPLv3 boundary before adoption.

The result is adopt Mnemopi, adopt OpenViking, retain memory disabled, or invalidate and rerun the experiment. Adoption requires a separate reviewed change. Run this experiment without an optional frontend skill.

## Workstreams

### `package-personal-omp-plugin`

Repository: `omp-agent-setup`.

Delivered: the flake, immutable plugin output, STE traceability, research workflow with Sci-Hub support, structured commit extension, minimal LSP overrides, and isolated plugin-load tests. The repository no longer contains the legacy bootstrap, mutable payload, installers, global shims, source patches, or compatibility commands.

### `consume-personal-omp-plugin`

Repository: `nix-darwin`.

Delivered: the pinned plugin output, wrapped upstream OMP, curated language-server path, Herdr reconciliation, local activation verifier, package-shape checks, representative LSP scenarios, and a real wrapped-session smoke. Activation leaves OMP-owned configuration and databases as regular writable files.

### `adopt-nixos-wsl-host`

Repository: `nix-darwin`.

Delivered: the NixOS host `korolev`, its WSL system scope, the portable user scope under Home Manager, host checks for the closure and the portable module set, and the deletion of the imperative bootstrap implementation. The [korolev provisioning runbook](../operations/wsl-omp-bootstrap.md) owns the Windows prerequisites, the image build, the import, the side-by-side cutover, both rollback paths, and the real-session proof.

Both supported Nix hosts now share one model: a system configuration that imports Home Manager as a module.

### `manage-windows-layer`

Repository: `nix-darwin`.

The repository renders a reviewable WinGet Configuration document and narrow Administrator scripts for the native Windows applications, settings, and application files used with `korolev`. Nix does not execute Windows resources. The operator applies the document as the interactive user; every resource uses that scope except the official Zen installer. The document prefers English (United Kingdom) for interfaces and ISO 8601 for short dates while it preserves the Austrian region, German input methods, and native Neo default. Windows Terminal still stores its immutable per-user AppX payload in the protected `WindowsApps` store, and the user-installed PowerToys bundle creates a hidden machine-wide MSI registration while keeping its payload and mutable files under `%LOCALAPPDATA%`. Neither packaging detail widens the DSC privilege boundary. The Administrator scripts own only Zen's Program Files policy path and the checksum-pinned native Neo keyboard driver under Windows machine paths. DSC convergence has no generation or transactional rollback.

### Project migrations

The dependency graph is:

1. complete the workstation base;
1. migrate HotRepl and Erenshor independently after the base;
1. migrate Ardenfall and Ancient Kingdoms independently after HotRepl.

Erenshor is not delayed behind the HotRepl consumers. It is listed last below only to keep each repository audit next to its acceptance contract, not to impose execution order.

Each repository gets a separate OpenSpec change. Existing delivered work counts after the change verifies it. A clean checkout must enter its Nix environment, restore frozen dependencies, pass `doctor`, build, deploy, launch, and complete one real runtime operation.

#### Common project migration contract

The migration unit is the repository, not the bottle. Every repository pins the host tools and dependencies needed by its own commands. CrossOver remains an external, mutable runtime.

Each migration must leave these boundaries true. Work delivered before the OpenSpec change counts after it is reverified and recorded:

1. `flake.nix` and `flake.lock` own host-supported SDKs, command-line tools, and the repository development shell. The flake must support Apple Silicon macOS and the Linux platform used by CI. Add Intel macOS when the project still supports it.
1. Ecosystem lockfiles continue to own library dependency resolution. Entering the shell must not create or update `bun.lock`, `pnpm-lock.yaml`, `uv.lock`, NuGet lock state, or tool manifests.
1. Immutable public build inputs that ecosystem lockfiles do not cover, including loader archives and manually restored NuGet payloads, are fixed-output Nix derivations such as `fetchurl` with hashes. Runtime commands consume their store paths; they do not download and hand-verify those artifacts.
1. `nix run .#bootstrap` restores frozen mutable checkout dependencies when the ecosystem requires them. It must remain reachable before those dependencies exist and must not install tools globally.
1. Read-only `doctor` behavior belongs to the canonical CLI when one exists and is cold-reachable as `nix run . -- doctor`. It reports the exact selected tool store paths, game discovery result, Steam application and build IDs, expected assembly paths, installed loader state and version, and whether the game is running.
1. Loader installation is explicit, idempotent, and cold-reachable through the canonical CLI or a dedicated `install-loader` app. It consumes a checksum-pinned store artifact and verifies an ownership manifest when adopting or updating mutable bottle files. It preserves loader configuration, logs, saves, and unrelated files. It refuses an unknown proxy DLL, loader layout, or partial installation.
1. A repository with a canonical CLI exports it as `apps.default`. Build, deploy, launch, status, and similar verbs remain CLI subcommands rather than duplicate Nix wrapper apps. Dedicated apps are limited to operations that must work before the CLI or checkout dependencies exist, such as bootstrap.
1. A fast environment wrapper may bypass `nix develop` only when an identity derived from the evaluated development shell or current `flake.nix` and `flake.lock` matches. A boolean presence sentinel is insufficient. `doctor` compares selected binaries with their exact expected Nix store paths, not merely the `/nix/store` prefix.
1. Deployment records the game build, loader version, source revision, artifact hashes, and deployed paths in repository-local ignored state. It copies atomically and refuses replacement while the game holds a target DLL open.
1. Game paths, bottle names, credentials, output locations, and ports remain ignored machine-local configuration. A default CrossOver discovery path may use `CROSSOVER_BOTTLE=Steam`, the Steam application manifest, and its `installdir`; it must reject ambiguous matches.
1. Proprietary game assemblies remain external build inputs. They are never copied into the Nix store, committed, or represented as a reproducible Nix package. The shell and build command are reproducible; the game payload is a verified prerequisite.
1. CI proves the pure, game-independent contract through the flake environment. A local runtime smoke proves discovery, loader compatibility, deployment, launch, and one real operation against the installed game.

Do not hide the mutable boundary in Home Manager activation or `darwin-rebuild`. Workstation activation may install CrossOver and create an empty bottle, but it must not authenticate Steam, install or update games, install loaders, deploy mods, launch games, or delete bottle files.

#### HotRepl migration

Audit snapshot:

- The repository has no flake. Contributor setup currently uses Homebrew for `lefthook`, `dprint`, `actionlint`, `commitlint`, and `typos`.
- `package.json` requires Bun 1.3.14. The currently pinned project-family nixpkgs exposes Bun 1.3.13, so the HotRepl flake must deliberately pin or package 1.3.14 rather than silently accepting the older binary.
- C# tests require .NET SDK 10. CSharpier 1.3.0 is already pinned in `.config/dotnet-tools.json`.
- `scripts/run-bun.sh` and `lefthook.yml` search `~/.bun`, Homebrew, and `/usr/local/share/dotnet`. Those fallbacks bypass the selected project environment.
- BepInEx builds require game-local Unity assemblies. MelonLoader builds additionally require `MelonLoaderPath` and generated IL2CPP assemblies. These inputs are intentionally outside Nix.

The `nix-development-environment` change must:

1. Add a flake with the exact Bun 1.3.14 runtime, .NET SDK 10, dprint, lefthook, actionlint, typos, and other tools that current hooks and CI actually invoke. Keep commitlint in the frozen Bun workspace unless a repository command proves a standalone binary is required.
1. Export a development shell, formatter, game-independent checks, and game-independent package outputs for the protocol, SDK, CLI, MCP server, and test helpers.
1. Replace `scripts/run-bun.sh` and hook-local Homebrew or `/usr/local` selection with one repository environment wrapper. GUI-launched hooks must enter the pinned shell through an explicit sentinel, not infer the whole environment from one executable on `PATH`.
1. Keep `dotnet tool restore` and `bun install --frozen-lockfile` as checkout bootstrap operations. Do not package `node_modules`, NuGet caches, or restored dotnet tools as mutable global state.
1. Publish a downstream build contract for loader hosts. A consumer pins the HotRepl flake revision, supplies verified game assemblies at invocation time, and writes build artifacts to a writable project cache. A consumer must not require a sibling HotRepl checkout or write `bin` or `obj` under an immutable flake source path.
1. Remove hard-coded checkout paths and the old tool-discovery fallbacks after the shell, hooks, and CI use the new contract.

HotRepl acceptance:

- a clean checkout enters the shell and reports Bun 1.3.14 and .NET SDK 10;
- frozen Bun and dotnet-tool restoration succeeds;
- current format, TypeScript, site, C#, package, and hook-parity checks pass on Linux CI and Apple Silicon macOS;
- game-independent flake packages build without proprietary DLLs;
- one BepInEx or MelonLoader host is built from the pinned source with external game references, deployed through an owning game repository, and answers one real HotRepl command.

#### Ardenfall migration

Audit snapshot:

- The repository has no flake and currently relies on Bun, .NET, and hook tools found on the ambient machine.
- `lefthook.yml` prepends `~/.bun/bin`, `/opt/homebrew/bin`, and `/usr/local/bin`.
- `.env.example`, `package.json`, and `mod/scripts/copy-libs.sh` require a mutable sibling HotRepl checkout and its `bin/Debug` outputs.
- The current Steam install is application 1837770, build 22145060. No `BepInEx` directory is currently present in that install.
- The controller already owns safe artifact deployment and loopback HotRepl configuration. Preserve that implementation instead of creating a parallel Nix deployment script.

The `nix-development-environment` change must:

1. Add a flake and lock for Bun, .NET SDK 10, the repository dotnet tools, lefthook, and the tools used by current CI and package scripts. Pin one Bun version that satisfies the existing `>=1.3.13` contract.
1. Add the common environment wrapper and route hooks through it. Remove hard-coded Homebrew, `~/.bun`, `/usr/local`, and obsolete `omp-plans` hook coupling only after the replacement OpenSpec checks pass.
1. Pin HotRepl as a flake input. Replace `HOTREPL_REPO`, `HOTREPL_CORE_OUT`, and `HOTREPL_BEPINEX_OUT` with a build adapter that uses the pinned source contract and a writable repository-local artifact directory.
1. Keep only genuine machine state in `.env`: optional bottle selection, output directories, bind address, port, and explicit path overrides. Discover the normal game install from the Steam manifest and verify `Ardenfall_Data/Managed` before accepting it.
1. Add `doctor`, a checksum-pinned BepInEx 5 installer, build, deploy, launch, and export apps. The loader version is selected and reviewed in the project change; do not infer it from a nearby game or use an unversioned release URL.
1. Keep HotRepl bound to `127.0.0.1` by default. Preserve the existing explicit remote-code-execution warning and remote opt-in.
1. Make decompilation use a pinned dotnet tool manifest or Nix package. Do not install `ilspycmd` into an ad hoc ignored directory.

Ardenfall acceptance:

- a clean checkout restores frozen dependencies and passes the existing lint, type, controller, pipeline, site, fixture, and mod checks;
- `doctor` discovers application 1837770 and reports the installed build instead of assuming a path;
- loader installation is idempotent and a second run changes no owned files;
- the pinned HotRepl host and Ardenfall mod build from verified game assemblies without a sibling checkout;
- deploy writes the expected plugin set and configuration, launch starts the game through CrossOver, and one export produces a validated snapshot and pipeline artifact.

#### Ancient Kingdoms migration

Audit snapshot:

- The existing flake is the correct base, but it is only a development shell. Its only check evaluates that shell.
- `package.json` pins pnpm 10.34.5 while the current flake input provides pnpm 10.34.0. The shell comment claims pnpm self-switches, which permits a user-local download and violates the pinned-tool contract.
- The Python pipeline requires Python 3.14 and the mods and build tool use .NET SDK 10. The existing selections are otherwise aligned.
- `scripts/update-server-scripts.sh` expects ambient SteamCMD and installs `ilspycmd` 10.1.1.8388 into `.ilspycmd/` on demand.
- `Local.props` correctly represents machine-local game, export, CrossOver, and HotRepl paths. Preserve the local-path role, but remove the sibling HotRepl checkout as the default dependency.
- The current Steam install is application 2241380, build 24628084, with MelonLoader 0.7.3 Open-Beta and Unity 6000.3.21f1.

The `nix-development-environment` change must:

1. Keep the existing flake authoritative. Pin or package pnpm 10.34.5 exactly, retain Python 3.14 and .NET SDK 10, and add every command the canonical workflows use, including SteamCMD when licensing and platform support permit it.
1. Export real packages, apps, and checks. At minimum, cover the Python pipeline, build-tool tests, mod compilation that does not need proprietary references, and website validation.
1. Add the common environment wrapper for GUI hooks and bootstrap. Use a shell sentinel; do not treat the presence of `uv`, `pnpm`, or `dotnet` as proof that all pinned tools are active.
1. Move `ilspycmd` 10.1.1.8388 into `.config/dotnet-tools.json` or an exact Nix package. Keep the rule that a decompiler bump and game-version bump are separate reviewed changes.
1. Pin HotRepl and build its MelonLoader host through the downstream contract. `HOTREPL_REPO_PATH` may remain an explicit development override, but it must not be the default or clean-checkout path.
1. Add a checksum-pinned MelonLoader installer. Adopt the observed 0.7.3 Open-Beta layout only when its owned-file manifest matches. Preserve `UserData`, `Mods`, configuration, generated IL2CPP assemblies, and logs. Never run it from workstation activation.
1. Keep `Local.props` for the game path and genuinely local export paths. Make non-interactive setup and `doctor` derive and verify the ordinary CrossOver values.
1. Route server reference updates through the pinned shell and SteamCMD. Preserve `SNAPSHOT.toml`, assembly hashes, versioned backups, and the citation-drift checks.

Ancient Kingdoms acceptance:

- the flake exposes pnpm 10.34.5, Python 3.14, .NET SDK 10, and pinned `ilspycmd`;
- a clean checkout restores frozen pnpm, uv, and dotnet dependencies and passes build-tool, pipeline, mod, and website checks;
- `doctor` verifies application 2241380, the current build, Unity version, MelonLoader layout, and generated reference assemblies;
- installer re-entry is a no-op, and deployment preserves unowned mods and loader state;
- the pinned HotRepl MelonLoader host and project mods build and deploy;
- launch reaches the expected MelonLoader and HotRepl readiness banners, and one compendium export completes with verified artifacts.

#### Erenshor migration

Audit snapshot:

- The existing flake is the strongest project base. It already pins Python 3.14 through uv2nix, .NET SDKs 9 and 10, Node 22, pnpm 10, AssetRipper, SQLite, and gitleaks across four systems. CI executes every verification leaf through the Linux flake environment.
- Bootstrap is already cold-reachable as `nix run .#bootstrap`. Entering the shell does not restore dependencies or mutate lockfiles; the existing shell hook unsets the inherited `PYTHONPATH` and exports the checkout root for uv2nix editable sources.
- `packages.python` incorrectly uses `workspace.deps.all`, so the nominal package includes development dependencies and has an observed 1.9 GiB closure. The default development shell has an observed 4.1 GiB closure.
- The flake has no default runnable application. Its checks only realize bootstrap, the Python environment, and the shell.
- `scripts/with-dev-env.sh` treats any `uv` on `PATH` as proof that the complete shell is active.
- Project metadata reports `2.0.0-alpha.1`, while `src/erenshor/__init__.py` reports `0.1.0`. The local interpreter is 3.14 while mypy targets 3.13; the change must make that distinction intentional or align it.
- `mod dev-setup` installs optional tools only after BepInEx already exists. There is no canonical loader installer.
- MapTileCapture currently binds `ws://0.0.0.0:18586`. The installed log confirms that non-loopback default.
- The current Steam install is application 2382520, build 24405256, with BepInEx 5.4.23.5. Lunaris remains a separate supported loader.
- `erenshor extract packages` downloads the Unity Editor NuGet payload from nuget.org using versions from `src/Assets/packages.config`, but no hashes or ecosystem lock cover those archives.
- Native projects have zero `packages.lock.json` files and no Central Package Management. Twelve projects contain 36 floating references across six packages: `Microsoft.NET.Test.Sdk` `17.1*`, `xunit` `2.*`, `xunit.runner.visualstudio` `2.*`, `coverlet.collector` `6.*`, `BepInEx.Core` `5.*`, and `Fleck` `1.*`. Implicit `dotnet test` restore is therefore another unpinned acquisition path.
- The floating `BepInEx.Core` compile surface can drift away from the fixed BepInEx 5.4.23.5 runtime. Fleck is copied for ILRepack and changes published mod bytes. Exact versions are correctness requirements for both, not only lockfile hygiene.
- A repository-root `Directory.Packages.props` is safe: the only project outside `src/` is a generated, ignored Unity LSP project with no package references.

The `nix-development-environment` change must:

1. Keep the flake and uv2nix implementation. Preserve the four-system toolchain, cold-reachable bootstrap, lockfile-safe shell entry, and Nix-based CI. Split a runtime environment from development and test groups. Export `packages.default` and `apps.default` as the real `erenshor` CLI, while the development shell retains the full toolchain.
1. Replace executable-presence detection with an environment identity derived from the evaluated development shell or current flake inputs. Preserve the direnv-first and `nix develop` fallback for GUI hooks. Do not use `ERENSHOR_DEV_SHELL=1` or another boolean sentinel.
1. Add pure flake checks for the packaged CLI, a `--help` smoke, the Python unit suite, and the Python-only portion of `tests/contract`. Do not require maps or native .NET test leaves to run as sandboxed derivations in this change.
1. Reconcile the package version so the packaged CLI has one canonical version. Document separately whether Python 3.13 is a supported minimum tested apart from the Python 3.14 development environment.
1. Add read-only `doctor` to the canonical CLI and checksum-pinned BepInEx and Lunaris derivations. Loader installation consumes those store artifacts through CLI commands unless a dedicated cold-start app is necessary. The current BepInEx 5.4.23.5 installation may be adopted only after its owned files match the selected release. Keep `mod setup` for compile references and `mod dev-setup` for optional development plugins.
1. Preserve the existing loader status, activation, deployment, and CrossOver-aware launch implementation. `apps.default` exposes those CLI verbs; do not add one Nix wrapper app per verb.
1. Keep Unity Hub, Unity licensing, Steam authentication, and the installed game external. Keep AssetRipper and all host-side build tools in the flake. Materialize the Unity Editor NuGet payload from hash-pinned Nix derivations instead of downloading it in `extract packages`.
1. Replace every floating `PackageReference` with exact version intent in a repository-root `Directory.Packages.props`, using NuGet Central Package Management for the repeated packages. Generate and commit locks before enabling strict restore. Ordinary projects use `packages.lock.json`. The five loader-conditional production mods set `NuGetLockFilePath` once in `src/mods/Directory.Build.props` to `packages.$(ModLoader).lock.json` and commit both BepInEx and Lunaris locks; one framework-keyed lock cannot represent both property-selected graphs.
1. Extend bootstrap with a project-dependency restore stage in addition to the existing `dotnet tool restore`. It explicitly restores every native project and both loader variants with `--locked-mode`. Enable lock-file generation for local development, condition `RestoreLockedMode` on `ContinuousIntegrationBuild`, make CI set that property explicitly, and make tests consume the completed restore. Document the intentional lock-refresh command for dependency updates.
1. Configure Renovate so NuGet dependency updates regenerate every affected ordinary or per-loader lock file in the same pull request. A dual-loader package update refreshes both variants. A version-only bot change or a change that refreshes only one loader must fail locked restore.
1. Keep maps and native .NET leaves as normal CI commands inside `nix develop`, with `pnpm install --frozen-lockfile` and the explicit locked project restore as preceding steps. Offline `node_modules` or NuGet vendoring is not an acceptance requirement.

Non-gating Erenshor follow-ups remain recorded here until the owning repository creates issues or changes:

- Change MapTileCapture to loopback by default. A non-loopback bind requires explicit configuration and a security warning.
- Audit repository skills and remove duplicate or stale workflow instructions.
- Remove the retired `omp-plans` hook and `AGENTS.md` command as the first migration step. The global executable is gone; historical `docs/plans/` files may remain after active plans are archived or converted to OpenSpec.

These corrections do not block archival of `nix-development-environment`.

Erenshor acceptance:

- `nix run . -- --help` runs the packaged CLI without development-only dependencies, reports the canonical package version, and closure measurements demonstrate the runtime split;
- pure flake checks cover the packaged CLI, its smoke, and the scoped Python suites;
- bootstrap retains manifest-pinned `dotnet tool restore` and adds a separate locked project restore covering every native project and both loader graphs;
- exact centrally managed NuGet versions and committed ordinary or per-loader lock files govern bootstrap and CI;
- a representative Renovate-style NuGet version update refreshes all affected locks, while fixtures with stale locks or only one refreshed loader variant fail locked restore;
- the complete existing local test matrix passes in the development shell and CI remains green;
- a bare GUI hook process enters the pinned environment through the wrapper;
- `doctor` reports application 2382520, the current build, available loaders, active loader, and CrossOver launch plan;
- both loader installers are idempotent and refuse unknown proxy DLLs;
- one maintained mod builds, deploys, activates, and launches for BepInEx; one dual-loader mod also completes the Lunaris build and deployment path;
- one end-to-end data operation completes through the canonical CLI, such as extraction export, map capture, or a local publish dry run.

#### Project migration completion rule

Do not merge the four migrations into one OpenSpec change or one cross-repository commit. Follow the dependency graph above. After each project passes:

1. archive its OpenSpec change;
1. move accepted commands and invariants into that repository's specifications, README, and `AGENTS.md`;
1. update this document's current-state row with the archived change name and exact acceptance command set;
1. remove obsolete Homebrew instructions, hard-coded host paths, ambient-tool fallbacks, and sibling-checkout defaults that the migration replaces;
1. retain durable ownership for orthogonal findings that were explicitly classified as non-gating;
1. leave CrossOver payloads and ignored local configuration in place.

### Legacy cleanup

Host cutover passed. `omp-agent-setup` removed the global mutable bootstrap, symlink deployment, OMP source patches, executable repointing, global installers, fleet scanner, `omp-skill`, `omp-plans`, personal agent payloads and generators, and local-model references. No aliases or compatibility shims remain. Each project migration still owns that repository's hard-coded host paths, duplicated policy, and historical calls to retired tools.

### Experiments

After the base and project-independent acceptance gates pass, run the frontend and memory experiments under mutually isolated configurations. Any adoption is a separate change.

## Activation, verification, and rollback

The [dependency-update runbook](../operations/dependency-updates.md) owns schedules, automation credentials, native update commands, and remote merge policy.

A plugin release changes an immutable input. Update `personal-omp-plugin`, run the repository gates, activate the reviewed generation, and run `verify-personal-omp` explicitly. The verifier must print the observed OMP version, immutable plugin store path, and `omp: current` Herdr status.

An OMP release changes only the platform-owned executable. Use Homebrew on Darwin or the official binary installer in NixOS/WSL. Do not change `flake.lock` or activate Nix for an OMP-only update. Run `verify-personal-omp` after every OMP update.

After an OMP or plugin behavior change, start a fresh wrapped OMP session. Ask it to report the loaded `@glockyco/personal-omp-plugin` source path, quote the personal policy, and run `personal_commit` with `action=preview`. The path must be under `/nix/store`, and preview must not change the repository.

On WSL, follow the [korolev provisioning runbook](../operations/wsl-omp-bootstrap.md) and run `sudo nixos-rebuild switch --flake .#korolev` from the reviewed clone. Run one distribution at a time, and confirm that `user@1000.service` reports `active` before activation. NixOS activation reconciles Herdr but does not install, update, or invoke OMP. Run `verify-personal-omp` explicitly after activation. Retain the previous NixOS generation until local verification and the real-session smoke pass.

For an activation-mutation audit, stop other OMP sessions and capture file type, mode, modification time, and size before and after activation. This form is BSD `stat` for the Darwin host, and the runbook states the Linux form:

```sh
stat -f '%N type=%HT mode=%Sp mtime=%Sm size=%z' \
  "$HOME/.omp/agent" \
  "$HOME/.omp/agent/config.yml" \
  "$HOME/.omp/agent/agent.db" \
  "$HOME/.omp/agent/history.db"
```

The directory and files remain user-owned, writable, and non-symlinked. A normal OMP session can change database times and sizes; the activation itself must not replace or rewrite them. Herdr alone owns `~/.omp/agent/extensions/herdr-omp-agent-state.ts` through its supported integration command.

Retain the previous Nix generation until the new generation passes the explicit local verifier and real-session smoke. Confirm the rollback target without a pager:

```sh
sudo darwin-rebuild --list-generations | cat
```

Restore the immediately previous generation with `sudo darwin-rebuild --rollback`, or select one with `sudo darwin-rebuild --switch-generation <number>`. Then run `verify-personal-omp` and the real-session smoke. Nix rollback changes immutable wrapper, plugin, Herdr, OpenSpec, and language-server paths. It does not change the platform-owned OMP executable or OMP-owned runtime state. Recover an OMP release through its platform installer.

## Acceptance gates

The environment is complete when:

- one Nix generation selects the OMP wrapper, Herdr, OpenSpec, language servers, and the personal plugin;
- each wrapper invokes one explicit platform-owned OMP executable without a fallback;
- the plugin loads from an immutable store path without a mutable checkout;
- mutable OMP authentication, preferences, sessions, history, and caches survive activation unchanged;
- no global Bun, npm, Python, .NET tool, or Homebrew toolchain is required by the plugin;
- the STE skill has audited Issue 9 traceability and complete rule-identifier coverage;
- the research workflow passes deterministic retrieval tests and a release smoke retains Sci-Hub support;
- the commit extension creates a real hooked commit with one correctly formatted causal body;
- the representative LSP matrix passes;
- Herdr starts a real session through the wrapped OMP binary;
- the WSL bootstrap installs the official prebuilt OMP binary at its fixed user-local path, preserves the global work Git identity and OMP-owned state, reports current Herdr integration, and passes the real Windows Terminal session smoke;
- native image generation succeeds with the configured provider;
- each migrated game repository proves its complete host-to-game workflow;
- experiments produce reviewable results and no experimental state remains active accidentally;
- removing the legacy deployment does not remove any accepted capability;
- rolling back a Nix generation restores the prior immutable wrapper environment without changing the platform-owned OMP executable or mutable OMP state.

## Decision log

### 2026-08-08

- Keep `omp-agent-setup` as an independently packaged plugin instead of folding its source into `nix-darwin`.
- Delete the old Air Mnemopi database rather than preserve or migrate it.
- Plan both frontend-skill and persistent-memory experiments after the stable base.
- Remove personal agents and local models completely from the target and backlog.
- Preserve explicit ASD-STE100 Issue 9 traceability, all 53 rule relationships, the controlled-dictionary boundary, and human-review disclaimer.
- Retain Sci-Hub in the paper-acquisition workflow.
- Keep active OpenSpec changes actionable; use issues for planned work blocked by the base.

### 2026-08-12

- Count verified repository work delivered before an OpenSpec change instead of rebuilding it.
- Prefer one packaged default CLI over per-verb Nix wrapper apps.
- Use identity-bearing development-shell detection; executable presence and boolean sentinels do not prove the selected flake generation.
- Fetch immutable public archives through hash-pinned Nix derivations. Runtime installers still verify owned mutable files before adoption.
- Allow HotRepl and Erenshor migrations to proceed independently after the workstation base.
- Remove repository calls to `omp-plans` before global legacy cleanup; they do not gate an otherwise complete environment migration.
- Keep maps and native .NET verification in CI through the pinned shell; do not require offline ecosystem vendoring merely to turn every leaf into a flake check.
- Require exact centrally managed NuGet versions and locked restore. Ordinary projects use one lock; loader-conditional mod graphs use distinct BepInEx and Lunaris locks because a framework-keyed lock cannot represent both.
- Generate every ordinary and per-loader lock before enabling strict mode. Keep intentional local update flows available, make CI strict, and require Renovate to refresh all affected variants with each NuGet version change.
- Keep manifest-pinned dotnet-tool restoration distinct from project dependency restoration. Bootstrap must perform both; `--locked-mode` applies to the project restore.
- Keep package-version reconciliation as an environment gate. Track MapTileCapture security and repository-skill cleanup as separate non-gating work.

### 2026-08-14

- Load the packaged extension explicitly with `--extension` in addition to `--plugin-dir`; the plugin directory supplies skills and rules, while explicit extension loading makes `personal_commit` available in a real session.
- Run a local verifier after Herdr reconciliation on every Home Manager activation. Keep the remote model-backed smoke as a release gate, not an activation dependency.
- Remove the mutable deployment implementation after two successful workstation activations and a real wrapped-session smoke. Preserve OMP-owned state and Herdr's supported extension only.
- Keep repository development tooling in a pinned `nix develop` shell. Do not retain global Bun shims for the plugin repository.
- Use retained nix-darwin generations as the rollback mechanism. Do not copy or restore mutable OMP databases as part of rollback.
- Let Renovate own JavaScript and GitHub Actions updates. Let the official flake updater own Nix inputs. Keep both systems review-only.
- Use a repository-scoped GitHub App token for flake pull requests so normal CI starts automatically. Keep merge, workstation activation, and the real OMP smoke under human control.

### 2026-08-15

- Store the dependency-updater App private key only in the protected `dependency-automation` control plane. Target repositories keep their update closure and CI contracts but no fleet-wide credential or local scheduler.
- Declare native Nix commands as argument arrays and allowlist their complete changed-path sets. Do not introduce a shared package-manager wrapper.

### 2026-09-01

- Support the work machine through Windows Terminal Stable and `x86_64` Ubuntu WSL 2. Do not make `nix-darwin` or WSL manage native Windows applications.
- Install OMP, OpenSpec, Herdr reconciliation, and verification as one named WSL profile entry with automatic profile rollback.
- Publish the signed Numtide cache from the root flake because input flake cache settings are not inherited.
- Let the bootstrap create only a missing OMP agent directory. Herdr remains the owner of its generated extension, and OMP remains the owner of all other mutable state.
- Keep the employer email as the WSL global Git identity and use the GitHub no-reply email only in the `nix-config` checkout.

### 2026-09-03

- Reverse the 2026-09-01 decision to install the WSL environment as one named user-profile entry with a hand-written bootstrap. Define the WSL machine as `nixosConfigurations.korolev`, and let `nixos-rebuild` own ordered activation, generation replacement, failure rollback, and the retained rollback target.
- State three layers of ownership for that machine. Windows owns Windows Terminal, WSL enablement, employer policy, native applications, and the editor. The NixOS host owns the Linux system scope, the user scope, and every executable path. OMP owns authentication, configuration, sessions, history, caches, logs, and databases.
- Reverse the 2026-09-01 decision to publish the signed Numtide cache from the root flake. Each host declares that substituter and key in system scope, because Nix discards a flake-provided key for a user who is not in `trusted-users` and warns on every command. A machine with neither host configuration passes both values as command-line flags.
- Keep `trusted-users` at `root` alone on the WSL host. Adding the interactive user would let any flake it evaluates add a substituter and a signing key.
- Run one WSL distribution at a time during the cutover. WSL shares one cgroup tree, so a second distribution with the same user ID cannot start its user manager, and an activation fails at its user unit reload.
- Record that the operator holds durable credentials for the local `Administrator` account. Import, NixOS activation, and both NixOS rollback paths run as the standard user.
- Add a separately applied Windows declaration. Nix renders one WinGet Configuration document and narrow Zen-policy and native-Neo scripts, but activation never executes them. The interactive user applies the document; only the official Zen installer can elevate inside it. A 64-bit PowerShell session authenticated with the local `Administrator` credential applies the scripts, which own only Zen's Program Files policy path and the checksum-pinned keyboard DLLs and registration.
- Accept DSC's weaker convergence boundary for native Windows state. Preview every apply, run a post-apply test, and prove re-entry, but do not claim generation or transactional rollback.
- Install the editor on Windows and keep it out of the Linux closure. Zed for Windows runs its remote server under `wsl.exe`, so every language server stays in the Nix closure without an SSH server or a display path.
- Keep Fork against the WSL worktree through checksum-pinned `wslgit`. This removes Windows Git's filesystem traversal but retains a measured per-command WSL process cost.
- Give portable AltSnap sole ownership of modifier dragging and edge or corner snapping. PowerToys owns only Command Palette; Grab And Move and FancyZones stay disabled.
- Install native `kbdneo` for the base Neo layout in ordinary, elevated, and UAC surfaces. At each logon, use the separate Administrator credential to start the per-user ReNeo executable with `RunAs`; one elevated instance supplies higher layers to ordinary and elevated applications. UAC's secure desktop remains native-driver-only.
- Apply Catppuccin Mocha with Mauve accents to Windows Terminal, Zed, and Zen from pinned upstream theme data.
- Prefer English (United Kingdom) for the Windows interface while retaining the Austrian region, German input methods, and native Neo default. Use ISO 8601 for short dates instead of the British slash-separated format.
- Declare a rootless container runtime with Docker command compatibility inside the NixOS host. WSL 2 already provides the Linux virtual machine that Colima provides on macOS.
- Instantiate one package set per system in the flake and hand it to that system's host. The dependency runs outward, so a host and an output cannot resolve a package differently.
- Provide the development shell on every supported system, because that shell installs the commit hook. A host without it has no local formatting gate and reports nothing.
- Run each continuous-integration leg with the Nix implementation that its host runs. `nix flake check` is implementation-sensitive, so a green leg under a different Nix is not evidence for the host.
- Derive the supported systems from one host binding table, so a supported system without a host, or a host without a gate, cannot be declared.

### 2026-09-04

- Transfer OMP executable ownership from Nix to the official platform distribution path. Homebrew owns Darwin; the official binary installer owns NixOS/WSL.
- Keep one Nix-managed wrapper and independently pinned personal plugin on both hosts. The wrapper names one platform path and has no fallback or `PATH` lookup.
- Keep Windows Zed on the wrapped NixOS/WSL `omp acp` command. Let Zed's native WSL remote start the agent with a Linux working directory. Do not configure an explicit local `wsl.exe` bridge or install a duplicate native Windows executable.
- Reverse the 2026-08-14 activation-verifier decision. Expose `verify-personal-omp` as an explicit command so Nix activation does not depend on mutable executable state.
- Recover OMP versions through the owning platform installer. Nix generation rollback restores the wrapper environment but does not change OMP.
- Declare each host's identity and OMP runtime once through typed `host.*` options. System modules read `config.host`, and user modules read `osConfig.host`.
- Keep one declaration for each shared fact. Both host scopes read the binary-cache values from shared data instead of copying them.
- Supply the shared-library ABI for OMP's downloaded Chromium through `programs.nix-ld.libraries`. Do not package Chromium with Nix, wrap the OMP executable with a browser-specific environment, or move OMP's browser cache and profile into the Nix store.
- Declare pinned, user-scope Brave as the dedicated Windows `browser-relay` application. Keep Zen as the interactive browser, keep Brave out of startup and default-browser resources, and do not use employer-managed Edge or Chrome for relay.
- Install the relay extension manually into Windows LocalAppData and load it only in a dedicated `OMP Relay` Brave profile. OMP and the browser own that mutable profile and extension state; Nix owns only the reviewed package declaration and rejection gates.
- Track nix-darwin pull request [#1815](https://github.com/nix-darwin/nix-darwin/pull/1815) for `services.tailscale.extraSetFlags`. Keep the compatible local option and launch daemon until an upstream release includes it.

## Primary references

- [ASD-STE100 official definition](https://www.asd-ste100.org/about_STE.html)
- [ASD-STE100 Issue 9 request](https://www.asd-ste100.org/STE_downloads.html)
- [STEMG white paper on STE and AI](https://www.asd-ste100.org/assets/files/WhitePaper-ASD-STE100_and_AI.pdf)
- [OpenSpec v1.8.0](https://github.com/Fission-AI/OpenSpec/releases/tag/v1.8.0)
- [OpenSpec workflows](https://github.com/Fission-AI/OpenSpec/blob/v1.8.0/docs/workflows.md)
- [OMP extension loading](https://github.com/can1357/oh-my-pi/blob/v17.2.15/docs/extension-loading.md)
- [OMP LSP configuration](https://github.com/can1357/oh-my-pi/blob/v17.2.15/docs/lsp-config.md)
- [OMP Mnemopi backend](https://github.com/can1357/oh-my-pi/blob/v17.2.15/docs/mnemosyne-memory-backend.md)
- [OpenViking](https://github.com/volcengine/OpenViking)
- [Git commit documentation](https://git-scm.com/docs/git-commit)
