# Korolev native Windows operations

## Scope and current state

Windows is the target primary workstation; NixOS-WSL remains a secondary CLI/build environment. Use a native checkout at `C:\Users\JGlock\src\github.com\glockyco\nix-config`, not the separate Linux checkout at `/home/user/src/github.com/glockyco/nix-config`. Windows is not a Nix flake system. This procedure requires no Nix-built Windows output.

WinGet Configuration owns packages and Windows settings; chezmoi owns Windows user files and user setup from `home/`. Each destination has one owner. Source/fixture checks do not claim native provisioning, application/session or network acceptance. Implementation evidence belongs to the OpenSpec change, not this current-state manual.

Existing live state supplied by the owner on 2026-10-07: per-user Git 2.55.0.5 is at `%LOCALAPPDATA%\Programs\Git` on user PATH; Tern 0.6.0 is at `%LOCALAPPDATA%\Programs\Tern` on user PATH with a Start-menu shortcut; official OMP 18.8.0 is at `%LOCALAPPDATA%\omp\omp.exe` on user PATH with personal plugin 0.2.0, per-user Git Bash selected and owner login complete. Zed's `agent_servers.omp` entry is removed. Do not redo those installations. These facts do not claim native LSP/annotation/network acceptance. The remaining catalog/release selections were verified read-only; further provisioning, UAC, restart and application acceptance are owner-attended.

## Source and privilege owners

| Source or state                               | Owner and boundary                                                                                                                                                                                                            |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `windows/configuration.winget`                | Hand-maintained JSON-compatible YAML (actual JSON). WinGet Configuration owns declared installs and Windows settings, never migrated user files. Application metadata beside each resource is the selector/version authority. |
| `windows/managed-applications.json`           | Dated Intune exclusion audit, not another application/pin list.                                                                                                                                                               |
| `windows/apply-kbdneo.ps1`                    | Explicit 64-bit Administrator operation: checksum-pinned native Neo DLLs and keyboard registration `b0000407` only.                                                                                                           |
| `windows/apply-zen-policies.ps1`              | Explicit Administrator operation: Zen policy file under Program Files only.                                                                                                                                                   |
| `windows/check.ps1` and fixtures              | Native validation/parser/ownership checks; never live apply.                                                                                                                                                                  |
| `home/` and shared TOML                       | Chezmoi owns portable Git/gh/SSH and Windows app declarations, pinned assets and user setup; undeclared app state remains app-owned.                                                                                          |
| OMP/plugin/Tern/Plannotator                   | Explicit upstream user installations described below, not Nix activation or automatic configuration apply.                                                                                                                    |
| Profiles, credentials, sessions, repositories | Application/user owned. Never copy authentication databases, private keys, browser profiles or another platform's OMP state.                                                                                                  |

Run the document, user setup and chezmoi as standard `jglock` (`scch\jglock`), never as Administrator and never against the Administrator HOME/HKCU. Only Zen and Tailscale are machine-scope package exceptions; the owner supplies the separate Administrator credential for their approved installer prompts. Intune-owned runtime dependencies are prerequisites to inspect, not additional installers. OpenSSH capability/service/firewall setup is a separately approved manual operation, not a third general-purpose Administrator script or a document resource. Do not bypass employer restrictions.

Git alone is removed from the managed exclusion set: the audited Patch My PC “Update für Git 2.51.0.2” detection and requirements in `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppWorkload.log` target HKLM, while the observed Git install is HKCU/per-user. That update package does not own this installation. Docker Desktop and every other audited excluded ID remain excluded; this does not modify Intune policy. Re-audit if central ownership changes.

## Native checks before any live writes

