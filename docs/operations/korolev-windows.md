# Korolev native Windows operations

## Scope and current state

Windows is the target primary workstation; NixOS-WSL remains a secondary CLI/build environment. Use a native checkout at `C:\Users\JGlock\src\github.com\glockyco\nix-config`, not the separate Linux checkout at `/home/user/src/github.com/glockyco/nix-config`. Windows is not a Nix flake system. This procedure requires no Nix-built Windows output.

This source unit does **not** complete the later chezmoi user-file migration or claim native provisioning/session/network acceptance. The hand-maintained document still contains surviving user-file resources until that migration removes them. Do not introduce a second writer in `home/` before the corresponding document writer is removed. Renderer code is temporarily retained for the remaining cutover work, not a second permanent Windows source. Implementation evidence belongs to the OpenSpec change, not this current-state manual.

Existing live state supplied by the owner on 2026-10-07: per-user Git 2.55.0.5 is at `%LOCALAPPDATA%\Programs\Git` on user PATH; Tern 0.6.0 is at `%LOCALAPPDATA%\Programs\Tern` on user PATH with a Start-menu shortcut; official OMP 18.8.0 is at `%LOCALAPPDATA%\omp\omp.exe` on user PATH with personal plugin 0.2.0, per-user Git Bash selected and owner login complete. Zed's `agent_servers.omp` entry is removed. Do not redo those installations. These facts do not claim native LSP/annotation/network acceptance. The remaining catalog/release selections were verified read-only; further provisioning, UAC, restart and application acceptance are owner-attended.

## Source and privilege owners

| Source or state                               | Owner and boundary                                                                                                                                                                                                                                 |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `windows/configuration.winget`                | Hand-maintained JSON-compatible YAML (actual JSON). WinGet Configuration owns declared installs and Windows settings; surviving user-file resources are transitional. Application metadata beside each resource is the selector/version authority. |
| `windows/managed-applications.json`           | Dated Intune exclusion audit, not another application/pin list.                                                                                                                                                                                    |
| `windows/apply-kbdneo.ps1`                    | Explicit 64-bit Administrator operation: checksum-pinned native Neo DLLs and keyboard registration `b0000407` only.                                                                                                                                |
| `windows/apply-zen-policies.ps1`              | Explicit Administrator operation: Zen policy file under Program Files only.                                                                                                                                                                        |
| `windows/check.ps1` and fixtures              | Native validation/parser/ownership checks; never live apply.                                                                                                                                                                                       |
| `home/` and shared TOML                       | Existing portable chezmoi source; Windows user-file ownership is the later clean cutover, not implemented by this documentation unit.                                                                                                              |
| OMP/plugin/Tern/Plannotator                   | Explicit upstream user installations described below, not Nix activation or automatic configuration apply.                                                                                                                                         |
| Profiles, credentials, sessions, repositories | Application/user owned. Never copy authentication databases, private keys, browser profiles or another platform's OMP state.                                                                                                                       |

Run the document, user setup and any eventual chezmoi apply as standard `JGlock` (`scch\jglock`), never as Administrator and never against the Administrator HOME/HKCU. Only Zen and Tailscale are machine-scope package exceptions; the owner supplies the separate Administrator credential for their approved installer prompts. Intune-owned runtime dependencies are prerequisites to inspect, not additional installers. OpenSSH capability/service/firewall setup is a separately approved manual operation, not a third general-purpose Administrator script or a document resource. Do not bypass employer restrictions.

Git alone is removed from the managed exclusion set: the audited Patch My PC “Update für Git 2.51.0.2” detection and requirements in `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppWorkload.log` target HKLM, while the observed Git install is HKCU/per-user. That update package does not own this installation. Docker Desktop and every other audited excluded ID remain excluded; this does not modify Intune policy. Re-audit if central ownership changes.

## Native checks before any live writes

