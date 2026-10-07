# Design

## Context

See proposal.md for motivation. This is fleet change 1, archived after `publish-plugin-through-omp-plugin-manager` and before the Home Manager/chezmoi cutover. It intentionally leaves Home Manager in place until change 2.

Verified repository evidence:

- `packages/personal-omp/package.nix:11-19,133-147` supplies seven language servers plus Plannotator, rejects `omp update`, and injects `--extension` and scoped `--plugin-dir` flags. Its remaining files implement shape, generation, verification, and Herdr reconciliation fixtures; the entire directory becomes obsolete.
- `packages/omp-dev-update/package.nix:16-37` owns patch base/tip and a Herdr executable; its Python updater/tests own addon preparation, candidate environments/cache, source selection, idle-session restarts, and generation retention. Delete the entire directory, not just its launcher.
- `modules/home/omp.nix` installs wrapper/updater/verifier/OpenSpec and reconciles Herdr. `modules/home/packages.nix` separately installs Herdr and uv; `modules/home/default.nix` imports OMP.
- `flake-modules/checks.nix:58-74,157-160,245-249,282-292` connects wrapper assertions, the browser check, `lib.openspecCheck`, and obsolete behavior tests. `checks/omp-browser-runtime-check.nix` checks real system libraries but also takes the wrapper closure solely to reject packaged Chromium. Preserve the useful ABI check and remove its deleted-wrapper dependency.
- `flake-modules/packages.nix:19-22` re-exports Herdr, OpenSpec, runtime personal plugin, and Plannotator. `flake.nix:69-82` has three separately meaningful inputs: ordinary llm-agents, pinned Plannotator vendor, and personal plugin/check tools.
- `hosts/macbook-pro/host.nix:32-48` declares Ghostty's Homebrew cask and Dock pin alongside manually installed `/Applications/Tern.app`; `modules/home/darwin/tern.nix` puts its bundle CLI on PATH because a missing CLI otherwise creates a Homebrew link. Ghostty's config and theme are in `modules/home/darwin/{ghostty,catppuccin}.nix`.
- `modules/shared/zed-settings.nix` declares `agent_servers.omp`; both `modules/home/darwin/zed.nix` and `packages/windows-configuration/files.nix:75-92` consume its command parameters. The owner does not use this integration: remove it from both consumers and remove the now-unused helper parameters, retaining all unrelated Zed values. No requirement in `windows-workstation-layer` mandates the agent-server setting (`Application configuration files` only requires themes, nixd, Fork, AltSnap and keyboard behavior); no Windows spec delta is needed.
- `modules/home/darwin/brave.nix` still supports an upstream OMP browser relay and ordinary external extensions. Upstream OMP retains browser capability: do not infer that wrapper removal makes Brave or its Bitwarden/Violentmonkey manifests obsolete. WSL browser/relay/interop/font removal is change 4, not this change.
- README's Develop/Activate/Update/Recover and `docs/operations/{dependency-updates,wsl-omp-bootstrap}.md` currently describe source generations, verifier, Herdr, and Windows Terminal. `.agents/skills/omp-update/` routes through that retired procedure. `docs/architecture/` is absent. Existing indexed historical plans and archived evidence are preserved; current-state claims/links and current specs are cleaned.
- `restart-sessions-and-prune-omp-generations` has 8/9 tasks complete, with its Mac prune gate still unchecked. It is superseded, not falsely completed or archived; delete its unarchived directory in this change.
- Read-only `sudo -n -l` on the current Korolev WSL host reported `(ALL : ALL) SETENV: NOPASSWD: ALL` for user `user` on 2026-10-07. Linux activation currently needs no password; recheck at execution time. README documents Mac activation through `ssh -t macbook-pro` with the owner typing the Mac sudo password in the terminal.

External evidence verified by reading the official scripts on 2026-10-07:

- [Unix installer](https://omp.sh/install), redirecting to [scripts/install.sh](https://github.com/can1357/oh-my-pi/blob/main/scripts/install.sh), accepts `--binary`, `--ref <release-tag>`, and `PI_INSTALL_DIR`, defaulting to `~/.local/bin`. Without `--binary` it can choose Bun if installed. It invokes the downloaded binary's version as an installation smoke; this is not plugin/session acceptance.
- [Windows installer](https://omp.sh/install.ps1), redirecting to [scripts/install.ps1](https://github.com/can1357/oh-my-pi/blob/main/scripts/install.ps1), accepts `-Binary` and `-Ref`, defaults to `%LOCALAPPDATA%\omp`, and configures a Bash path opportunistically. It can find WSL's `bash.exe`; native Windows procedures must inspect the resulting shell ownership and select PowerShell or real Git Bash, not silently accept WSL.
- [Marketplace documentation](https://github.com/can1357/oh-my-pi/blob/main/docs/marketplace.md) documents user-scope installs, extension loading, plugin versioned caches/registries, upgrade semantics, and restart requirements.
- Change 0's isolated OMP 18.6.1 spike, reported by its author, verified marketplace discovery of both extension modules, nine skills, always-applied personal policy, all LSP overrides including disabled Marksman, and all six OpenSpec commands. Commands are visibly namespaced `/personal:opsx-*`. Change 0 also establishes LSP selection filters for root markers, executable availability, and `disabled`, so missing Roslyn is not selected on WSL. This is dependency evidence, not live fleet acceptance.

## Goals / Non-Goals

**Goals:** Keep every personal capability observable in upstream OMP; make update owners unambiguous; remove every task-obsolete implementation and current contract; prove replacement before removing the running environment.

**Non-Goals:** Home Manager removal, Windows-native Korolev provisioning/network changes, WSL secondary-role reduction, browser retirement, project SDK migration, new verifier/updater, scheduler, wrapper aliases, source patches, or controlling unrelated sessions. Native Windows Plannotator invocation is change 3's separately gated problem: change 0's module discovery does not prove its POSIX process-group lifecycle on Windows. This change's annotation gates use Mac and Linux/WSL only.

## Decisions

### 1. Official standalone binary, not a Nix or Bun launcher

Install explicitly with:

```sh
curl -fsSL https://omp.sh/install | sh -s -- --binary
```

Both hosts use the official default `~/.local/bin/omp`; add that directory to the normal user PATH rather than creating a wrapper. Check the actual ELF dynamic loader on WSL: the existing nix-ld/browser ABI declaration is retained, but successful browser loading does not prove OMP itself starts. If the binary requires additional runtime libraries, add only the observed required libraries to the declarative host loader and verify actual startup. Do not use source mode, `patchelf` an application-owned binary, or introduce an executable fallback.

Use `omp update` normally. For explicit recovery, use the same official installer in binary mode with `--ref <recorded-accepted-release-tag>`; on the manual desktop use `& ([scriptblock]::Create((irm https://omp.sh/install.ps1))) -Binary` and `-Ref <tag>` when restoring an accepted release. Re-read the live installer before executing it; flags are verified today, not assumed permanent. Record observed releases and available GitHub asset digest evidence; the installer itself does not establish the full release acceptance or promise transactional rollback.

Alternative: keep the wrapper but route updates upstream. Rejected because it retains duplicated ownership, argument injection and obsolete code. Alternative: Bun-global OMP. Rejected by the owner-approved standalone preference and the desktop's prior rejected shim.

### 2. Runtime plugin manager versus build-time OpenSpec tooling

The mandatory change 0 commands are:

```sh
omp plugin marketplace add glockyco/omp-agent-setup
omp plugin install --scope user personal@glockyco

omp plugin marketplace update glockyco
omp plugin upgrade --scope user personal@glockyco
```

Restart OMP after install/upgrade to load extension modules. During pre-cutover proof run these commands through the official binary's absolute path, never the installed Nix wrapper. Retain no explicit extension/plugin-dir launch flags, source checkout, link installation, or bare-command aliases. Update current instructions/spec references to `/personal:opsx-apply`, `/personal:opsx-archive`, `/personal:opsx-explore`, `/personal:opsx-propose`, `/personal:opsx-sync`, and `/personal:opsx-update`. Generated filenames can remain `opsx-*.md`; command names seen by the user cannot.

Keep `inputs.personal-omp-plugin` only because `flake-modules/checks.nix` consumes its `lib.openspecCheck` and the owning repository supplies generated-adapter tooling. Remove the overlay runtime package export and every host/runtime reference. Retain required follows/transitive lock nodes only while those build-time consumers use them; remove nodes only if unreachable. Distinguish this check-tool pin from the independently installed plugin release in AGENTS.md/README. Do not remove `llm-agents` (OpenSpec) or `plannotator-packages` (vendor package), and do not add a nixpkgs follow to the vendor input.

Alternative: remove the entire plugin input. Rejected while the shared OpenSpec contract library remains required. Alternative: package/git mode. Change 0's spike rejected it because it did not load the LSP overrides and local link installs are not an upgrade channel.

### 3. Ordinary packages with an explicit host matrix

Change 1's package additions belong to `modules/home/packages.nix`, using the shared package set and existing typed host data. Existing unrelated package/program modules are not duplicated. Required end-state package membership:

| Both hosts                                                                                                                                                                                        | Mac only                      | Removed from both                                                                               |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------- | ----------------------------------------------------------------------------------------------- |
| `pkgs.uv`, `pkgs.herdr`, `pkgs.openspec`, `pkgs.plannotator`, `pkgs.markdown-oxide`, `pkgs.nixd`, `pkgs.pyright`, `pkgs.svelte-language-server`, `pkgs.texlab`, `pkgs.typescript-language-server` | `pkgs.roslyn-language-server` | `pkgs.personal-omp`, updater/verifier/reconciler, Herdr reconciliation, runtime personal plugin |

Texlab already appears in `modules/home/tex.nix`; preserve a single intentional effective package selection, not a second tool convention. WSL currently also puts nixd in its system package set for Windows Zed's WSL process. Keep that consumer until change 3 changes the Windows transport; this change ensures ordinary user package availability too. Reuse the fixed-output Markdown Oxide/Roslyn packages and their behavior checks; keep Darwin's source-free guard. The plugin's missing-executable filter makes Roslyn absent on WSL rather than adding a fallback. C# project SDKs stay with Mac project environments.

Change 2 moves every Home Manager package, including this matrix, to `users.users.<name>.packages`, migrates PATH/configuration to chezmoi, and preserves the same check/package derivation assertions. This change does not remove Home Manager, sops-nix, Catppuccin's remaining Zed/CLI theming, or their inputs.

### 4. Tern becomes the primary terminal; Ghostty and Herdr stay secondary

Tern is the primary terminal for interactive OMP sessions. Keep Tern's record, CLI path and Dock pin; verify the signed-in manually delivered bundle exists before switching. Tern owns its writable settings and self-updates; this change adds no settings manager or alternative installer.

Ghostty and Herdr remain useful secondary tools, so the owner keeps them: the Mac retains Ghostty's Homebrew cask, application record, Dock pin, configuration and Catppuccin theme, and both hosts keep the Herdr package. What goes is the wrapper-era coupling: activation no longer creates, reconciles or restarts through Herdr's OMP integration, and the updater's Herdr hooks/tests go with the updater. The owner installs that integration on demand with Herdr's supported `herdr integration install omp`; it is user state, not a migration artifact to delete. Remove both Zed OMP setting consumers and now-unused helper arguments; convergent Zed writes can preserve removed keys, so live cleanup must remove only the previously declared `agent_servers.omp` value from writable Mac and Windows settings before asserting absence.

Alternatives: remove Ghostty and Herdr in this cutover (rejected by the owner, who still uses both), or keep activation-managed Herdr reconciliation (rejected: it couples Nix activation to OMP's mutable extension directory). Existing processes are manually finished/resumed; no replacement restart automation is introduced.

### 5. Preserve useful gates, remove wrapper evidence

Replace the per-host `personal-omp` check with ordinary package-derivation membership checks, OpenSpec executable-version consistency, Plannotator vendor identity and host matrix assertions. Keep generic login-shell/Homebrew PATH ordering assertions. Remove personalOmpTests and `personalOmpShape`, `personalOmpGeneration`, `personalOmpVerification`, `herdrOmpReconciliation`, `personalOmpUpdate`, and their now-unreachable dependencies. Adapt the browser check to the actual declared system/browser-support closure, preserving all ABI names and no Nix Chromium assertion until change 4 removes it.

The retained OpenSpec library checks active contracts and archived completion; it does not alone prove adapter freshness or installed CLI version. Preserve/add explicit gates for those contracts using the owning plugin repository's independent adapter check and the shared installed OpenSpec derivation, not a runtime plugin path. Retained SSH, network, DNS, secrets, container, WSL font/interop, host, and helper package behavior checks are unchanged unless a deleted runtime argument forces a targeted interface change.

### 6. Requirement ownership and archive order

Deltas touch only the assigned requirements, plus the integrator-authorized minimal changes to `Shared user-scope module set`, `Declarative WSL host configuration`, and `Program checks exercise the program`. The first two remove only retired clauses and retain unrelated text/scenarios for change 2. The generic program requirement is explicitly REMOVED and its unchanged generic behavior is ADDED as `Packaged program behavior checks`, dropping obsolete wrapper-only scenarios. Strict validation forbids silent scenario loss or renamed headings in MODIFIED blocks, so requirements with misleading retired-platform headings are explicitly removed/replaced instead. `Managed browser compatibility on WSL` keeps its name and all four headings; only the update scenario's WHEN changes to official `omp update`, as directed by the integrator, so change 4 can remove that requirement by its original name. No `windows-workstation-layer` delta is needed for unused agent-server removal. Current spec purposes that describe a wrapper/source runtime must be updated during implementation/sync as owned contract cleanup, without rewriting archived historical evidence.

## Risks / Trade-offs

- [This conversation and its workers run the existing wrapped OMP in WSL, displayed through Tern for Windows] → Install upstream/plugin and complete independent pre-cutover sessions first; preserve all running source paths and previous Nix generation. Never terminate the invoking session or prune its runtime. Open a proven official session before handing off deletion/activation.
- [PATH continues selecting a wrapper or old Bun shim] → Use absolute official path before cutover; inspect all resolutions after activation in a new login shell; remove only identified task-owned launchers/links. No permanent alias or routing fallback.
- [NixOS foreign-binary requirements differ from current browser ABI] → Verify official binary loading on the real host; add only evidenced loader libraries if necessary and repeat startup. A binary download is not acceptance.
- [Plugin-manager namespaces and independent releases change workflow discovery] → Gate all six namespaced commands, nine skills, both extension modules, policy, and LSP overrides; pinning check tools does not upgrade the plugin.
- [Upstream installers/update commands do not provide source-generation atomic promotion/rollback guarantees] → Stop promising the old behavior; record the accepted release and retain migration recovery paths; use explicit official release reinstall and repeat smoke. Never delete credentials or claim a nonexistent rollback.
- [Removed convergent settings remain on disk] → Target only the known owned `agent_servers.omp` keys after replacement proof, recording before/after identity without printing credentials. Preserve application UI state and user extensions, including an owner-installed Herdr integration.
- [Mac sudo, Stencil access, provider login or publication unavailable] → Complete safe work, then report the exact owner-assisted gate; no credential bypass, automatic merge, or inferred push authorization.
- [Windows Terminal policy still exists before change 3] → Use existing Tern for Windows manually to launch WSL now; remove Windows Terminal/renderer ownership only in change 3. Do not claim this change finishes native Korolev.

## Migration Plan

1. Verify change 0 is released and its marketplace command/capability proof is available; record installed versions, state paths, old Nix/source generations, current processes, and available terminal/admin access on both hosts.
1. While keeping the wrapper and current sessions intact, install official binaries on both hosts with the verified installer flags, install the released plugin through the absolute binary, and prove personal behavior in separate Tern sessions. Verify ordinary tool executables through the existing environment as pre-cutover availability evidence; repeat after package relocation. Complete local provider login only if required, with the owner in the native browser/terminal.
1. Hand off to a proven official session; finish or explicitly resume old sessions without losing drafts. Implement the Nix/package/terminal/editor/docs/spec clean cutover; retain old Nix/source generations, no new wrapper aliases.
1. Run ordered README gates on both hosts, validate this change, review and commit only task-owned work. Pushes and merges require explicit owner authorization; a reviewed committed local revision can be activated without an unnecessary push. Activate WSL from the committed checkout and the Mac over `ssh -t macbook-pro` in a terminal, owner typing the Mac password.
1. Prove the default official command, exact plugin-manager capabilities, all applicable LSPs, Plannotator lifecycle, clickable links and WSL browser in real Tern sessions after activation. Exercise authorized Nix package rollback/reapply while confirming independent OMP/plugin state stays unchanged. Update executable/plugin with their official commands and repeat required smoke; an already-current result is valid but recorded honestly.
1. Update the unmanaged desktop's manual procedure and, with explicit owner authorization, migrate its plugin manager and exercise native `omp update`/commit-preview/workflow smoke. Do not change desktop services/networking or install hidden WSL dependencies.
1. Only after both hosts and desktop's applicable gate pass, retire old source/cache directories that no process uses and task-owned obsolete runtime links. Keep previous Nix generations until acceptance completes. Sync owned spec deltas and owned Purpose text, validate, complete tasks with evidence, and archive in fleet order.

Recovery before replacement proof: leave the wrapper installed and do not start deletion. Recovery after Nix cutover failure: select the retained prior Nix generation; it may restore old wrapper paths but does not downgrade the official binary/plugin. Keep retained source generations available for that explicit migration recovery only, not as an automatic production fallback. Recovery of a rejected official executable: authorized binary reinstall of the recorded accepted tag and repeated fresh-session proof. Plugin downgrade/recovery must follow change 0's supported manager procedure; do not fabricate a version-selector or rewrite its registry/cache by hand.
