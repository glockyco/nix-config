______________________________________________________________________

## title: OMP Setup Nix Consolidation Tasks type: plan status: draft created: 2026-08-07 parent: 2026-08-07-omp-setup-nix-consolidation-spec superseded_by: archived:

**Superseded:** The accepted [workstation contract](../../openspec/specs/personal-omp-workstation/spec.md) replaces this task list. Keep this file as historical evidence; do not execute it.

## File map

New modules under `modules/home/omp/`, each owning one surface:

- Create `modules/home/omp/default.nix`: imports the sibling omp modules. Nothing else.
- Create `modules/home/omp/lsp.nix`: owns the 20 language-server packages and deploys `agent/lsp.json`.
- Create `modules/home/omp/content.nix`: owns every payload under `~/.omp/agent/` — `AGENTS.md`, `RULES.md`, `skills/`, `rules/`, `agents/`, `optional-skills/`, `extensions/`.
- Create `modules/home/omp/config.nix`: owns the `PI_CONFIG_FILES` overlay and `~/.omp/agent/.mcp.json`.
- Create `modules/home/omp/tools.nix`: owns the three Nix-built CLIs.
- Modify `modules/home/default.nix`: add `./omp` to `imports`. Required — `checks.moduleImports` fails otherwise.

Content and sources migrated from `glockyco/omp-agent-setup`:

- Create `agent/AGENTS.md`, `agent/RULES.md`, `agent/lsp.json`: user-level context, sticky rules, LSP overrides.
- Create `agent/skills/<name>/`: the nine managed skills, minus `impeccable`, which becomes a derivation.
- Create `agent/rules/planning-docs.md`, `agent/rules/remnote.md`.
- Create `extensions/omp-session-env.ts`, `extensions/impeccable-hook.ts`, `types/omp.d.ts`.
- Create `tools/` holding `omp-plans`, `omp-skill`, and `omp-lsp-audit` sources plus their tests.

Derivations and overlays:

- Create `packages/impeccable.nix`: fetch, transform, and translate the Impeccable bundle.
- Create `packages/omp-tools.nix`: build the three CLIs with `bun2nix`.
- Create `overlays/omp-patches.nix`: apply the four source patches to `llmAgents.omp`.
- Create `patches/*.patch`: the four patch files.
- Modify `flake.nix`: add the `plannotator` and `impeccable-translator` inputs, register the overlay, extend `checks`.

Not migrated, and deliberately absent from this map: `src/bootstrap.ts`, `src/backup.ts`, `src/bin-link.ts`, `src/patches-runtime.ts`, `src/plugins.ts`, `src/config.ts`, `src/mcp.ts`, `src/omp-update.ts`, `src/verify.ts`, `src/cli.ts`, `scripts/install-lsp.sh`, `src/lsp-channels.ts`, `manifests/plugins.yml`, `config/*.template`, and the root Biome, knip, commitlint, lefthook, and renovate configuration. The spec records why each one goes.

## Tasks

### Task 1: Language servers from nixpkgs

**Files:**

- Create: `modules/home/omp/lsp.nix`

- Create: `modules/home/omp/default.nix`

- Create: `agent/lsp.json`

- Modify: `modules/home/default.nix`

- [ ] Add the 18 language-server packages to `home.packages` in `lsp.nix`: `typescript-language-server`, `typescript`, `svelte-language-server`, `vscode-langservers-extracted`, `yaml-language-server`, `bash-language-server`, `tailwindcss-language-server`, `dockerfile-language-server`, `basedpyright`, `ruff`, `rust-analyzer`, `taplo`, `marksman`, `texlab`, `jdt-language-server`, `metals`, `lua-language-server`, `roslyn-ls`.
  Verification: `nix build --no-link .#darwinConfigurations.macbook-pro.system`
  Expected: builds, proving every attribute resolves in the pinned nixpkgs.

- [ ] Copy `agent/lsp.json` verbatim from the old repo, then correct its `$comment` to reference this repo instead of `scripts/install-lsp.sh`.
  Verification: `nix eval --raw --impure --expr '(builtins.fromJSON (builtins.readFile ./agent/lsp.json)).servers.taplo.command'`
  Expected: prints `taplo`.

