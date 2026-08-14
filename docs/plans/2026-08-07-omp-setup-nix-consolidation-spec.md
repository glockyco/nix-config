______________________________________________________________________

## title: OMP Setup Nix Consolidation type: spec status: draft created: 2026-08-07 parent: superseded_by: archived:

**Superseded:** The accepted [Personal OMP Environment Architecture](../architecture/personal-omp-environment.md) replaces this design. Keep this file as historical evidence; do not implement it.

## Problem

`omp-agent-setup` is a maintained TypeScript project — 39 source modules, 30 test files, Biome, knip, commitlint, lefthook, renovate, a coverage gate, and a pinned Bun runtime — whose deliverable is 83 KB of the user's own Markdown. Measured composition:

| bucket                                                         | files |   KB | share |
| -------------------------------------------------------------- | ----: | ---: | ----: |
| `agent/skills/impeccable` + `agent/agents` (vendored upstream) |   147 | 2968 |   78% |
| `docs/plans/`                                                  |    18 |  288 |    8% |
| `src/` + `extensions/`                                         |    39 |  224 |    6% |
| `tests/`                                                       |    30 |  184 |    5% |
| `agent/` (the user's own content)                              |    17 |   83 |    2% |
| root tooling config                                            |    21 |   70 |    2% |

Most of its sophistication compensates for two problems this machine does not have. Imperative package managers: `scripts/install-lsp.sh` is 250 lines spanning `bun add -g`, `uv tool install`, `brew install`, `rustup component`, and `dotnet tool -g`, including workarounds for rustup's lying proxy stub and for `/etc/paths.d/dotnet-cli-tools` shipping an unexpanded `~`. Mutable dotfile deployment: `bootstrap` snapshots 20 generations before every mutation, because it edits live files in `$HOME`.

The repo is also not deployable here as written. `bun` is absent, `~/Projects` does not exist (the ghq root is `~/src`), and `remnote-mcp-server` is absent. Nothing under `~/.omp/agent/` is managed today.

Two mechanisms are outright incompatible with a Nix-provided `omp`. `bin-link` re-points `~/.bun/bin/omp` at `$BUN_INSTALL/install/global/node_modules/@oh-my-pi/pi-coding-agent/src/cli.ts` so the package runs from source, and `patches` then edits that TypeScript in place so the edits take effect. Under Nix, `omp` is `llmAgents.omp` in `/nix/store`, immutable, with no bun global install to re-point and no writable source to patch.

## Goal

One repository, one CI, no global toolchain, no Bun on `PATH`, no Homebrew formulae. Every capability either moves to a declarative Nix expression, survives as a Nix-built binary because it is genuinely per-repo and imperative, or is deleted with its reason recorded.

## Strategy

Assign every artifact to exactly one of three ownership zones, and never let two zones own one path.

1. **Nix owns provisioning.** Binaries, `omp` itself and its patches, vendored upstream content, read-only agent payloads, config overlays, launchd services. Immutable, reproducible, rolled back by generations.
1. **omp owns its runtime state.** `config.yml`, `mcp.json`, `agent.db`, `history.db`, `models.db`, `sessions/`, `logs/`, `blobs/`. Nix never writes these paths. This zone exists because omp writes them itself through `omp config set`, `/settings`, `/mcp add`, and `/mcp disable`.
1. **Two CLIs stay imperative.** `omp-plans` and `omp-skill` act on arbitrary repositories at runtime, discovered from the session working directory. Nix builds them and puts them on `PATH`. Nix does not run them.

Zone 2 is the reason the old repo's config merging existed, and it is the constraint that decides the whole design.

## Design

### Read-only config without merging

The old repo deep-merged four keys into `~/.omp/agent/config.yml` while preserving unrelated keys, with YAML AST surgery to keep key ordering stable and a `FORMER_MANAGED_CONFIG` list to retract keys it used to own. All of that exists because it wrote into a file omp also writes.

omp resolves settings through a precedence chain:

```
built-in defaults <- global config <- project config <- CLI overlays <- runtime overrides
```

`PI_CONFIG_FILES` takes a platform-delimited path list of overlay files that load before explicit `--config` overlays, sit above global and project config, and are never persisted. Nix writes an overlay to the store, `home.sessionVariables` exports `PI_CONFIG_FILES`, and omp keeps sole ownership of the mutable `config.yml`. The merge logic, its YAML dependency, its retraction list, and `tests/config.test.ts` all delete.

The same problem for MCP has a different solution. Their own boundary rule is explicit: *"Symlink `~/.omp/agent/mcp.json` into the repo the way `lsp.json` is → Keep it merged. OMP writes this file itself."* But the native provider also reads `~/.omp/agent/.mcp.json` for compatibility and writes only to the primary `mcp.json`. So Nix owns `.mcp.json` as a store symlink and omp keeps `mcp.json`. No merge, and the boundary rule is honoured rather than worked around.

`lsp.json` needs neither trick. omp never writes it, which is exactly why the old repo symlinked it, so a plain `home.file` is correct.

Accepted tradeoff: a `PI_CONFIG_FILES` overlay outranks project `.omp/config.yml`, so a repository cannot override an overlay key. The four keys are `extensions`, `skills.customDirectories`, `ask.timeout`, and `contextPromotion.enabled`, and none is a plausible per-repo override. If one becomes so, the fallback is to drop that single key from the overlay and seed it once with `omp config set`, leaving it in zone 2.

### Patches become build inputs

`llmAgents.omp` is a derivation with `src`, `patches`, `postPatch`, and `bunDeps`, so `overrideAttrs` can append patch files. The four patches move from runtime reapplication to build time:

| patch                                | target                                                  | intent                                                                                                                             |
| ------------------------------------ | ------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `convert-to-llm-content-guard`       | `pi-agent-core/src/compaction/messages.ts`              | drop undefined, empty, and non-array content during custom and hook message conversion, avoiding provider `.filter`/`.map` crashes |
| `tree-selector-custom-message-guard` | `pi-coding-agent/src/modes/components/tree-selector.ts` | default `entry.content` to `[]` so a malformed custom message does not crash the render                                            |
| `eval-write-protocol-delegation`     | `pi-coding-agent/src/eval/js/shared/prelude.txt`        | route non-`local://` schemes in eval `write()` through the real `write` tool                                                       |
| `eval-tool-device-delegation`        | `pi-coding-agent/src/eval/js/tool-bridge.ts`            | resolve `xd://` mounted tool devices from eval                                                                                     |

This deletes the drift class the old repo had to detect and report. `skip-anchor-missing` becomes a build failure instead of a silent runtime regression, `omp bin not pointed at source` becomes structurally impossible, `bootstrap` stops being a recovery path, and the `omp-session-env` extension's unpatched-bundle warning becomes dead code.

The first two patches are crash guards with no local policy in them, so they should be sent upstream. Once merged they delete permanently rather than being carried forever.

### Vendored content becomes pinned inputs

78% of the old repo is committed third-party content. None of it should be in git.

**Impeccable** ships an unversioned zip at `https://impeccable.style/api/download/bundle/universal`. `pkgs.fetchzip` with a pinned hash makes it reproducible and, because the URL is unversioned, makes upstream movement a loud hash mismatch instead of silent drift. The existing transforms all become build phases of one derivation: rewrite `.pi` script paths to `$OMP_AGENT_DIR/skills/impeccable`, apply `IMPECCABLE_VENDOR_FIXES`, assert the Pi provider id and reject forbidden provider markers in Markdown, and translate the four `.claude/agents/` definitions into omp front matter. The translator is kept as TypeScript and invoked in the build, because reimplementing a tested front-matter translator in Nix would be strictly worse. 2.9 MB leaves git and `agent/skills/impeccable` stops existing as a tracked path.

**simple-english** is already pinned to commit `379728b51981b6d2ee1de0f201164483a9648972` in `src/optional-skills.ts`, so `fetchFromGitHub` expresses it directly and `vendored-skill-update.ts` plus its unauthenticated GitHub API client delete.

**Plannotator** is a fork the user actively develops, so it needs two representations, not one. A `flake = false` input pinned by `flake.lock` supplies the built extension that omp consumes, replacing `manifests/plugins.yml`. A normal clone under `~/src` is where rebasing happens. The manifest's `currentCommit` is vestigial today — it is parsed and never compared — so `flake.lock` is a strict improvement rather than a like-for-like port.

### Content deployment splits by edit frequency

The user's own 83 KB is edited often, and requiring `darwin-rebuild switch` for a prose fix would be a regression against the old symlink deployment. `mkOutOfStoreSymlink` points `~/.omp/agent/` entries at the live working tree, so edits land immediately.

Vendored and generated content goes to store paths instead, because it is not hand-edited and store paths give it the reproducibility and garbage-collection roots it should have.

The old repo's five name registries (`managed-skills`, `managed-rules`, `managed-agents`, `optional-skills`, `MANAGED_MCP_SERVERS`) become Nix lists in the module that consumes them. Their documented hazard — *"`planManagedLinks` never checks that a source exists, so a name registered ahead of its file deploys a dangling symlink"* — becomes an evaluation error, because a missing path fails at build time.

### The imperative residue

`omp-skill enable <name>` creates `<repo>/.omp/skills/<name>` pointing at `~/.omp/agent/optional-skills/<name>` and adds an anchored line to that repository's `.git/info/exclude`. The target repository is arbitrary and chosen at runtime, and the two-hop indirection is deliberate so re-vendoring reaches every opted-in repo with nothing re-run. This cannot be declarative and should not be.

`omp-plans` is working-directory-scoped onto `./docs/plans/`, no-ops when absent, and sweeps a fleet on demand. Also correctly imperative.

Both keep their TypeScript sources and their tests, built by Nix through `bun2nix` from the `llm-agents` input. Bun becomes a build input, not a global toolchain, which satisfies the README's *"No global toolchains"* rule while keeping tested code tested.

Both hardcode `~/Projects` for fleet sweeps and must move to the ghq root `~/src`.

### What replaces doctor and verify

`doctor` checked that symlinks resolve, payloads exist, the plugin has a `.git`, the bin points at source, and `mcp.json` deep-equals the registry. Under Nix the first four are structurally guaranteed and the fifth is obviated by `.mcp.json`, so most of `doctor` has nothing left to check. `nix flake check` covers the structural half, extended with a module-import assertion in the style of the existing `checks.moduleImports`.

`verify`'s live gates are worth keeping in spirit, and two of its checks are weaker than they look: `ompDirectSmoke` and `ompExtensionSmoke` assert only expected stdout, never subprocess exit code or timeout, so a failing `omp` that still printed the token passes. A replacement smoke check should assert exit status.

Genuinely runtime health — is a daemon answering, is a GUI app running — has no subject on this machine until RemNote returns, so it is deferred rather than ported.

### Deletions

| Deleted                                                                 | Because                                                  |
| ----------------------------------------------------------------------- | -------------------------------------------------------- |
| `scripts/install-lsp.sh`, `src/lsp-channels.ts`                         | 20 servers are in the pinned nixpkgs                     |
| `src/bootstrap.ts`, `src/backup.ts` and runtimes                        | store paths are immutable, generations are the snapshots |
| `src/bin-link.ts` and runtime                                           | Nix owns the binary                                      |
| `src/patches-runtime.ts`                                                | patches apply at build time                              |
| `src/plugins.ts` and runtime, `manifests/plugins.yml`                   | `flake.lock` pins inputs                                 |
| `src/config.ts`, `src/mcp.ts` merge halves                              | overlay plus `.mcp.json`                                 |
| `src/impeccable-update-runtime.ts`, `src/vendored-skill-update*.ts`     | `fetchzip` and `fetchFromGitHub`                         |
| `src/omp-update.ts`, `src/verify.ts`, most of `src/cli.ts`              | `nix flake update` and `darwin-rebuild switch`           |
| `config/config.yml.template`                                            | stale and never consumed by any code path                |
| `config/plannotator.json.template`                                      | no consumer exists                                       |
| `omp-session-env.ts` bin-check half                                     | guards a failure mode Nix makes impossible               |
| root Biome, knip, commitlint, lefthook, renovate, `bun.lock`, CI matrix | scoped down to what two small tools need                 |

## Acceptance

1. `bun` is absent from `PATH` and from `home.packages`, and `/opt/homebrew/Cellar` contains no formulae.
1. `omp` starts and `omp --version` reports the `llm-agents` pin.
1. All nine managed skills, two rules, and four Impeccable agents are discovered in a fresh session, and `simple-english` is **not** discovered until a repository opts in.
1. Editing `agent/skills/commit/SKILL.md` in the working tree changes what the next session reads, with no rebuild.
1. `omp config list` shows `ask.timeout` as `0` and `contextPromotion.enabled` as `false`, while `~/.omp/agent/config.yml` remains writable and omp-owned. `omp config set theme.dark <value>` still persists.
1. Every one of the 20 language servers resolves on `PATH`, and `agent/lsp.json` is present at `~/.omp/agent/lsp.json`.
1. The four patches are present in the built `omp` source, verified by grepping the store path for each `appliedSignature`.
1. `omp-plans index` and `omp-plans check` succeed in this repo, and `omp-skill list` runs. Neither hardcodes `~/Projects`.
1. `nix flake check` passes, including the module-import assertion.
1. No path under `~/.omp/agent/` is written by both Nix and omp.
1. `git ls-files` in this repo lists no vendored Impeccable payload.

## Risks

**Patch anchors may have drifted.** The patches were written against whichever omp version the old machine ran, and the pin here is 17.2.10. Literal anchors are whitespace-sensitive and exactly one match is required. Each patch must be checked against the pinned source before the overlay is wired, and any patch whose anchor is gone is either re-anchored or dropped as no longer needed.

**Two servers are not equivalent substitutions.** nixpkgs ships `kotlin-language-server` (fwcd), while the old repo installed JetBrains `kotlin-lsp` from a macOS-only tap. They are different implementations. Separately, `agent/lsp.json` sets `command: roslyn-language-server`, and the nixpkgs attribute is `roslyn-ls`, so the installed binary name must be confirmed and the override corrected if it differs.

**`fetchzip` on an unversioned URL is brittle by construction.** Upstream can change the bundle under a stable URL, which surfaces as a hash mismatch. That is the desired failure direction, but it does mean the build breaks on upstream movement rather than degrading, and the hash bump is a manual step.

**`mkOutOfStoreSymlink` couples the deployment to an absolute path.** `~/.config/nix-darwin` must stay put, and the content is outside the store so `nix flake check` cannot validate it.

**Plannotator needs a real build.** The old setup only ever reconciled a checkout and relied on the user having built `apps/pi-extension`. Packaging it is new work, not a port, and it is the one task here whose effort is genuinely unknown until attempted.