From the reviewed native repository root, as the standard user:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\windows\check.ps1
pwsh -NoProfile -NonInteractive -File .\windows\check.ps1
winget configure show --file .\windows\configuration.winget
```

Windows PowerShell 5.1 covers scripts executed by that host; PowerShell 7 covers native tooling. The default check validates the vendored official DSC schema and discovered resource-type allowlist, runs isolated positive/negative fixtures and parses document scripts, both Administrator scripts and native scripts. Findings name the resource/script and return nonzero. Read-only WinGet show must exit zero; missing dependencies fail rather than skip. `winget configure validate` is not the gate: WinGet 1.29.380 returns 1 for valid native DSC resources because its public-module warnings count as findings, including on the untouched baseline. [Implementation evidence](../../openspec/changes/make-korolev-windows-native/evidence.md) records the upstream reason and actual discovery versions. Never suppress the warning or call exit 1 a pass. These checks install no workstation resource and require no login; Linux PowerShell 7 evidence is not Windows PowerShell 5.1/WinGet evidence.

The default checker also renders Windows chezmoi scripts, AST-parses their actual PowerShell output, and runs isolated init/apply/verify, Git/SSH and app-state fixtures with process/WinGet doubles. It requires chezmoi 2.73.0, Git and OpenSSH on PATH; it never applies workstation resources to the real profile. `-DocumentPath` selects a document and `-AdditionalScriptPath` accepts a PowerShell `string[]` of additional rendered scripts. `-SkipFixtures` permits focused parser/invariant inspection only, not acceptance. Complete repository release gates remain in [README](../../README.md#develop), run sequentially.

The Windows PowerShell invocation uses a process-only execution-policy setting for the reviewed repository fixtures; it changes no persistent policy and cannot override managed policy. Do not modify employer policy to make a check pass. If managed execution restrictions still reject the scripts, record that prerequisite rather than bypassing it.

## Tool ownership, update and recovery matrix

For all **exact** rows, installation targets the reviewed version; drift is reported, not permission to downgrade an already newer installation. Stop and review the installed executable/registration, dependencies and source revision before repair. Select an approved updated declaration or an explicit reviewed reinstall/removal using the tool's supported mechanism and local backup. Never quietly reinstall an older pin. For all **self-updating** rows, WinGet installs/repairs with latest available and no version selector; an installed version newer than catalog is desired and must not be downgraded. There is no additional updater/scheduler.

“Exact repair” below means that explicit review-and-backup procedure, not automatic downgrade. Document URLs/digests and npm integrity records are authoritative; metadata selection is not successful native execution evidence.

| Tool / role                                   | Installer owner, scope and selected policy                                                 | Update path                                            | Recovery path                                                                                                                     |
| --------------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| Git/GCM (`Git.Git`)                           | WinGet, user, self-updating; observed 2.55.0.5, not a pin                                  | Vendor/user update; inspect GCM after every Git update | Retain accepted installer and configuration; explicitly repair Git and recheck native GCM/Fork, never downgrade catalog-newer Git |
| Zed (`ZedIndustries.Zed`)                     | WinGet, user, self-updating                                                                | Vendor channel                                         | Supported vendor repair/accepted build; preserve UI state; no WSL transport or OMP agent server                                   |
| Zen (`Zen-Team.Zen-Browser`)                  | WinGet, machine exception, self-updating                                                   | Vendor channel; re-test narrow policies                | Approved installer repair plus explicit policy script; preserve profile/history and newer version                                 |
| Brave (`Brave.Brave`)                         | WinGet, user, self-updating, browser relay only                                            | Vendor channel                                         | Supported repair; relay profile/extension remain app-owned; no startup entry                                                      |
| Ferdium (`Ferdium.Ferdium`)                   | WinGet, user, self-updating                                                                | App/vendor updater                                     | Supported repair preserving services, credentials, sessions/cache and startup/update preferences                                  |
| Tern                                          | Manual signed-in Stencil build, user, self-updating                                        | Stencil/Tern vendor flow                               | Retain previous accepted build outside Temp; preserve `%LOCALAPPDATA%\Tern`                                                       |
| Fork (`Fork.Fork`)                            | WinGet, user, exact 2.21.0                                                                 | Reviewed document pin change                           | Exact repair, preserving unrelated app settings; target native Git only after file-owner cutover                                  |
| PowerToys (`Microsoft.PowerToys`)             | WinGet, user, exact 0.101.2362.0                                                           | Reviewed pin and installed module-key audit            | Exact repair and owned-key backup; preserve UI state, one startup owner, no AltSnap overlap                                       |
| AltSnap (`AltSnap.AltSnap`)                   | Reviewed checksum-verified official release, user, exact 1.68                              | Reviewed archive/executable/hooks pins                 | Exact repair with owned INI backup; preserve 50/50 snapping                                                                       |
| ReNeo (`Rojetto.ReNeo.neo2`)                  | WinGet, user, exact 1.6.0                                                                  | Reviewed pin/config update                             | Exact repair and launcher/config backup; complete separate runtime RunAs prompt at logon                                          |
| JetBrainsMono Nerd Font                       | Checksum-verified user font payload, exact 3.3.0                                           | Reviewed font/archive checksums                        | Exact repair of declared fonts/registry names only; restart terminal for font test                                                |
| chezmoi (`twpayne.chezmoi`)                   | WinGet, user, exact 2.73.0                                                                 | Reviewed document pin                                  | Exact repair; local config/state backups are separate from user destinations                                                      |
| Tailscale (`Tailscale.Tailscale`)             | WinGet, approved machine exception, exact 1.102.4                                          | Reviewed pin and network acceptance                    | Approved installer/service recovery; enrollment rollback is separate, no device-state import                                      |
| PowerShell                                    | Official checksum-verified user ZIP, exact 7.6.6 at `%LOCALAPPDATA%\Programs\PowerShell\7` | Reviewed URL/hash/version                              | Retain accepted ZIP/binary; exact repair, verify absolute executable and any SSH DefaultShell use                                 |
| GitHub CLI                                    | Official checksum-verified user ZIP, exact 2.102.0                                         | Reviewed URL/hash/version                              | Exact repair; keep Windows-local gh authentication, never manage `hosts.yml`                                                      |
| Node (`OpenJS.NodeJS.LTS`)                    | WinGet portable ZIP selected with `--scope user`, exact 24.19.0                            | Reviewed document pin                                  | Exact repair; verify node/npm and dependent native wrappers before use                                                            |
| Bun (`Oven-sh.Bun`)                           | WinGet, user, exact 1.4.2                                                                  | Reviewed document pin                                  | Exact repair; never use a Bun-global OMP shim                                                                                     |
| Python (`Python.Python.3.13`)                 | WinGet, user, exact 3.13.15                                                                | Reviewed document pin                                  | Exact repair; inspect native executable versus Store aliases and preserve research environments                                   |
| uv (`astral-sh.uv`)                           | WinGet, user, exact 0.12.23                                                                | Reviewed document pin                                  | Exact repair; preserve user/project environment data                                                                              |
| ghq (`x-motemen.ghq`)                         | WinGet, user, exact 1.10.1                                                                 | Reviewed document pin                                  | Exact repair; keep native `~/src` repositories, never substitute Linux clone root                                                 |
| ripgrep (`BurntSushi.ripgrep.MSVC`)           | WinGet, user, exact 15.2.0                                                                 | Reviewed document pin                                  | Exact repair; verify native `rg` resolution                                                                                       |
| fd (`sharkdp.fd`)                             | WinGet, user, exact 10.5.0                                                                 | Reviewed document pin                                  | Exact repair; verify native `fd` resolution                                                                                       |
| fzf (`junegunn.fzf`)                          | WinGet, user, exact 0.74.4                                                                 | Reviewed document pin                                  | Exact repair; verify native picker                                                                                                |
| delta (`dandavison.delta`)                    | WinGet, user, exact 0.20.1                                                                 | Reviewed document pin                                  | Exact repair; verify Git pager without changing repository policy                                                                 |
| lefthook (`evilmartians.lefthook`)            | WinGet, user, exact 2.1.17                                                                 | Reviewed document pin                                  | Exact repair; later native development bootstrap owns hook installation; never bypass a failing hook                              |
| markdown-oxide (`FelixZeller.markdown-oxide`) | WinGet, user, exact 0.25.12                                                                | Reviewed pin and representative Markdown smoke         | Exact repair; verify native initialization/navigation, not version alone                                                          |
| Typst (`Typst.Typst`)                         | WinGet, user, exact 0.15.1                                                                 | Reviewed pin and document build                        | Exact repair; preserve project fonts/packages/build inputs                                                                        |
| tinymist (`Myriad-Dreamin.Tinymist`)          | WinGet, user, exact 0.15.8                                                                 | Reviewed pin and LSP smoke                             | Exact repair; verify native diagnostics/navigation                                                                                |
| pyright                                       | npm user prefix, exact 1.1.411                                                             | Reviewed version/integrity/lock change                 | Exact repair of locked packages; verify native `pyright.cmd`/language server                                                      |
| TypeScript                                    | npm user prefix, exact 5.9.3                                                               | Reviewed version/integrity/lock change                 | Exact repair; preserve project SDK/tsconfig ownership                                                                             |
| typescript-language-server                    | npm user prefix, exact 5.3.0                                                               | Reviewed version/integrity/lock change                 | Exact repair; TS 5.9.3 compatibility requires native project smoke, not a claimed peer constraint                                 |
| svelte-language-server                        | npm user prefix, exact 0.17.31                                                             | Reviewed version/integrity/lock change                 | Exact repair; verify native `svelteserver.cmd` in representative project                                                          |
| OpenSpec (`@fission-ai/openspec`)             | npm user prefix, exact 1.14.0                                                              | Reviewed version/integrity/lock change                 | Exact repair; adapters remain personal-plugin-owned, never run `openspec init` here                                               |
| OMP                                           | Official standalone binary user installer; reviewed release below                          | `omp update`                                           | Reinstall accepted reviewed release through official `-Binary -Ref`; preserve auth/session state                                  |
| Personal plugin                               | OMP user plugin manager                                                                    | Marketplace update then plugin upgrade, below          | Supported corrective plugin release; retained source/version record, never rewrite cache                                          |
| Plannotator                                   | Official minimal user installer, exact v0.28.7 with attestation verification               | Explicit reviewed vendor release selection             | Reinstall accepted release via same verified minimal flow; no vendor skills/hooks or WSL hosting                                  |

npm packages live under `%LOCALAPPDATA%\Programs\npm`; their native `.cmd` wrappers are under `node_modules\.bin`, which the resource adds to user PATH after Node. Installation uses the reviewed complete integrity lock with `npm ci`, not only direct-package hashes. Node's real ZIP directory provides its adjacent `npm.cmd`. WinGet CLI resources enforce `--scope user` in the installer command and skip automatic runtime dependency installs; missing user installers never fall back to machine scope. Official PowerShell/GitHub ZIPs check hashes before extraction and native versions afterwards, retaining prior directories for recovery. Check the Intune-owned VC++ runtime where required (uv, fd, delta and Typst); do not install competing runtimes. Native failures become terminating errors containing the original exit code because the DSC script host must not swallow an isolated `exit`.

Svelte's `svelteserver.cmd` has no `--version` mode. Its convergence check verifies the locked installed `svelte-language-server/package.json` version and native wrapper presence, not an unsupported version command that opens IPC. Representative LSP initialization remains a separate live project gate.

For Nerd Font faces, a differing installed TTF does not reliably reveal Nerd Font release ordering. The installer therefore refuses to overwrite different existing content automatically. Back up and identify that installed release, then perform explicit reviewed recovery of only the declared faces; never remove unrelated user fonts.

## Preview, Neo prerequisite, apply and Zen policies

Before writes, retain permission-preserving local backups outside the checkout of affected user settings, PATH/environment, Fork Git references, chezmoi config/state and narrowly owned machine files/registry entries. Record absent paths and versions. Keep previous accepted Nix generations for Linux recovery. Do not export credentials or whole runtime profiles into the repository.

### Bootstrap the standard-user native checkout

In a fresh standard-user PowerShell session, install only the bootstrap prerequisites from the approved source, then clone Windows-local storage. Do not reuse the Linux checkout through UNC or `/mnt/c` for user setup:

```powershell
winget install --id Git.Git --exact --source winget --scope user --accept-source-agreements --accept-package-agreements
winget install --id twpayne.chezmoi --exact --source winget --scope user --version 2.73.0 --accept-source-agreements --accept-package-agreements
```

Open a fresh standard-user shell so PATH reflects those installs, then:

```powershell
$checkout = Join-Path $HOME 'src\github.com\glockyco\nix-config'
git clone https://github.com/glockyco/nix-config.git $checkout
Set-Location $checkout
chezmoi init --source $checkout
chezmoi source-path
chezmoi data
chezmoi diff
```

Select `korolev` at init. Confirm persisted `sourceDir` is this native checkout (not its `home` child), `data.host=korolev`, Windows profile facts and ghq root `~/src`. The repository's `.chezmoiroot` selects `home/`. Init and diff do not authorize apply; review source revision, backups and Neo prerequisite first. On an existing checkout, inspect it instead of cloning over it. Never print decrypted credential previews.

In standard PowerShell, from the native checkout:

```powershell
$checkout = (Get-Location).Path
$configuration = Join-Path $checkout 'windows\configuration.winget'
$kbdNeo = Join-Path $checkout 'windows\apply-kbdneo.ps1'
$zenPolicies = Join-Path $checkout 'windows\apply-zen-policies.ps1'
winget configure --enable
winget configure test --file $configuration --accept-configuration-agreements --disable-interactivity --suppress-initial-details
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $kbdNeo -Test
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $zenPolicies -Test
```

Inspect each result: drift is not an acceptable execution/resource error. Require installer elevation only for Zen/Tailscale, never user-profile settings. Dark-appearance acceptance allows Windows' generated `Custom.theme` when declared dark modes/transparency/wallpaper match; it does not demand a fixed active theme path. Do not apply the document's Neo input tip before installing the native driver and restarting.

Open **64-bit Administrator PowerShell** with the separate credential. Set `$kbdNeo` to the absolute source script path (the Administrator session does not inherit standard-user variables), then:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $kbdNeo -Test
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $kbdNeo
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $kbdNeo -Test
```