- [ ] Deploy it with `home.file.".omp/agent/lsp.json".source = ../../../agent/lsp.json`. A plain store symlink is correct because omp never writes this file.

- [ ] Add `./omp` to `imports` in `modules/home/default.nix` and create `modules/home/omp/default.nix` importing `./lsp.nix`.
  Verification: `nix flake check`
  Expected: passes, including `checks.moduleImports`.

- [ ] Apply and confirm every server binary resolves.
  Run: `sudo darwin-rebuild switch --flake .` then `for b in typescript-language-server tsserver svelteserver vscode-html-language-server vscode-css-language-server vscode-json-language-server vscode-eslint-language-server yaml-language-server bash-language-server tailwindcss-language-server docker-langserver basedpyright ruff rust-analyzer taplo marksman texlab jdtls metals lua-language-server; do command -v "$b" >/dev/null || echo "MISSING $b"; done`
  Expected: no `MISSING` lines. Any that print identify a binary whose nixpkgs attribute ships a different executable name, which is then fixed in `lsp.nix` or overridden in `agent/lsp.json`.

- [ ] Resolve the two known substitution mismatches. Confirm the C# server binary name with `ls "$(nix eval --raw .#inputs.nixpkgs.legacyPackages.aarch64-darwin.roslyn-ls)"/bin` and set `agent/lsp.json`'s `roslyn-language-server.command` to the real name. Add `kotlin-language-server` and change the `kotlin-lsp` entry to match fwcd's server, or mark Kotlin unsupported by disabling it.
  Verification: `command -v "$(nix eval --raw --impure --expr '(builtins.fromJSON (builtins.readFile ./agent/lsp.json)).servers."roslyn-language-server".command')"`
  Expected: prints a path under `/etc/profiles/per-user`.

- [ ] Commit.
  Message: `feat(omp): install language servers from nixpkgs`

### Task 2: Deploy the user's own agent content

**Files:**

- Create: `agent/AGENTS.md`, `agent/RULES.md`

- Create: `agent/skills/{commit,writing-project-readmes,writing-agent-instructions,planning-files,writing-plans,searching-literature,retrieving-paper-pdfs,formatting-bibtex-entries}/`

- Create: `agent/rules/planning-docs.md`, `agent/rules/remnote.md`

- Create: `extensions/omp-session-env.ts`, `extensions/impeccable-hook.ts`, `types/omp.d.ts`

- Create: `modules/home/omp/content.nix`

- Modify: `modules/home/omp/default.nix`

- [ ] Copy the eight non-Impeccable managed skills, both rules, both extensions, and `types/omp.d.ts` from the old repo unchanged. `impeccable` is excluded here and arrives in Task 6.

- [ ] Write `agent/RULES.md` carrying the constraint that installs go through Nix: no `brew install`, `pip install`, `npm i -g`, `cargo install`, or `uv tool install`, one-offs use `nix shell nixpkgs#<pkg> -c <cmd>`, permanent additions go in this flake, and `homebrew.onActivation.cleanup = "uninstall"` reaps undeclared formulae. `RULES.md` rather than `AGENTS.md` because sticky rules are re-attached near the current turn instead of decaying out of the opening context.

- [ ] Delete `checkOmpBin`, `decideOmpBinWarning`, `OmpBinWarningState`, `OmpBinWarningDecision`, `OmpSessionEnvFs`, and `OMP_UNPATCHED_BUNDLE_MESSAGE` from `extensions/omp-session-env.ts`, keeping `installSessionEnvVars` and the `session_start` registration. There is no bun global bin under Nix, so the warning can never fire truthfully.
  Verification: `grep -c 'unpatched bundle' extensions/omp-session-env.ts`
  Expected: `0`.