From the reviewed native repository root, as the standard user:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\windows\check.ps1
pwsh -NoProfile -NonInteractive -File .\windows\check.ps1
winget configure show --file .\windows\configuration.winget
```

Windows PowerShell 5.1 covers scripts executed by that host; PowerShell 7 covers native tooling. The default check validates the vendored official DSC schema and discovered resource-type allowlist, runs isolated positive/negative fixtures and parses document scripts, both Administrator scripts and native scripts. Findings name the resource/script and return nonzero. Read-only WinGet show must exit zero; missing dependencies fail rather than skip. `winget configure validate` is not the gate: WinGet 1.29.380 returns 1 for valid native DSC resources because its public-module warnings count as findings, including on the untouched baseline. [Implementation evidence](../../openspec/changes/make-korolev-windows-native/evidence.md) records the upstream reason and actual discovery versions. Never suppress the warning or call exit 1 a pass. These checks install no workstation resource and require no login; Linux PowerShell 7 evidence is not Windows PowerShell 5.1/WinGet evidence.

The checker supports `-DocumentPath` for a selected document and `-AdditionalScriptPath` as a PowerShell `string[]` for actual rendered scripts in an isolated fixture tree. For the later chezmoi/ReNeo migration, pass every rendered PowerShell script, not unrendered template text:

```powershell
& .\windows\check.ps1 -DocumentPath .\windows\configuration.winget -AdditionalScriptPath @('C:\fixture\rendered\one.ps1', 'C:\fixture\rendered\two.ps1')
if ($LASTEXITCODE -ne 0) { throw 'Native Windows check failed' }
```

The paths above illustrate the interface; replace them with the real fixture output paths. Run this invocation in both required PowerShell hosts. `-SkipFixtures` permits focused parser/invariant inspection only; it is not the complete acceptance gate. Checks derive mutable pins/checksums from source, not this prose. Complete repository release gates remain in [README](../../README.md#develop), run sequentially by the integration owner.

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

For Nerd Font faces, a differing installed TTF does not reliably reveal Nerd Font release ordering. The installer therefore refuses to overwrite different existing content automatically. Back up and identify that installed release, then perform explicit reviewed recovery of only the declared faces; never remove unrelated user fonts.

## Preview, Neo prerequisite, apply and Zen policies

Before writes, retain permission-preserving local backups outside the checkout of affected user settings, PATH/environment, Fork Git references, chezmoi config/state and narrowly owned machine files/registry entries. Record absent paths and versions. Keep previous accepted Nix generations for Linux recovery. Do not export credentials or whole runtime profiles into the repository.

Do not execute the whole-document apply below while the transitional Fork/Zed/Zen/ReNeo/PowerToys/AltSnap user-file writers remain. Complete their single-owner chezmoi migration first; validation and the explicit Neo/Zen test procedures are safe review steps before that cutover.

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
winget configure --file $configuration --accept-configuration-agreements --disable-interactivity --suppress-initial-details
```

The owner supplies the separate Administrator credential only at approved Zen/Tailscale installer prompts. Never elevate the whole document. Tailscale installation does not authorize enrollment; use the separately approved network cutover procedure before any Windows node login.

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

Native Markdown/Python/TypeScript/Svelte and Typst use Windows tools directly. Test initialization, diagnostics/navigation and a representative Typst build, including `.cmd` resolution and paths with spaces. Node/Python availability does not give this repository ownership of project SDKs, virtual environments, root markers, compiler flags or builds. Open native repositories in Zed as local Windows projects; the later settings migration removes WSL transport/nixd/OMP agent integration rather than replacing it with another launcher. Fork's target native Git/GCM migration also belongs to that later clean cutover; do not manually introduce competing settings writers here.

LaTeX compilation and TexLab run on the **Mac's existing full TeX closure**. Keep a separate local Mac clone of the project; exchange committed work through Git, or transfer disposable inputs with approved SSH/SFTP while preserving originals. Use the Mac's approved `macbook-pro` interactive or `macbook-pro-batch` endpoint to run the **project's documented** build command in that clone. Run TexLab with the Mac editor/agent against that Mac worktree; retrieve/view the resulting PDF through the approved transfer workflow. Verify a representative actual Mac editor/TexLab/build session before declaring acceptance. Project root/build settings remain project-owned. Do not install native MiKTeX/TexLab, wire Windows Zed to WSL LaTeX, or add native nixd/Roslyn/C#/Unity servers. Retained WSL TeX and other CLI packages are secondary tools and are not removed by this source unit; use their own Linux Git/build workflow, not Fork/wslgit bridging.

## Manual preferences and nontransactional recovery

Use Windows Settings for default associations, taskbar pins and Night light (sunset-to-sunrise, 50% strength). Keep Austria as country/region. Do not edit undocumented CloudStore bytes, manufacture `UserChoice` hashes or claim these preferences converge through the document. Zen is the interactive browser; Brave is the approved OMP relay with no startup entry. Ferdium owns its profile/services/authentication/session/cache/startup/update preferences; a fresh profile's defaults are not managed state.

**DSC/Windows has no generation or transactional rollback.** A failure can leave earlier resources installed or settings changed. Stop; inspect resource errors, actual versions and partial state before repair. A Git revert does not restore files, uninstall packages or reverse policy/service/node operations. Nix rollback restores only Nix-owned Linux/Mac state.

Restore only backed-up, change-owned user files/PATH/Fork references and compatible reviewed source, preserving post-cutover UI edits, repositories, profiles, credentials and OMP history. Restore narrowly owned Neo DLL/registration or Zen policy backups from local Administrator recovery as appropriate; keyboard changes require a coordinated restart and input verification. Package repair is a separately reviewed supported installer operation, never an implicit downgrade. Repeat native checks, WinGet test, both narrow script tests and actual app/session acceptance. Keep backups/accepted binaries/generations until all applicable live gates pass.

Target later chezmoi operation is ordinary-user `chezmoi diff`, `chezmoi apply`, `chezmoi verify` from the persisted native checkout; a content-hashed before-script runs WinGet only when source changes. That migration is not implemented here. Its unchanged script ledger is not a live-drift detector or a backup: use independent WinGet test and an explicit approved selected-script rerun for repair. Never run Administrator-profile chezmoi apply. Network/node/SSH recovery remains separately approved, with local Administrator recovery and no private-key/device-state copying.