Require `kbdneo: desired`. Coordinate a real Windows restart **before** registering input tip `0407:b0000407`. Return to standard `JGlock` PowerShell, reset the source paths and, after review/approval, apply:

```powershell
chezmoi diff
chezmoi apply
chezmoi verify
```

The Windows-only content-hashed `run_onchange_before_` checks the persisted checkout against Git's root and runs its document before user files. The owner supplies the separate Administrator credential only at approved Zen/Tailscale installer prompts. Never elevate the whole apply. Tailscale installation does not authorize enrollment; use the separately approved network cutover procedure before any Windows node login.

After Zen installation, open Administrator PowerShell, set `$zenPolicies` to the absolute source path, and run only:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $zenPolicies -Test
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $zenPolicies
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $zenPolicies -Test
```

Require `Zen policies: desired`. Sign out/in after first user apply for UI language/input defaults and ReNeo launcher; the owner completes ReNeo's RunAs prompt at each sign-in. If sign-out is delayed, run the installed launcher as the standard user:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$env:LOCALAPPDATA\WindowsConfiguration\start-reneo-elevated.ps1"
```

Keep German QWERTZ **first/default**, native Neo second. Office derives character shortcuts from the first loaded layout; making Neo first breaks that boundary. Elevated ReNeo supplies all layers in ordinary/elevated apps over QWERTZ, but secure-desktop UAC accepts QWERTZ only. Select `Deutsch (Neo)` using `Win+Space` before UAC for the native base layer there; higher layers remain unavailable on the secure desktop. After switching, change foreground windows once or reload ReNeo so it detects the layout. Verify Office copy/paste and declared character shortcuts in both layouts.