- [ ] In `content.nix`, deploy each payload with `config.lib.file.mkOutOfStoreSymlink` rooted at `${config.home.homeDirectory}/.config/nix-darwin/agent` so prose edits take effect without a rebuild. Cover `AGENTS.md`, `RULES.md`, `skills/<name>`, `rules/<name>.md`, and `extensions/<name>.ts`. Derive the skill and rule name lists from `builtins.attrNames (builtins.readDir ./../../../agent/skills)` so a payload cannot be registered ahead of its file.
  Verification: `sudo darwin-rebuild switch --flake . && readlink ~/.omp/agent/skills/commit`
  Expected: prints a path inside `~/.config/nix-darwin/agent/skills`, not a store path.

- [ ] Confirm omp discovers the skills and that none is the optional payload.
  Run: `omp -p --no-session 'List every skill name you can see, one per line, nothing else'`
  Expected: the eight managed skill names appear. `simple-english` does not.

- [ ] Confirm live editability.
  Run: `printf '\n<!-- probe -->\n' >> agent/skills/commit/SKILL.md && grep -c probe ~/.omp/agent/skills/commit/SKILL.md && git checkout agent/skills/commit/SKILL.md`
  Expected: prints `1` with no rebuild, then the working tree is restored.

- [ ] Commit.
  Message: `feat(omp): deploy agent content from the flake`

### Task 3: Read-only config overlay and MCP base

**Files:**

- Create: `modules/home/omp/config.nix`

- Modify: `modules/home/omp/default.nix`

- [ ] Generate the overlay with `pkgs.writeText` holding the four managed keys: `extensions` listing `~/.omp/agent/extensions/omp-session-env.ts` and `~/.omp/agent/extensions/impeccable-hook.ts`, `skills.customDirectories` as an empty list until Task 9 adds Plannotator, `ask.timeout = 0`, and `contextPromotion.enabled = false`.

- [ ] Export it with `home.sessionVariables.PI_CONFIG_FILES = "${overlayFile}"`.
  Verification: `sudo darwin-rebuild switch --flake . && exec zsh -l && omp config get ask.timeout && omp config get contextPromotion.enabled`
  Expected: `0` and `false`.

- [ ] Confirm omp keeps ownership of the mutable global config.
  Run: `omp config set theme.dark titanium && grep -c 'titanium' ~/.omp/agent/config.yml`
  Expected: at least `1`, and `~/.omp/agent/config.yml` is a regular writable file, not a symlink.

- [ ] Deploy `home.file.".omp/agent/.mcp.json"` as a store symlink containing `{"mcpServers":{}}`. The compat path is read by omp and never written by it, so this satisfies the old repo's rule against symlinking `mcp.json` without needing a merge step. No RemNote entry is added — the binary is not installed on this machine.
  Verification: `omp -p --no-session 'Reply with exactly: MCP_OK'; echo "exit=$?"`
  Expected: output contains `MCP_OK` and `exit=0`, proving the empty base file does not break startup.

- [ ] Commit.
  Message: `feat(omp): supply managed config through a read-only overlay`

### Task 4: Rewrite the deployed agent context for this repo

**Files:**

- Modify: `agent/AGENTS.md`

- [ ] Replace every `~/Projects/omp-agent-setup` reference with `~/.config/nix-darwin`, and replace the `bun run bootstrap` / `bun run doctor` / `bun run verify` recovery instructions with `sudo darwin-rebuild switch --flake .` and `nix flake check`.

- [ ] Replace the "Conventions and recovery" paragraph so it names this flake as owner of `~/.omp/agent/`, states that skills and rules are edited in `agent/` and take effect immediately through out-of-store symlinks, and states that `config.yml` and `mcp.json` remain omp-owned.

- [ ] Correct the stale substitution example. The old root `AGENTS.md` describes `omnisharp` → `csharp-ls`, but `agent/lsp.json` disables both and routes C# through `roslyn-language-server`.
  Verification: `grep -n 'csharp-ls' agent/AGENTS.md agent/lsp.json`
  Expected: matches only in `agent/lsp.json`, as a `disabled` entry.

- [ ] Verify no stale path survives anywhere in the migrated content.
  Run: `grep -rn 'Projects/\|bun run \|\.bun/bin' agent/ extensions/`
  Expected: no output.

- [ ] Commit.
  Message: `docs(omp): retarget agent context at the nix flake`

### Task 5: Optional skill as a pinned source

**Files:**

- Modify: `modules/home/omp/content.nix`

- [ ] Fetch `simple-english` with `pkgs.fetchFromGitHub` using `owner = "AminBlg"`, `repo = "SimpleEnglish"`, and `rev = "379728b51981b6d2ee1de0f201164483a9648972"`, the commit already recorded in the old `src/optional-skills.ts`. Deploy `${src}/skills/simple-english` to `~/.omp/agent/optional-skills/simple-english` as a store symlink, since vendored content is not hand-edited.
  Verification: `sudo darwin-rebuild switch --flake . && head -3 ~/.omp/agent/optional-skills/simple-english/SKILL.md`
  Expected: front matter with `name: simple-english`.

- [ ] Confirm the payload stays invisible, which is the whole point of the opt-in.
  Run: `omp -p --no-session 'List every skill name you can see, one per line, nothing else'`
  Expected: `simple-english` is absent.

- [ ] Commit.
  Message: `feat(omp): pin the simple-english optional skill`

### Task 6: Impeccable as a build product

**Files:**

- Create: `packages/impeccable.nix`

- Create: `tools/impeccable-translate/` holding the front-matter translator ported from `src/impeccable-agents.ts` and the vendor fixes from `src/impeccable-update.ts`

- Modify: `flake.nix`, `modules/home/omp/content.nix`

- [ ] Fetch the bundle with `pkgs.fetchzip { url = "https://impeccable.style/api/download/bundle/universal"; hash = ...; }`. Obtain the hash by building once with `lib.fakeHash` and reading the mismatch error.
  Verification: `nix build --no-link .#impeccable`
  Expected: builds. A later upstream change surfaces as a hash mismatch, which is the intended fail-closed behaviour.

- [ ] In the build phase, rewrite the skill's project-local `node .pi/...` script paths to `${OMP_AGENT_DIR:-$HOME/.omp/agent}/skills/impeccable`, and rewrite the update instruction to name this flake rather than `bun run update-impeccable`.
  Verification: `grep -rn '\.pi/' "$(nix build --no-link --print-out-paths .#impeccable)/skills/impeccable" | grep -v 'IMPECCABLE_PROVIDER_ID'`
  Expected: no output.

- [ ] Apply the three vendor fixes as build-time patches: `omp-hook-detection` short-circuiting on a truthy `IMPECCABLE_OMP_HOOK`, `concept-seed-fs-import` importing `realpathSync`, and `concept-seed-main-guard` comparing canonical realpaths so a symlinked invocation is not a silent no-op.
  Verification: `grep -c 'IMPECCABLE_OMP_HOOK' "$(nix build --no-link --print-out-paths .#impeccable)/skills/impeccable/scripts/context.mjs"`
  Expected: at least `1`. A zero means upstream moved the anchor and the fix needs re-anchoring.

- [ ] Assert the Pi variant, matching the old `IMPECCABLE_PROVIDER_ID = "pi"` check, and fail the build when a forbidden provider marker appears in the vendored Markdown.
  Verification: `nix build --no-link .#impeccable`
  Expected: builds, and the assertion is exercised because it runs unconditionally in `checkPhase`.

- [ ] Translate the four `.claude/agents/` definitions into omp front matter with the ported translator: keep the body verbatim, emit `name` and a quoted `description`, map `Read`/`Write`/`Edit`/`Bash`/`Glob`/`Grep` to lowercase and append `yield`, validate `effort` or `thinkingLevel` against the allowed set and emit `thinkingLevel`, and drop `model`, `maxTurns`, and `output`.
  Verification: `head -12 "$(nix build --no-link --print-out-paths .#impeccable)/agents/impeccable-finish-reviewer.md"`
  Expected: front matter with lowercase tools including `yield`, and no `model` or `maxTurns` key.

- [ ] Deploy `${impeccable}/skills/impeccable` and the four `${impeccable}/agents/*.md` as store symlinks under `~/.omp/agent/`.
  Verification: `sudo darwin-rebuild switch --flake . && omp -p --no-session 'List every subagent name you can see, one per line, nothing else'`
  Expected: all four `impeccable-*` names appear.