Repeat all three tests from the standard account. Require desired state; repeat apply/test in each original account context and require no changes. Inspect actual Windows dark modes, UI/input language, app themes, PowerToys module behavior, AltSnap snapping and undeclared UI/profile preservation. A schema/parser pass is not these live checks.

## Explicit Tern, OMP, plugin and annotation flows

Owner sign-in/download is required for Tern's closed-beta Stencil service. Install the accepted build at `%LOCALAPPDATA%\Programs\Tern\tern.exe`, not Temp; preserve `%LOCALAPPDATA%\Tern`. Add the stable directory exactly once to **user** PATH through reviewed user setup. No invented WinGet ID/download URL. Open actual Tern and prove native PowerShell, executable discovery, Unicode/glyphs, paste, resizing, interrupt and clickable links. Retain the prior accepted build and temporary spike until real session gates pass. Do not uninstall Windows-owned terminals or delete unrelated profiles merely because their declaration is retired.

Install OMP through its [official Windows installer](https://github.com/can1357/oh-my-pi/blob/main/scripts/install.ps1) with the reviewed release, then the exact personal-plugin commands:

```powershell
& ([scriptblock]::Create((Invoke-RestMethod https://omp.sh/install.ps1))) -Binary -Ref v18.8.0
omp plugin marketplace add glockyco/omp-agent-setup
omp plugin install --scope user personal@glockyco
& ([scriptblock]::Create((Invoke-RestMethod https://plannotator.ai/install.ps1))) -Minimal -Version v0.28.7 -VerifyAttestation
```

OMP defaults to `%LOCALAPPDATA%\omp`; verify actual executable/version and user PATH. The Plannotator release selection has published digest/attestation metadata, but that is not cryptographic verification of a downloaded EXE: require `-VerifyAttestation` to succeed, never suppress it. Minimal mode leaves skills/hooks to the personal plugin. Inspect OMP's actual selected shell after install: choose native PowerShell or the actual Git-for-Windows Bash executable, never System32 `bash.exe`/WSL. No wrapper, launcher flags, Bun-global OMP, imported auth DB or complete chezmoi-managed OMP config.

Restart OMP and verify both extension modules, all nine personal skills, personal policy, `/personal:opsx-*`, native LSP overrides and disabled Marksman. Owner performs Windows-local Anthropic/OpenAI, GitHub/GCM, browser/Overleaf logins where needed; prove a real response for each provider, `gh auth status`, HTTPS Git access and nonprompting GCM lookup afterwards without printing secrets. Do not copy WSL/Mac credentials.

In actual Tern, use a disposable native checkout with a space in its path: exercise native PowerShell/Git/research/OpenSpec and harmless `personal_commit` preview creating no commit. In the actual Windows browser invoke `/plannotator-annotate` on a disposable file and `/plannotator-last`, submit feedback and prove source unchanged. Cancel a pending review with `/plannotator-cancel`; inspect owned listener/process cleanup after cancel, navigation and shutdown. Closing a browser tab alone is not cancellation. A native lifecycle failure blocks acceptance and requires a separately approved plugin fix, not hidden WSL hosting or omitted commands. Saved OMP history is not process survival across reboot.

Updates are independent:

```powershell
omp update
omp plugin marketplace update glockyco
omp plugin upgrade --scope user personal@glockyco
omp --version
omp plugin list
```

Restart and repeat real Tern/annotation/cancel/LSP smokes. Retain accepted binaries and source/version records until these pass; recover OMP via the official binary installer and reviewed `-Ref`, plugin via supported corrective releases, not cache editing or Nix rollback. Plannotator updates remain explicit reviewed minimal installations with verification.

## Native projects and Mac LaTeX

Native Markdown/Python/TypeScript/Svelte and Typst use Windows tools directly. Test initialization, diagnostics/navigation and a representative Typst build, including `.cmd` resolution and paths with spaces. Node/Python availability does not give this repository ownership of project SDKs, virtual environments, root markers, compiler flags or builds. Open native repositories in Zed as local Windows projects. Chezmoi merges declared settings without discarding JSONC comments or unrelated UI state, enforces the Windows-first keymap and installs the pinned theme. There is no WSL transport, nixd or OMP agent server. Make keymap changes in source: the next apply replaces local keymap edits. Verify Ctrl+C/V/A/Z/F in Vim modes, Ctrl+K Ctrl+S, Ctrl+W, ordinary Vim editing and terminal Ctrl+C in the actual editor.

Fork's declared `GitInstancePath` points at `%LOCALAPPDATA%\Programs\Git`, preserving unrelated settings. Global Git uses the work email; `~/src/github.com/` selects the GitHub no-reply identity and repository-local email wins. Shared defaults include Git LFS, delta, `main`, pull/push policy, `autocrlf=input`, HTTPS and native GCM with Overleaf's generic provider. GCM's reviewed relative path is `mingw64/bin/git-credential-manager.exe` for Git 2.55; Git >=2.56 moves to `ucrt64/bin`. Review and update the shared fact after a Git upgrade rather than probing a fallback chain. Credentials, gh `hosts.yml` and private SSH keys are never managed. Confirm effective Git identity and native HTTPS/GCM operations in disposable worktrees before accepting Fork.

PowerToys declared module keys, ReNeo launcher/config and AltSnap INI values have chezmoi ownership; app-held files use stop/write/restart setup. Zen themes and its single `user.js` preference apply only to real profiles found through `profiles.ini`; create a profile in Zen first, never fabricate one. Cookies/history and unrelated preferences remain untouched. Keep local backups and close applications for recovery. Remove only change-owned old wslgit payload/environment references after live native Fork acceptance, not during fixture validation.

An absent Zen `profiles.ini` skips theme setup during fresh bootstrap; after creating a real profile, ordinary apply discovers it. A present malformed profile declaration or missing declared directory fails rather than writing guessed paths. Dynamic Zen setup rechecks on every apply; ordinary `chezmoi verify` covers regular declared destinations, not the dynamically discovered profile writes. Inspect Zen after apply as part of live acceptance.

LaTeX compilation and TexLab run on the **Mac's existing full TeX closure**. Keep a separate local Mac clone of the project; exchange committed work through Git, or transfer disposable inputs with approved SSH/SFTP while preserving originals. Use the Mac's approved `macbook-pro` interactive or `macbook-pro-batch` endpoint to run the **project's documented** build command in that clone. Run TexLab with the Mac editor/agent against that Mac worktree; retrieve/view the resulting PDF through the approved transfer workflow. Verify a representative actual Mac editor/TexLab/build session before declaring acceptance. Project root/build settings remain project-owned. Do not install native MiKTeX/TexLab, wire Windows Zed to WSL LaTeX, or add native nixd/Roslyn/C#/Unity servers. Retained WSL TeX and other CLI packages are secondary tools and are not removed by this source unit; use their own Linux Git/build workflow, not Fork/wslgit bridging.

## Manual preferences and nontransactional recovery

Use Windows Settings for default associations, taskbar pins and Night light (sunset-to-sunrise, 50% strength). Keep Austria as country/region. Do not edit undocumented CloudStore bytes, manufacture `UserChoice` hashes or claim these preferences converge through the document. Zen is the interactive browser; Brave is the approved OMP relay with no startup entry. Ferdium owns its profile/services/authentication/session/cache/startup/update preferences; a fresh profile's defaults are not managed state.

**DSC/Windows has no generation or transactional rollback.** A failure can leave earlier resources installed or settings changed. Stop; inspect resource errors, actual versions and partial state before repair. A Git revert does not restore files, uninstall packages or reverse policy/service/node operations. Nix rollback restores only Nix-owned Linux/Mac state.

Restore only backed-up, change-owned user files/PATH/Fork references and compatible reviewed source, preserving post-cutover UI edits, repositories, profiles, credentials and OMP history. Restore narrowly owned Neo DLL/registration or Zen policy backups from local Administrator recovery as appropriate; keyboard changes require a coordinated restart and input verification. Package repair is a separately reviewed supported installer operation, never an implicit downgrade. Repeat native checks, WinGet test, both narrow script tests and actual app/session acceptance. Keep backups/accepted binaries/generations until all applicable live gates pass.

If an interrupted app-held file apply leaves `%LOCALAPPDATA%\WindowsConfiguration\chezmoi-app-restarts.json`, preserve that transient restart journal. Review and explicitly rerun only the after-hook to restart recorded applications before inspecting partial file state:

```powershell
$repair = Join-Path $env:TEMP 'chezmoi-apps-restart.ps1'
chezmoi execute-template --file (Join-Path $checkout 'home\run_after_windows-apps-restart.ps1.tmpl') --output $repair
if ($LASTEXITCODE -ne 0) { throw 'Could not render selected app recovery script' }
powershell.exe -NoProfile -ExecutionPolicy Bypass -File $repair
if ($LASTEXITCODE -ne 0) { throw 'App recovery script failed; retain journal and inspect' }
Remove-Item -LiteralPath $repair
chezmoi diff
```

This selected hook also rechecks real Zen profiles; review it before running. It never runs the Administrator scripts or package document. Then repair/reapply owned files and verify; do not discard the journal or force unrelated setup to conceal interrupted state.

Ordinary-user maintenance is `chezmoi diff`, `chezmoi apply`, `chezmoi verify` from the persisted native checkout. An unchanged document hash does not rerun WinGet; the script ledger is neither a live-drift detector nor a backup. Run independent `winget configure test --file $configuration` to inspect package/settings drift. After explicit review and approval, repair that drift by running the selected document directly with `winget configure --file $configuration --accept-configuration-agreements --disable-interactivity --suppress-initial-details`, then repeat tests and chezmoi verify. Do not force all setup scripts or delete chezmoi's state database to repair one resource. Changed owned user files converge through ordinary apply; restore only compatible owned backups/source if rejecting that change. Never run Administrator-profile chezmoi apply. Network/node/SSH recovery remains separately approved, with local Administrator recovery and no private-key/device-state copying.