- [ ] Commit.
  Message: `feat(omp): build impeccable from a pinned bundle`

### Task 7: OMP patches as an overlay

**Files:**

- Create: `overlays/omp-patches.nix`

- Create: `patches/convert-to-llm-content-guard.patch`, `patches/tree-selector-custom-message-guard.patch`, `patches/eval-write-protocol-delegation.patch`, `patches/eval-tool-device-delegation.patch`

- Modify: `flake.nix`

- [ ] Check each anchor against the pinned omp source before writing any patch. The four targets are `pi-agent-core/src/compaction/messages.ts`, `pi-coding-agent/src/modes/components/tree-selector.ts`, `pi-coding-agent/src/eval/js/shared/prelude.txt`, and `pi-coding-agent/src/eval/js/tool-bridge.ts`.
  Run: `nix build --no-link --print-out-paths .#inputs.llm-agents.packages.aarch64-darwin.omp.src` then grep each anchor in the unpacked source.
  Expected: exactly one match per anchor. Zero matches means the patch is either obsolete or needs re-anchoring, and the decision is recorded in the spec's risk section before proceeding.

- [ ] Write the four patch files, preserving each original intent as tabulated in the spec.

- [ ] Add `overlays/omp-patches.nix` overriding `llmAgents.omp` with `overrideAttrs (old: { patches = (old.patches or []) ++ [ ... ]; })`, and register it in `flake.nix`'s overlay list.
  Verification: `nix build --no-link .#darwinConfigurations.macbook-pro.system`
  Expected: builds. A patch whose anchor does not apply fails here rather than silently regressing at runtime, which is the improvement over the old reapply-and-report model.

- [ ] Confirm each patch is present in the built output.
  Run: for each patch, grep the built omp store path for its distinguishing replacement text.
  Expected: one match each.

- [ ] Confirm omp still runs and reports the expected version.
  Run: `sudo darwin-rebuild switch --flake . && omp --version && omp -p --no-session 'Reply with exactly: PATCHED_OK'; echo "exit=$?"`
  Expected: version prints, output contains `PATCHED_OK`, and `exit=0`. Asserting the exit code closes the gap in the old `verify`, which checked stdout only.

- [ ] Open upstream pull requests for `convert-to-llm-content-guard` and `tree-selector-custom-message-guard`. Both are crash guards with no local policy, so carrying them forever is avoidable.

- [ ] Commit.
  Message: `feat(omp): apply source patches through an overlay`

### Task 8: The three surviving CLIs

**Files:**

- Create: `tools/omp-plans/`, `tools/omp-skill/`, `tools/omp-lsp-audit/` with the sources and tests ported from `src/plans*.ts`, `src/skill-cli.ts`, `src/repo-skill*.ts`, and `src/lsp-audit*.ts`

- Create: `packages/omp-tools.nix`

- Create: `modules/home/omp/tools.nix`

- Modify: `flake.nix`, `modules/home/omp/default.nix`

- [ ] Port the three tools with their existing tests. Keep the pure-logic and `-runtime` split, since it is what makes the logic testable without touching the filesystem.

- [ ] Change the fleet root from `~/Projects` to the ghq root `~/src` in all three, and read it from `programs.git.settings.ghq.root` rather than hardcoding it a second time.
  Verification: `grep -rn 'Projects' tools/`
  Expected: no output.

- [ ] Build all three with `bun2nix` from the `llm-agents` input so Bun is a build input and never lands on `PATH`.
  Verification: `nix build --no-link .#omp-tools && command -v bun`
  Expected: the build succeeds and `command -v bun` prints nothing.

- [ ] Run the ported test suites in `checkPhase`.
  Verification: `nix build --no-link .#omp-tools`
  Expected: builds with tests passing. A failure here is a genuine port regression.

- [ ] Add the package to `home.packages` in `tools.nix`.
  Verification: `sudo darwin-rebuild switch --flake . && omp-plans check && omp-skill list && omp-lsp-audit ~/src`
  Expected: `omp-plans check` exits `0` against this repo's `docs/plans/`, `omp-skill list` reports no enabled optional skills, and the audit reports on `~/src` without error.

- [ ] Confirm `omp-plans` validates the two documents this plan lives in.
  Run: `omp-plans index && git diff --stat docs/plans/INDEX.md`
  Expected: `INDEX.md` is unchanged, proving the hand-written index matches the generated form.

- [ ] Commit.
  Message: `feat(omp): build omp-plans, omp-skill, and omp-lsp-audit with nix`

### Task 9: Plannotator as an input

**Files:**

- Modify: `flake.nix`, `modules/home/omp/config.nix`

- [ ] Add `inputs.plannotator = { url = "github:glockyco/plannotator/omp-local"; flake = false; }`. `flake.lock` now pins the revision, replacing `manifests/plugins.yml` and its `currentCommit` field, which the old code parsed and never compared.

- [ ] Package `apps/pi-extension` as a derivation so the extension is built rather than assumed built. This is new work, not a port — the old setup only reconciled a checkout.
  Verification: `nix build --no-link .#plannotator-extension`
  Expected: builds and the output contains the extension entry point.

- [ ] Add the built extension path to the overlay's `extensions` list and its `skills` directory to `skills.customDirectories`.
  Verification: `sudo darwin-rebuild switch --flake . && omp -p --no-session 'List every skill name you can see, one per line, nothing else'`
  Expected: `plannotator-review` appears.

- [ ] Confirm no extension load errors were logged.
  Run: `grep -c 'Failed to load extension\|Extension error' ~/.omp/logs/omp.$(date -u +%Y-%m-%d).log`
  Expected: `0`.

- [ ] Clone the fork to `~/src/github.com/glockyco/plannotator` for development. Rebasing `omp-local` onto `upstream/main` is three git commands and needs no wrapper. Bumping the consumed version is `nix flake update plannotator`.

- [ ] Commit.
  Message: `feat(omp): consume plannotator as a pinned flake input`

### Task 10: Repository conventions

**Files:**

- Create: `AGENTS.md`

- Modify: `flake.nix`, `README.md`

- [ ] Write this repo's `AGENTS.md` linking `docs/plans/INDEX.md` and describing the three ownership zones. The planning-files convention requires a repo's agent context to link the index so a fresh agent reaches the tree without searching.

- [ ] Extend `checks` with a `payloadRegistry` assertion in the style of the existing `moduleImports` check: every directory under `agent/skills/` contains a `SKILL.md`, and every file under `agent/rules/` is referenced by `content.nix`.
  Verification: `nix flake check`
  Expected: passes. Temporarily creating an empty `agent/skills/probe/` makes it fail, which proves the check has teeth.

- [ ] Update `README.md` to record that omp agent configuration lives here, and note that `~/.omp/agent/config.yml` and `mcp.json` are omp-owned and must not be symlinked.

- [ ] Format everything.
  Run: `git ls-files -z '*.nix' | xargs -0 nix fmt --`
  Expected: no diff on a second run.

- [ ] Commit.
  Message: `docs: document omp ownership zones and payload checks`

### Task 11: Retire the old repository

**Files:**

- None in this repo.

- [ ] Confirm the full acceptance list in the spec passes end to end, in particular that `/opt/homebrew/Cellar` is empty, `command -v bun` prints nothing, and no path under `~/.omp/agent/` is written by both Nix and omp.
  Run: `ls /opt/homebrew/Cellar | wc -l; command -v bun; find ~/.omp/agent -maxdepth 1 -type l -exec readlink {} \;`
  Expected: `0`, no bun, and every symlink resolves either into `~/.config/nix-darwin/agent` or into `/nix/store`.

- [ ] Copy the 18 documents in the old repo's `docs/plans/` into this repo's `docs/plans/archive/`, preserving their front matter, then regenerate the index.
  Run: `omp-plans index && omp-plans check`
  Expected: both exit `0` and the archive footer reports the copied count.

- [ ] Archive `glockyco/omp-agent-setup` on GitHub as read-only. Its git history and CI record stay available, and nothing depends on it any more.

- [ ] Commit.
  Message: `chore: migrate planning archive from omp-agent-setup`
