# Korolev native Windows operations

## Scope and current state

Windows is the target primary workstation; NixOS-WSL remains a secondary CLI/build environment. Use a native checkout at `C:\Users\JGlock\src\github.com\glockyco\nix-config`, not the separate Linux checkout at `/home/user/src/github.com/glockyco/nix-config`. Windows is not a Nix flake system. This procedure requires no Nix-built Windows output.

WinGet Configuration still owns live packages and Windows settings. The PowerShell 7 engine is a parallel replacement pending owner-confirmed parity, not the active chezmoi hook. Chezmoi owns Windows user files and user setup from `home/`. Each destination has one active owner. Static/mock checks do not claim live provisioning, application/session or network acceptance. Evidence belongs to the OpenSpec change.

Existing live state supplied by the owner on 2026-10-07: per-user Git 2.55.0.5 is at `%LOCALAPPDATA%\Programs\Git` on user PATH; Tern 0.6.0 is at `%LOCALAPPDATA%\Programs\Tern` on user PATH with a Start-menu shortcut; official OMP 18.8.0 is at `%LOCALAPPDATA%\omp\omp.exe` on user PATH with personal plugin 0.2.0, per-user Git Bash selected and owner login complete. Zed's `agent_servers.omp` entry is removed. Do not redo those installations. These facts do not claim native LSP/annotation/network acceptance. The remaining catalog/release selections were verified read-only; further provisioning, UAC, restart and application acceptance are owner-attended. Superseded on 2026-10-09: Tern 0.7.0 runs from `%LOCALAPPDATA%\Programs\Tern`, and Tern-managed OMP at `%LOCALAPPDATA%\Tern\omp\bin` replaced the official-installer copy, which was removed with its PATH entry ([evidence](../../openspec/changes/make-korolev-windows-native/evidence.md#tern-launch-session-daemon-and-omp-ownership-2026-10-09)).

## Source and privilege owners

| Source or state                               | Owner and boundary                                                                                                                                                                                                            |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `windows/configuration.winget`                | Hand-maintained JSON-compatible YAML (actual JSON). WinGet Configuration owns declared installs and Windows settings, never migrated user files. Application metadata beside each resource is the selector/version authority. |
| `windows/workstation.json` and schema         | Parallel declarative inventory with present or named-consumer pinned policies. No live cutover until accepted parity.                                                                                                         |
| `windows/Workstation.psm1` and helpers        | PowerShell 7 test/set engine. Standard user only, explicit dry-run/apply entrypoint, no automatic Administrator tools.                                                                                                        |
| `windows/check-workstation.ps1`               | Built-in schema, parser, analyzer, ownership invariants and mocked Pester behaviors. Never invokes the real engine.                                                                                                           |
| `windows/bootstrap.ps1`                       | Minimal Windows PowerShell 5.1 prerequisite installer and PowerShell 7 handoff. No apply or development-tool installation.                                                                                                    |
| `windows/managed-applications.json`           | Dated Intune exclusion audit, not another application/pin list.                                                                                                                                                               |
| `windows/apply-kbdneo.ps1`                    | Explicit 64-bit Administrator operation: checksum-pinned native Neo DLLs and keyboard registration `b0000407` only.                                                                                                           |
| `windows/apply-zen-policies.ps1`              | Explicit Administrator operation: Zen policy file under Program Files only.                                                                                                                                                   |
| `windows/check.ps1` and fixtures              | Native validation/parser/ownership checks; never live apply.                                                                                                                                                                  |
| `home/` and shared TOML                       | Chezmoi owns portable Git/gh/SSH and Windows app declarations, pinned assets and user setup; undeclared app state remains app-owned.                                                                                          |
| OMP/plugin/Tern/Plannotator                   | Explicit upstream user installations described below, not Nix activation or automatic configuration apply.                                                                                                                    |
| Profiles, credentials, sessions, repositories | Application/user owned. Never copy authentication databases, private keys or browser profiles. Only the three reviewed OMP decision files may cross platforms through the bounded procedure below.                            |

Run the document, user setup and chezmoi as standard `jglock` (`scch\jglock`), never as Administrator and never against the Administrator HOME/HKCU. Only Zen, Tailscale and Docker Desktop are machine-scope package exceptions. The owner supplies the separate Administrator credential for their approved installer prompts. Intune-owned runtime dependencies are prerequisites to inspect, not additional installers. OpenSSH capability/service/firewall setup is a separately approved manual operation, not another general-purpose Administrator script or a document resource. Do not bypass employer restrictions.

Git is removed from the managed exclusion set for its HKCU installation. The audited Patch My PC "Update fuer Git 2.51.0.2" detection and requirements in `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\AppWorkload.log` target HKLM, while the observed Git install is HKCU/per-user. Docker Desktop is also removed for initial machine installation. The owner-confirmed 2026-10-11 `AppWorkload-20261011-084710.log` shows only "Update fuer Docker Desktop 4.47.0". Intune updates an existing machine installation but does not initially install it. The owner confirmed Docker Desktop licensing/entitlement and approved installation on 2026-10-12. The log alone is not licensing evidence. Every other audited excluded ID remains excluded. No Intune policy changes. Re-audit if central ownership changes.

### Docker Desktop permissions and first launch

The [official Windows installer documentation](https://docs.docker.com/desktop/setup/install/windows-install/) and [permission requirements](https://docs.docker.com/desktop/setup/install/windows-permission-requirements/) distinguish the WSL 2 Linux backend from privileged Hyper-V and Windows-container features. Use the default WSL 2 backend. Machine scope keeps the HKLM installation compatible with Intune updates. Do not select per-user installation, enable Hyper-V/Windows containers, add `--always-run-service` or accept the subscription agreement automatically.

The [WinGet 4.94.0 manifest observed on 2026-10-12](https://github.com/microsoft/winget-pkgs/blob/master/manifests/d/Docker/DockerDesktop/4.94.0/Docker.DockerDesktop.installer.yaml) injects `--accept-license`. The resource replaces catalog arguments with `--override 'install --quiet --backend=wsl-2 --no-windows-containers'` so the standard user accepts the agreement on first launch and privileged Windows containers stay disabled. This reviewed argument override is not a version pin.

When the installer credential belongs to a different administrator account, `docker-users` membership is required for privileged Hyper-V/Windows-container features, not WSL 2 Linux containers. Docker warns that this membership grants daemon-equivalent administrative control. The declared resource therefore never changes local groups and never hard-codes an account. If live acceptance refuses the standard user, retain the exact error and review the required backend and permission change separately before adding membership. Resolve the actual standard user's SID from their own session, not the elevated Administrator identity. Any approved membership change requires sign-out/sign-in before retrying.

After reviewed merge and owner approval, use the standard-user preview/apply procedure below. The owner types the separate UAC credential for Docker's machine installer only. Open a fresh standard-user terminal afterward. Start Docker Desktop from Start, click `Accept` on the Docker Subscription Service Agreement, then click `Sign in` and use the employer-approved entitled Docker account if required by the subscription or organization policy. The owner, not configuration, performs agreement acceptance and authentication. Select the WSL 2 Linux backend if prompted. Do not enable integration with the retiring `NixOS` project distro. Follow the [bounded native acceptance procedure](container-runtime.md#korolev) before migrating container projects. Retain Docker-owned distributions and data when retiring `NixOS`.

## Native checks before any live writes

From the reviewed native repository root, as the standard user:

```powershell
powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\windows\check.ps1
pwsh -NoProfile -NonInteractive -File .\windows\check.ps1
winget configure show --file .\windows\configuration.winget
```

Windows PowerShell 5.1 covers scripts executed by that host; PowerShell 7 covers native tooling. The default check validates the vendored official DSC schema and discovered resource-type allowlist, runs isolated positive/negative fixtures and parses document scripts, both Administrator scripts and native scripts. Findings name the resource/script and return nonzero. Read-only WinGet show must exit zero; missing dependencies fail rather than skip. `winget configure validate` is not the gate: WinGet 1.29.380 returns 1 for valid native DSC resources because its public-module warnings count as findings, including on the untouched baseline. [Implementation evidence](../../openspec/changes/make-korolev-windows-native/evidence.md) records the upstream reason and actual discovery versions. Never suppress the warning or call exit 1 a pass. These checks install no workstation resource and require no login; Linux PowerShell 7 evidence is not Windows PowerShell 5.1/WinGet evidence.

The default checker also renders Windows chezmoi scripts, AST-parses their actual PowerShell output, and runs isolated init/apply/verify, Git/SSH and app-state fixtures with process/WinGet doubles. It requires chezmoi 2.73.0, Git and OpenSSH on PATH; it never applies workstation resources to the real profile. `-DocumentPath` selects a document and `-AdditionalScriptPath` accepts a PowerShell `string[]` of additional rendered scripts. Native precommit invokes `windows/check.ps1 -SkipFixtures`, retaining shipped document contracts, the pinned official schema and shipped script AST/Administrator-boundary checks while omitting only isolated fixtures. Staged formatting and staged-Nix same-checkout validation are unchanged. Full on-demand checks above, including rendered chezmoi coverage, remain required before live writes and release; the focused hook is not full acceptance. Complete repository release gates remain in [README](../../README.md#develop), run sequentially.

Windows CI retains both legacy Windows PowerShell 5.1 and locked PowerShell 7 document/fixture jobs until cutover. The unchanged native archive fixture runs in pwsh from either legacy checker because it uses the migrated development bootstrap. A parallel runner-pwsh engine job runs shared formatting once and static/mock checks without WinGet/DSC provisioning or live apply. It caches checksum-verified formatter archive inputs and pinned engine modules. Legacy caches still contain archives only and recheck hashes before extraction. `check (windows-latest)` remains the required aggregate, rejecting failed/cancelled affected children. Docs-only changes run formatting without engine or legacy fixtures. Gate durations are printed. Record actual Actions job/step timings in acceptance evidence.

CLI fallback discovery follows PATH precedence and selects one executable. It never concatenates multiple `Get-Command` application matches. Portable applications still require exactly one executable within their declared package root. The retained archive fixture uses the first PATH-resolved pwsh, which CI places at its locked host path.

The Windows PowerShell invocation uses a process-only execution-policy setting for the reviewed repository fixtures; it changes no persistent policy and cannot override managed policy. Do not modify employer policy to make a check pass. If managed execution restrictions still reject the scripts, record that prerequisite rather than bypassing it.

## Parallel engine acceptance and recovery

Provision local development dependencies and run the engine's static/mock checks from standard-user PowerShell 7.4 or later:

Before merge, a feature worktree and the old main checkout share the common Git hook directory but not the same interpreter declarations. Keep the shared PowerShell 5.1 launcher unchanged and isolate this worktree's pwsh launcher before bootstrapping:

```powershell
git config extensions.worktreeConfig true
git config --worktree core.hooksPath "$PWD/.direnv/windows-hooks"
```

The setting lives in this worktree's `config.worktree` and disappears with the worktree. The launcher remains a real hook, not a bypass. After merging the tooling commit, rerun bootstrap in the updated main checkout to migrate its exact repository-owned shared launcher to pwsh. Any older worktrees must retain their own old launcher until their `native-windows` job is also pwsh. Mixing a pwsh launcher with the old nested powershell.exe job can inherit an incompatible module search path.

```powershell
pwsh -NoProfile -NonInteractive -File .\windows\dev\bootstrap.ps1 -IncludeTestDependencies
pwsh -NoProfile -NonInteractive -File .\windows\dev\engine-dependencies.ps1
pwsh -NoProfile -NonInteractive -File .\windows\dev\format.ps1 -Check
pwsh -NoProfile -NonInteractive -File .\windows\check-workstation.ps1
```

The setup saves Pester 5.7.1 and PSScriptAnalyzer 1.24.0 with PSResourceGet to Git-local `engine-modules`, separate from replaceable formatter tools and never a global profile. `-ModuleRoot` selects an isolated CI/test path. Missing modules fail with an actionable setup command. The checker reads declarations through `Read-WorkstationData`, validates schema and privilege invariants, parses shipped sources, checks the two fixed Administrator scripts without running them, runs the analyzer and executes mocked behaviors. `-StaticOnly` omits only Pester. Native precommit runs that static gate alongside the retained legacy focused checker. Staged Nix validation still requires the same native checkout in the declared WSL environment.

Only the integrator runs the exact live read-only acceptance command on Korolev, from the reviewed checkout as `scch\jglock`, never Administrator:

```powershell
pwsh -NoProfile -File .\windows\workstation.ps1 -DryRun
```

Require every application and setting to be desired and exit 0. Exit 1 means drift. Record each named difference and obtain explicit owner acceptance before proceeding. Exit 2 means validation/execution failure, not accepted drift. Agents never run the engine against the real workstation, apply resources or elevate. Static mocks do not prove real language/input APIs or localized WinGet snapshot parsing.

Only after accepted parity and reviewed backups may the integrator run an explicit engine apply:

```powershell
pwsh -NoProfile -File .\windows\workstation.ps1 -Apply
pwsh -NoProfile -File .\windows\workstation.ps1 -DryRun
```

Do not run both the old document and the new engine apply for the same revision. Apply rejects an elevated session, changes only drifted resources and checks its postconditions. Only Zen, Tailscale and Docker Desktop installer prompts may request the separate Administrator credential. Neo/Zen machine scripts, manual TeX Live, network enrollment, Tern/OMP/plugin setup and authentication remain owner operations. Bun 1.3.13 names omp-agent-setup's `.bun-version` consumer. OpenSpec 1.14.0 names its reusable workflow consumer. Other present applications do not trigger catalog upgrades. A newer consumer-pinned version is incompatible but never downgraded. Reviewed archive/npm integrity selections choose missing-install payloads, not permission to downgrade.

Preserve permission-aware backups outside the checkout of changed registry values/types/absence, user PATH, owned files and chezmoi config/state. Archive delivery retains the previous install directory. If a new release fails, stop, inspect the recorded error and restore only the affected owned directory and PATH from the accepted backup or use the vendor's supported repair. Restore saved registry values with their original types and absent state. Do not delete unrelated fonts or overwrite conflicting font bytes. Do not copy credentials, sessions or whole app profiles into the repository. Native nonzero exits stop without automatic retries. stderr notices alone are not failures. Confirm recovery with an owner-run dry run and app smoke.

Keep the old document, legacy tests, DSC provisioners, chezmoi hook and persisted PowerShell 5.1 interpreter until explicit parity confirmation. Then review a separate hash-protected hook/interpreter cutover and a separate obsolete-source deletion. Reinitialize chezmoi only against the accepted native source revision and inspect its persisted interpreter and diff before apply. Retain the last accepted source revision and backups. CI success alone never authorizes cutover. Record observed CI timings and owner parity evidence before deleting the legacy path.

## Tool ownership, update and recovery matrix

For all **exact** rows, installation targets the reviewed version; drift is reported, not permission to downgrade an already newer installation. Stop and review the installed executable/registration, dependencies and source revision before repair. Select an approved updated declaration or an explicit reviewed reinstall/removal using the tool's supported mechanism and local backup. Never quietly reinstall an older pin. For all **self-updating** rows, WinGet installs/repairs with latest available and no version selector; an installed version newer than catalog is desired and must not be downgraded. There is no additional updater/scheduler.

“Exact repair” below means that explicit review-and-backup procedure, not automatic downgrade. Document URLs/digests and npm integrity records are authoritative; metadata selection is not successful native execution evidence.

| Tool / role                                                | Installer owner, scope and selected policy                                                 | Update path                                            | Recovery path                                                                                                                     |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| Git/GCM (`Git.Git`)                                        | WinGet, user, self-updating; observed 2.55.0.5, not a pin                                  | Vendor/user update; inspect GCM after every Git update | Retain accepted installer and configuration; explicitly repair Git and recheck native GCM/Fork, never downgrade catalog-newer Git |
| Zed (`ZedIndustries.Zed`)                                  | WinGet, user, self-updating                                                                | Vendor channel                                         | Supported vendor repair/accepted build; preserve UI state; no WSL transport or OMP agent server                                   |
| Zen (`Zen-Team.Zen-Browser`)                               | WinGet, machine exception, self-updating                                                   | Vendor channel; re-test narrow policies                | Approved installer repair plus explicit policy script; preserve profile/history and newer version                                 |
| Brave (`Brave.Brave`)                                      | WinGet, user, self-updating, browser relay only                                            | Vendor channel                                         | Supported repair; relay profile/extension remain app-owned; no startup entry                                                      |
| Ferdium (`Ferdium.Ferdium`)                                | WinGet, user, self-updating                                                                | App/vendor updater                                     | Supported repair preserving services, credentials, sessions/cache and startup/update preferences                                  |
| Tern                                                       | Manual signed-in Stencil build, user, self-updating                                        | Stencil/Tern vendor flow                               | Retain previous accepted build outside Temp; preserve `%LOCALAPPDATA%\Tern` and `%APPDATA%\Tern`                                  |
| Fork (`Fork.Fork`)                                         | WinGet, user, exact 2.21.0                                                                 | Reviewed document pin change                           | Exact repair, preserving unrelated app settings; target native Git only after file-owner cutover                                  |
| PowerToys (`Microsoft.PowerToys`)                          | WinGet, user, exact 0.101.2362.0                                                           | Reviewed pin and installed module-key audit            | Exact repair and owned-key backup; preserve UI state, one startup owner, no AltSnap overlap                                       |
| AltSnap (`AltSnap.AltSnap`)                                | Reviewed checksum-verified official release, user, exact 1.68                              | Reviewed archive/executable/hooks pins                 | Exact repair with owned INI backup; preserve 50/50 snapping                                                                       |
| ReNeo (`Rojetto.ReNeo.neo2`)                               | WinGet, user, exact 1.6.0                                                                  | Reviewed pin/config update                             | Exact repair and launcher/config backup; complete separate runtime RunAs prompt at logon                                          |
| JetBrainsMono Nerd Font                                    | Checksum-verified user font payload, exact 3.3.0                                           | Reviewed font/archive checksums                        | Exact repair of declared fonts/registry names only; restart terminal for font test                                                |
| chezmoi (`twpayne.chezmoi`)                                | WinGet, user, exact 2.73.0                                                                 | Reviewed document pin                                  | Exact repair; local config/state backups are separate from user destinations                                                      |
| Tailscale (`Tailscale.Tailscale`)                          | WinGet, approved machine exception, exact 1.102.4                                          | Reviewed pin and network acceptance                    | Approved installer/service recovery; enrollment rollback is separate, no device-state import                                      |
| Docker Desktop (`Docker.DockerDesktop`)                    | WinGet, machine exception, self-updating. Override catalog license acceptance for WSL 2.   | Intune update-only package and vendor channel          | Supported owner-approved repair. Accept newer installed releases without downgrade. Preserve Docker runtime data.                 |
| PowerShell                                                 | Official checksum-verified user ZIP, exact 7.6.6 at `%LOCALAPPDATA%\Programs\PowerShell\7` | Reviewed URL/hash/version                              | Retain accepted ZIP/binary; exact repair, verify absolute executable and any SSH DefaultShell use                                 |
| GitHub CLI                                                 | Official checksum-verified user ZIP, exact 2.102.0                                         | Reviewed URL/hash/version                              | Exact repair; keep Windows-local gh authentication, never manage `hosts.yml`                                                      |
| Node (`OpenJS.NodeJS.LTS`)                                 | WinGet portable ZIP selected with `--scope user`, exact 24.19.0                            | Reviewed document pin                                  | Exact repair; verify node/npm and dependent native wrappers before use                                                            |
| Bun (`Oven-sh.Bun`)                                        | WinGet, user, exact 1.3.13                                                                 | Reviewed document pin matching Mac/plugin development  | Exact repair; never use a Bun-global OMP shim                                                                                     |
| Python (`Python.Python.3.13`)                              | WinGet, user, exact 3.13.15                                                                | Reviewed document pin                                  | Exact repair; inspect native executable versus Store aliases and preserve research environments                                   |
| uv (`astral-sh.uv`)                                        | WinGet, user, exact 0.12.23                                                                | Reviewed document pin                                  | Exact repair; preserve user/project environment data                                                                              |
| ghq (`x-motemen.ghq`)                                      | WinGet, user, exact 1.10.1                                                                 | Reviewed document pin                                  | Exact repair; keep native `~/src` repositories, never substitute Linux clone root                                                 |
| ripgrep (`BurntSushi.ripgrep.MSVC`)                        | WinGet, user, exact 15.2.0                                                                 | Reviewed document pin                                  | Exact repair; verify native `rg` resolution                                                                                       |
| fd (`sharkdp.fd`)                                          | WinGet, user, exact 10.5.0                                                                 | Reviewed document pin                                  | Exact repair; verify native `fd` resolution                                                                                       |
| fzf (`junegunn.fzf`)                                       | WinGet, user, exact 0.74.4                                                                 | Reviewed document pin                                  | Exact repair; verify native picker                                                                                                |
| delta (`dandavison.delta`)                                 | WinGet, user, exact 0.20.1                                                                 | Reviewed document pin                                  | Exact repair; verify Git pager without changing repository policy                                                                 |
| lefthook (`evilmartians.lefthook`)                         | WinGet, user, exact 2.1.17                                                                 | Reviewed document pin                                  | Exact repair; later native development bootstrap owns hook installation; never bypass a failing hook                              |
| markdown-oxide (`FelixZeller.markdown-oxide`)              | WinGet, user, exact 0.25.12                                                                | Reviewed pin and representative Markdown smoke         | Exact repair; verify native initialization/navigation, not version alone                                                          |
| Typst (`Typst.Typst`)                                      | WinGet, user, exact 0.15.1                                                                 | Reviewed pin and document build                        | Exact repair; preserve project fonts/packages/build inputs                                                                        |
| tinymist (`Myriad-Dreamin.Tinymist`)                       | WinGet, user, exact 0.15.8                                                                 | Reviewed pin and LSP smoke                             | Exact repair; verify native diagnostics/navigation                                                                                |
| TexLab (`TexLab.TexLab`, `latex-lsp`)                      | Checksum-verified official user ZIP, exact 5.26.0                                          | Reviewed release URL/hash/version and LSP smoke        | Exact repair; retain accepted archive and prior directory; verify native diagnostics/navigation                                   |
| Poppler (`oschwartz10612.Poppler`, `pdf-text`)             | WinGet, user, exact 25.07.0-0                                                              | Reviewed document pin and native PDF smoke             | Exact repair; verify native `pdftotext`/`pdfinfo`, preserving project inputs                                                      |
| Pandoc (`JohnMacFarlane.Pandoc`, `document-converter`)     | WinGet, user, exact 3.12.1                                                                 | Reviewed document pin and conversion smoke             | Exact repair; preserve project filters/templates/build policy                                                                     |
| QPDF (`QPDF.QPDF`, `pdf-transform`)                        | Checksum-verified official user ZIP, exact 12.4.2                                          | Reviewed release URL/hash/version                      | Exact repair; retain accepted archive and prior directory; preserve original PDFs                                                 |
| ImageMagick (`ImageMagick.ImageMagick`, `image-converter`) | Checksum-verified official user archive, exact 7.1.2-33 (portable Q16 HDRI x64 `.7z`)      | Reviewed release URL/hash/four-component version       | Exact repair; retain accepted archive and prior directory; preserve original images                                               |
| TeX Live                                                   | Owner-run official installer, user, release 2026; reviewed `windows/texlive.profile`       | Explicit `tlmgr update --self --all`; yearly reinstall | Retain previous accepted yearly tree, profile and user PATH backup; no WinGet/Nix rollback or second distribution                 |
| pyright                                                    | npm user prefix, exact 1.1.411                                                             | Reviewed version/integrity/lock change                 | Exact repair of locked packages; verify native `pyright.cmd`/language server                                                      |
| TypeScript                                                 | npm user prefix, exact 5.9.3                                                               | Reviewed version/integrity/lock change                 | Exact repair; preserve project SDK/tsconfig ownership                                                                             |
| typescript-language-server                                 | npm user prefix, exact 5.3.0                                                               | Reviewed version/integrity/lock change                 | Exact repair; TS 5.9.3 compatibility requires native project smoke, not a claimed peer constraint                                 |
| svelte-language-server                                     | npm user prefix, exact 0.17.31                                                             | Reviewed version/integrity/lock change                 | Exact repair; verify native `svelteserver.cmd` in representative project                                                          |
| OpenSpec (`@fission-ai/openspec`)                          | npm user prefix, exact 1.14.0                                                              | Reviewed version/integrity/lock change                 | Exact repair; adapters remain personal-plugin-owned, never run `openspec init` here                                               |
| OMP                                                        | Tern-managed at `%LOCALAPPDATA%\Tern\omp\bin`, first on user PATH                          | Tern's **Check for omp updates**                       | Tern's **Install omp**; preserve `~/.omp` auth/session state; never add a second installer copy                                   |
| Personal plugin                                            | OMP user plugin manager                                                                    | Marketplace update then plugin upgrade, below          | Supported corrective plugin release; retained source/version record, never rewrite cache                                          |
| Plannotator                                                | Official minimal user installer, exact v0.28.7 with attestation verification               | Explicit reviewed vendor release selection             | Reinstall accepted release via same verified minimal flow; no vendor skills/hooks or WSL hosting                                  |

npm packages live under `%LOCALAPPDATA%\Programs\npm`; their native `.cmd` wrappers are under `node_modules\.bin`, which the resource adds to user PATH after Node. Installation uses the reviewed complete integrity lock with `npm ci`, not only direct-package hashes. Node's real ZIP directory provides its adjacent `npm.cmd`. WinGet CLI resources enforce `--scope user` in the installer command and skip automatic runtime dependency installs; missing user installers never fall back to machine scope. Official PowerShell/GitHub ZIPs check hashes before extraction and native versions afterwards, retaining prior directories for recovery. Check the Intune-owned VC++ runtime where required (uv, fd, delta and Typst); do not install competing runtimes. Native failures become terminating errors containing the original exit code because the DSC script host must not swallow an isolated `exit`.

WinGet portable tools are discovered only inside their selected `%LOCALAPPDATA%\Microsoft\WinGet\Packages\<id>_Microsoft.Winget.Source_8wekyb3d8bbwe` directory, allowing nested release folders but requiring exactly one declared executable. The standard account has no symlink privilege: WinGet may put that directory on user PATH and leave `WinGet\Links` empty. Do not enable Developer Mode or create links to make convergence pass; the package root works in either WinGet mode. Node and its adjacent `npm.cmd` use that same root, never a machine/WSL Node or arbitrary PATH match. Reapplying an already-installed exact version does not issue another install; ambiguous executable matches fail for explicit review.

Document native calls temporarily use `ErrorActionPreference = 'Continue'`, capture stderr and the native exit code, then restore the previous preference. A successful npm notice is not a failed install; nonzero exits still terminate with the original native code. Do not suppress those failures or retry a live apply automatically. After the owner applies a reviewed source change, use read-only `winget configure test --file .\windows\configuration.winget` to confirm the installed package roots and versions.

User-scope WiX packages use the Windows Installer API for installed-state discovery: the reviewed UpgradeCode selects related products, `AssignmentType` must be `0` (per-user), and `VersionString` must match the exact pin as well as the native executable. Pandoc's per-user MSI can have an HKLM Uninstall entry that WinGet's `list --scope user` filter misclassifies; the MSI context, not the ARP hive or install-directory spelling, determines scope. Machine-context or ambiguous related products fail; installation still explicitly uses `winget install --scope user`.

Bun 1.3.13 matches the Mac nixpkgs and plugin-development pin because the personal plugin requires that exact native local version. There is no installed Bun to downgrade. TexLab/QPDF/ImageMagick reuse the official archive specification and resource scripts: checksum verification precedes extraction, native version checks follow it and prior directories are retained. ImageMagick extraction invokes absolute inbox `%SystemRoot%\System32\tar.exe`, never a PATH-selected Git GNU tar; its native `7.1.2-33` version is matched as four components with the hyphen preserved.

Svelte's `svelteserver.cmd` has no `--version` mode. Its convergence check verifies the locked installed `svelte-language-server/package.json` version and native wrapper presence, not an unsupported version command that opens IPC. Representative LSP initialization remains a separate live project gate.

For Nerd Font faces, a differing installed TTF does not reliably reveal Nerd Font release ordering. The installer therefore refuses to overwrite different existing content automatically. Back up and identify that installed release, then perform explicit reviewed recovery of only the declared faces; never remove unrelated user fonts.

## Preview, Neo prerequisite, apply and Zen policies

Before writes, retain permission-preserving local backups outside the checkout of affected user settings, PATH/environment, Fork Git references, chezmoi config/state and narrowly owned machine files/registry entries. Record absent paths and versions. Keep previous accepted Nix generations for Linux recovery. Do not export credentials or whole runtime profiles into the repository.

### Bootstrap the standard-user native checkout

Obtain and review `windows/bootstrap.ps1` from the selected repository revision before the first clone. In a fresh standard-user Windows PowerShell 5.1 session, run that script. If the source tree is already available:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\bootstrap.ps1
```

For a separately saved reviewed copy, use its actual path instead. The script installs only PowerShell 7, Git and chezmoi through approved user-scope WinGet commands. It explicitly selects PowerShell's user MSIX instead of the machine MSI, resolves its registered package path and exact portable prerequisite roots, then opens PowerShell 7 with them on process PATH. The [reviewed WinGet installer manifest](https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/m/Microsoft/PowerShell/7.6.6.0/Microsoft.PowerShell.installer.yaml) distinguishes those scopes. Bootstrap still selects the current version when missing. It does not install formatters, run workstation apply, initialize chezmoi or apply user files. No machine-scope fallback or engine elevation is allowed. In the resulting PowerShell 7 shell, clone Windows-local storage. Never reuse the Linux checkout through UNC or `/mnt/c` for user setup:

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

Windows init declares the built-in `powershell.exe` interpreter with `-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File`; package setup therefore does not depend on PowerShell 7 being installed first. Re-run `chezmoi init --source $checkout` after updating an existing clone to refresh that persisted declaration, then inspect diff before apply.

Every Windows PowerShell entry point first establishes a shared, process-only module search path for the Desktop interpreter: its own modules, Windows PowerShell's user/shared defaults and persisted user/machine `PSModulePath` values. This excludes PowerShell 7 runtime directories inherited through chezmoi when applying from `pwsh`, without changing registry environment values or shell profiles. Core-edition execution is unchanged. Windows CI provisions locked PowerShell 7 and exercises the real `pwsh` → chezmoi → `powershell.exe` boundary as well as both full host suites.

The repository's root `.gitattributes` keeps LF in every working tree (`* text=auto eol=lf`), overriding Git for Windows' bootstrap `core.autocrlf=true`, so native formatters, hooks and checks see the same bytes as Linux and macOS. Vendored Windows app includes additionally use scoped `* -text`, so pinned asset bytes are never converted. A fresh clone needs no repair. An older clone may already contain converted CRLF bytes: after updating to the reviewed revision, inspect and back up local edits in that directory outside the checkout before restoring its canonical tracked bytes:

```powershell
git diff -- home/.chezmoitemplates/windows-apps
git restore --source=HEAD --worktree -- home/.chezmoitemplates/windows-apps
git check-attr text -- home/.chezmoitemplates/windows-apps/zed-catppuccin-mauve.asset home/.chezmoitemplates/windows-apps/zen/userChrome.css
```

The reported attribute must be `unset`. This scoped restore discards local edits there, so do not run it without their reviewed backup. Maintainers who need to renormalize the index can then run `git add --renormalize -- home/.chezmoitemplates/windows-apps` and inspect `git diff --cached -- home/.chezmoitemplates/windows-apps`; canonical bytes should produce no asset change. Do not stage the old converted bytes first: `-text` deliberately preserves bytes and would preserve the wrong CRLF content too. Run native checks again before apply.

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

Inspect each result: drift is not an acceptable execution/resource error. Require installer elevation only for Zen/Tailscale/Docker Desktop, never user-profile settings. Dark-appearance acceptance allows Windows' generated `Custom.theme` when declared dark modes/transparency/wallpaper match. It does not demand a fixed active theme path. Do not apply the document's Neo input tip before installing the native driver and restarting.

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
chezmoi verify --exclude=scripts
```

Exclude scripts because the three always-run Windows app stop/restart and Tern PATH scripts remain pending by design; regular managed files still verify.

The Windows-only content-hashed `run_onchange_before_` checks the persisted checkout against Git's root and runs its document before user files. The owner supplies the separate Administrator credential only at approved Zen/Tailscale/Docker Desktop installer prompts. Never elevate the whole apply. Tailscale installation does not authorize enrollment. Use the separately approved network cutover procedure before any Windows node login.

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

## Owner-assisted project migration

The owner-approved 2026-10-12 transfer carries pending work as-is, without publishing. Native roots below are relative to `C:\Users\jglock\src`. Every repository and initialized submodule verified with zero transfer differences. Transfer parity is not project acceptance. [Migration evidence](../../openspec/changes/retire-korolev-wsl-host/evidence.md) records preserved branches, stashes, file counts and exclusions.

| Project and native path                                   | Host requirement | Acceptance status and links                                                                                                                                                                                                                             |
| --------------------------------------------------------- | ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `github.com\glockyco\phd-thesis`                          | Mac + Windows    | Windows 230-page build, hooks, OpenSpec and wrapper tests passed. [Project PR #4](https://github.com/glockyco/phd-thesis/pull/4). Five initialized `projects/` submodules transferred at recorded commits. Mac acceptance not recorded here.            |
| `github.com\glockyco\Teralizer-Paper`                     | Mac + Windows    | Windows 58-page build and OpenSpec passed. Includes `correspondence` on `main`. [Project](https://github.com/glockyco/Teralizer-Paper). Mac acceptance not recorded here.                                                                               |
| `github.com\glockyco\test-generalization`                 | Mac + Windows    | Docker toolchain/materialized-symlink acceptance pending. Origin is [Teralizer](https://github.com/glockyco/Teralizer). `jpf-symbc` and `projects/EqBench` remain uninitialized.                                                                        |
| `github.com\glockyco\omp-agent-setup`                     | Mac + Windows    | Windows local check passed 156 tests with Python 3.13/pywinpty. [Project](https://github.com/glockyco/omp-agent-setup). Mac acceptance not recorded here.                                                                                               |
| `github.com\glockyco\nix-config`                          | Mac + Windows    | Existing native checkout reconciled, no WSL branch transfer needed. [C3 evidence](../../openspec/changes/make-korolev-windows-native/evidence.md). Retirement/Mac integrated gates pending.                                                             |
| `gitlab.scch.at\foci\aisys\saner2027-paper`               | Korolev          | 732 passed, two skipped, both PDFs built on local `korolev-native` commit `0b26b43`. Includes Overleaf `paper`. UNC output share reachable, `S:` unmapped. Container replication pending. [Project](https://gitlab.scch.at/foci/aisys/saner2027-paper). |
| `gitlab.scch.at\foci\aisys\saner2027-overleaf`            | Korolev          | Windows 12-page build passed. [Project](https://gitlab.scch.at/foci/aisys/saner2027-overleaf).                                                                                                                                                          |
| `gitlab.scch.at\foci\aisys\andritz\anita`                 | Korolev          | `uv sync` and catalog notebook execution passed without changing owner state. [Project](https://gitlab.scch.at/foci/aisys/andritz/anita).                                                                                                               |
| `gitlab.scch.at\foci\aisys\andritz\aqua`                  | Korolev          | 845 tests, ruff and ty passed on local `korolev-native` commit `e7755ff`. Compose gate pending. [Project](https://gitlab.scch.at/foci/aisys/andritz/aqua).                                                                                              |
| `gitlab.scch.at\scch\internal-tools\not-so-personalwolke` | Korolev          | Untracked booking skill and local `nix-dev-shell` preserved. Compose gate pending. [Project](https://gitlab.scch.at/scch/internal-tools/not-so-personalwolke).                                                                                          |

Reference clones `can1357/oh-my-pi*` and `backnotprop/plannotator` are excluded. The owner dropped `/tmp/haroon/LLMCodeImpact` from native migration and retains it only in the private WSL export. Disposable dataset-packaging fixtures and smoke repositories are excluded. The export location is `C:\Users\jglock\Backups\wsl\`, retained privately for three months of native use and then deleted. Export and unregister are not yet completed or authorized by this checklist.

### Transfer procedure

1. Inventory HEAD, branches/remotes/upstreams, porcelain status, fixed-option `git diff --binary HEAD` checksum, stash list, `.git/info/exclude`, untracked/ignored files and initialized submodules. Finish source omp sessions with `/exit`. Leave transcripts in WSL.
1. In each source repository and initialized submodule, create temporary `refs/migrate/head`, `refs/migrate/worktree` from `git stash create`, and `refs/migrate/stash/N` for every stash. Bundle kept branches, tags, remote-tracking refs and temporary refs with `git bundle create <bundle> <refs...>`. Delete temporary source refs afterward. Skip a branch only when `git cherry` proves every commit patch-equivalent against its origin branch or origin's default branch. Always keep the checked-out branch.
1. Archive untracked/ignored files in pax tars and local LFS objects separately. Exclude platform environments, symlinks and Windows-invalid names. Record exclusions explicitly. Do not discard pending owner data or publish it.
1. Initialize each new native repository, restore LFS objects first, then `git fetch <bundle> '+refs/*:refs/*'`. Recreate remotes, mapping origin to HTTPS, and restore upstream configuration and HEAD. Set `GIT_LFS_SKIP_SMUDGE=1` for `git reset --hard`, only inside the newly initialized destination, then run `git lfs checkout`. Reconcile an existing native checkout rather than resetting it.
1. Restore each stash with `git stash store`, apply `refs/migrate/worktree` with `git stash apply --index`, and extract file tars. Materialize initialized nested repositories, run HTTPS `git submodule init`, then `git submodule absorbgitdirs`. Leave source-uninitialized submodules uninitialized.
1. Compare ref names/SHAs, HEAD, porcelain status after recorded exclusions, diff checksum, stash list and copied counts/bytes. Require zero differences before refresh. Run `git fetch --prune` over HTTPS. Skip the retained `macbook-pro` remote until native Mac SSH exists. Keep WSL as a second copy until verified export.

Docker installation occurred after cloning. Native Docker/Compose smoke passed before project container acceptance. Container gates and each project's Mac requirement still block destructive retirement.

### Native HTTPS credentials

Run `gh auth login --web --git-protocol https` and let the owner confirm in their browser. GitHub Git uses `gh auth git-credential`. For GitLab, create an owner-local repository-only token with `read_repository` and `write_repository`, then hand it directly to Git Credential Manager via `git credential approve`. Do not print the token or include it in shell history. The observed legacy token expires 2027-10-11. Fine-grained Git/LFS coverage was not assumed.

For `git.overleaf.com`, let the owner generate a fresh Git authentication token and store it in GCM with username `git`. Close token pages after storage. Never copy credentials from WSL. Read-only `git ls-remote` with `GCM_INTERACTIVE=never` proves reuse without prompting.

## Bounded OMP decision migration

After source sessions finish, only `architecture.md`, `product.md` and `style.md` may be copied from a reviewed WSL bank. Never copy `queue/`, `state.json`, transcripts, authentication/session databases, plugin caches or whole `~/.omp`. Back up existing native decision files and have the owner reconcile conflicts. This exception does not transfer sessions or claim process survival.

Bank identity is `<basename>-<Bun.hash(cwd).toString(36)>`, using the resolved cwd exactly as omp sees it on each platform. Compute with that platform's Bun and path resolution. Do not guess hashes, case-normalize Windows paths or reuse Linux bank names. For `C:\Users\jglock\src\gitlab.scch.at\foci\aisys\saner2027-paper`, the native bank is `saner2027-paper-3cdx7sc59ezhj`, paired with WSL `saner2027-paper-168zanlieu4n9`. Banks live under `~/.omp/agent/memories/sharpshooter/`. Compare copied bytes and start a fresh native session to prove decision discovery. [Verified mappings](../../openspec/changes/retire-korolev-wsl-host/evidence.md#tasks-31-32-and-33-bounded-decision-banks).

### Booking plugin and provider login

Use the approved private marketplace, not a skill copy inside personalwolke:

```powershell
omp plugin marketplace add glockyco/omp-booking
omp plugin install --scope user booking@glockyco-booking
```

Upgrade through the manager:

```powershell
omp plugin marketplace update glockyco-booking
omp plugin upgrade --scope user booking@glockyco-booking
```

Start a fresh omp session after installation or upgrade. Verify `skill:book-project-hours` discovery and harmless evidence-helper execution. The helper honors `PI_CODING_AGENT_DIR` and repeated `--session-root`, including retained WSL transcripts when explicitly selected. Booking real hours requires separate owner authorization. Observed plugins are `personal@glockyco` 0.4.0 and `booking@glockyco-booking` 0.1.0 on the sole Tern-managed `%LOCALAPPDATA%\Tern\omp\bin\omp.exe`.

Reproduce only the nonsecret provider definition in `%USERPROFILE%\.omp\agent\models.yml`, preserving other native definitions:

```yaml
providers:
  litellm:
    baseUrl: https://vllm-api.scch.at/v1
```

Do not copy WSL's stored credential. The owner must run `/login` in native omp and obtain one real provider response. Configuration exists, but login/response acceptance remains pending.

## Explicit Tern, OMP, plugin and annotation flows

Owner sign-in/download is required for Tern's closed-beta Stencil service. Install the accepted build at `%LOCALAPPDATA%\Programs\Tern\tern.exe`, not Temp; preserve `%LOCALAPPDATA%\Tern` and `%APPDATA%\Tern`. Add the stable directory exactly once to **user** PATH through reviewed user setup. No invented WinGet ID/download URL. Open actual Tern and prove native PowerShell, executable discovery, Unicode/glyphs, paste, resizing, interrupt and clickable links. Retain the prior accepted build until real session gates pass. Do not uninstall Windows-owned terminals or delete unrelated profiles merely because their declaration is retired.

Launch Tern only through that executable: the Start-menu shortcut, or a taskbar pin created from a window it started. Tern updates the executable it was started from, so a pin or shortcut to another copy silently keeps that copy current instead. The manually created Start-menu shortcut must carry Tern's AppUserModelID `so.stencil.tern` (shortcut property `System.AppUserModel.ID`); without it, Windows cannot match the window to the shortcut and the taskbar shows a blank icon. Do not set `TERN_CONFIG_DIR`; settings and saved sessions belong in the default `%APPDATA%\Tern`.

Sessions survive closing or updating the window only while a window is attached to Tern's session daemon (`\\.\pipe\tern-<user>`). In a pane, `tern whoami` names the pane; Settings › Sessions shows the daemon as running. A window that reports the daemon unavailable runs its programs itself, and they end with the window. Known Tern for Windows defect, reproduced on 0.6.0, 0.6.3 and 0.7.0: the window first connects 14–25 s after launch, but a daemon it started with nothing to restore exits idle after 10 s. A daemon restoring saved panes stayed up, so the defect mainly affects a launch with no saved session. Do not add login daemons, launcher scripts or scheduled tasks to work around it. The palette's **Restart session daemon** does not reattach a window that has already fallen back.

OMP on Windows is Tern-managed. Accept Tern's offer to install it, or run **Install omp** from the palette; Tern places it at `%LOCALAPPDATA%\Tern\omp\bin` and first on user PATH. Then install the personal plugin and Plannotator:

```powershell
omp plugin marketplace add glockyco/omp-agent-setup
omp plugin install --scope user personal@glockyco
pwsh -NoProfile -Command { $env:PLANNOTATOR_MINIMAL = '1'; & ([scriptblock]::Create((Invoke-RestMethod https://plannotator.ai/install.ps1))) -Version v0.28.7 -VerifyAttestation }
```

Verify that `omp` resolves to Tern's copy and check its version. Do not keep an official-installer copy under `%LOCALAPPDATA%\omp` beside it. The Plannotator release selection has published digest/attestation metadata, but that is not cryptographic verification of a downloaded EXE: require `-VerifyAttestation` to succeed, never suppress it. Select binary-only mode with `PLANNOTATOR_MINIMAL=1`, not `-Minimal`: the v0.28.7 script assigns `$minimal = $false` after its parameters, and PowerShell variable names are case-insensitive, so that line discards the `-Minimal` switch and a full install writes vendor skills, OpenCode commands and sidecars. The child `pwsh` keeps the variable out of the session and contains the script's `exit`. Confirm that `~\.plannotator\install-flags.json` lists `minimal` and that no `plannotator*` skills exist under `~\.claude\skills` or `~\.agents\skills`. Minimal mode leaves skills/hooks to the personal plugin. If a full install happened, run `plannotator uninstall --yes` and reinstall. Inspect OMP's actual selected shell: choose native PowerShell or the actual Git-for-Windows Bash executable, never System32 `bash.exe`/WSL. No wrapper, launcher flags, Bun-global OMP, imported auth DB or complete chezmoi-managed OMP config.

Restart OMP and verify both extension modules, all nine personal skills, personal policy, `/personal:opsx-*`, native LSP overrides and disabled Marksman. Owner performs Windows-local Anthropic/OpenAI, GitHub/GCM, browser/Overleaf logins where needed; prove a real response for each provider, `gh auth status`, HTTPS Git access and nonprompting GCM lookup afterwards without printing secrets. Do not copy WSL/Mac credentials.

In actual Tern, use a disposable native checkout with a space in its path: exercise native PowerShell/Git/research/OpenSpec and harmless `personal_commit` preview creating no commit. In the actual Windows browser invoke `/plannotator-annotate` on a disposable file and `/plannotator-last`, submit feedback and prove source unchanged. Cancel a pending review with `/plannotator-cancel`; inspect owned listener/process cleanup after cancel, navigation and shutdown. Closing a browser tab alone is not cancellation. A native lifecycle failure blocks acceptance and requires a separately approved plugin fix, not hidden WSL hosting or omitted commands. Saved OMP history is not process survival across reboot.

Updates are independent: Tern's **Check for omp updates** updates OMP, and the plugin updates with

```powershell
omp plugin marketplace update glockyco
omp plugin upgrade --scope user personal@glockyco
omp --version
omp plugin list
```

Restart and repeat real Tern/annotation/cancel/LSP smokes. Recover OMP through Tern's **Install omp**, the plugin via supported corrective releases, not cache editing or Nix rollback. Plannotator updates remain explicit reviewed minimal installations with verification.

## Native projects and TeX Live

Native Markdown/Python/TypeScript/Svelte and Typst use Windows tools directly. Test initialization, diagnostics/navigation and a representative Typst build, including `.cmd` resolution and paths with spaces. Node/Python availability does not give this repository ownership of project SDKs, virtual environments, root markers, compiler flags or builds. Open native repositories in Zed as local Windows projects. Chezmoi merges declared settings without discarding JSONC comments or unrelated UI state, enforces the Windows-first keymap and installs the pinned theme. There is no WSL transport, nixd or OMP agent server. Make keymap changes in source: the next apply replaces local keymap edits. Verify Ctrl+C/V/A/Z/F in Vim modes, Ctrl+K Ctrl+S, Ctrl+W, ordinary Vim editing and terminal Ctrl+C in the actual editor.

Fork's declared `GitInstancePath` points at `%LOCALAPPDATA%\Programs\Git`, preserving unrelated settings. Global Git uses the work email; `~/src/github.com/` selects the GitHub no-reply identity and repository-local email wins. Shared defaults include Git LFS, delta, `main`, pull/push policy, `autocrlf=input`, HTTPS and native GCM with Overleaf's generic provider. GCM's reviewed relative path is `mingw64/bin/git-credential-manager.exe` for Git 2.55; Git >=2.56 moves to `ucrt64/bin`. Review and update the shared fact after a Git upgrade rather than probing a fallback chain. Credentials, gh `hosts.yml` and private SSH keys are never managed. Confirm effective Git identity and native HTTPS/GCM operations in disposable worktrees before accepting Fork.

Windows Git rewrites both `git@github.com:` and `ssh://git@github.com/` to `https://github.com/`, and both `git@gitlab.scch.at:` and `ssh://git@gitlab.scch.at/` to `https://gitlab.scch.at/`. Existing SSH-form origins and `.gitmodules` entries therefore use native HTTPS credentials without rewriting project metadata. These rules are Windows-only. Mac rendering and SSH transport remain unchanged.

Zed's remembered WSL projects (`wsl_connections`) remain app-owned UI state and survive settings convergence. Only retired managed `lsp.nixd`, `lsp.texlab` and `agent_servers.omp` entries are removed; keeping remembered projects does not restore WSL language-server wiring. PowerToys' declared enabled map reflects the owner's 2026-10-08 live module selection, including FancyZones and `File Explorer`; the absent obsolete `File Explorer Preview` key is not declared.

PowerToys declared module keys, ReNeo launcher/config and AltSnap INI values have chezmoi ownership; app-held files use stop/write/restart setup. PowerToys children stop when needed, but restart only through `%LOCALAPPDATA%\PowerToys\PowerToys.exe`, not by independently launching its modules. AltSnap keeps its existing INI encoding and BOM (including UTF-16LE); new BOMless files and other managed app text use UTF-8 without BOM. Tern's PATH setup preserves unexpanded entries such as `%LOCALAPPDATA%`, keeps `REG_EXPAND_SZ`, and broadcasts the user-environment change; open a fresh shell to inherit it. Zen themes and its single `user.js` preference apply only to real profiles found through `profiles.ini`; create a profile in Zen first, never fabricate one. Cookies/history and unrelated preferences remain untouched. Keep local backups and close applications for recovery. Remove only change-owned old wslgit payload/environment references after live native Fork acceptance, not during fixture validation.

An absent Zen `profiles.ini` skips theme setup during fresh bootstrap; after creating a real profile, ordinary apply discovers it. A present malformed profile declaration or missing declared directory fails rather than writing guessed paths. Dynamic Zen setup rechecks on every apply; ordinary `chezmoi verify --exclude=scripts` covers regular declared destinations, not the dynamically discovered profile writes. Inspect Zen after apply as part of live acceptance.

LaTeX compilation and TexLab run **natively on Windows** against local Windows worktrees. TeX Live 2026 is the single native TeX distribution; its full scheme supplies latexmk, biber and the bundled Windows Perl. TexLab 5.26.0 is the separate checksum-verified user ZIP, discovered by native Zed and OMP. Use the **project's documented** build command and existing root/build configuration; test a representative latexmk/biber build plus actual TexLab diagnostics/navigation in Zed and OMP, including paths with spaces. Overleaf projects still compile on Overleaf; a native installation does not migrate their build ownership. Do not install MiKTeX, wire Windows Zed to WSL/Mac LaTeX transport or add native nixd/Roslyn/C#/Unity servers. Retained WSL TeX and other CLI packages are secondary tools and are not removed by this source unit; use their own Linux Git/build workflow, not Fork/wslgit bridging.

### Owner-run TeX Live 2026 installation and maintenance

TeX Live installation is an explicit owner-run standard-user operation, never automatic WinGet/chezmoi apply or an Administrator operation. Before installation, retain local backups of the user PATH, any existing TeX trees and local package/configuration data; inspect executable discovery so another distribution cannot silently win. Review `windows/texlive.profile` against the official [profile reference](https://tug.org/texlive/doc/install-tl.html#PROFILES). Every selected key is documented there:

| Profile key                    | Reviewed value                              |
| ------------------------------ | ------------------------------------------- |
| `selected_scheme`              | `scheme-full` (no collection overrides)     |
| `TEXDIR`                       | `C:/Users/jglock/texlive/2026`              |
| `TEXMFLOCAL`                   | `C:/Users/jglock/texlive/texmf-local`       |
| `TEXMFSYSCONFIG`               | `C:/Users/jglock/texlive/2026/texmf-config` |
| `TEXMFSYSVAR`                  | `C:/Users/jglock/texlive/2026/texmf-var`    |
| `TEXMFCONFIG`                  | `C:/Users/jglock/.texlive2026/texmf-config` |
| `TEXMFVAR`                     | `C:/Users/jglock/.texlive2026/texmf-var`    |
| `TEXMFHOME`                    | `C:/Users/jglock/texmf`                     |
| `instopt_adjustpath`           | `1`                                         |
| `tlpdbopt_install_docfiles`    | `0`                                         |
| `tlpdbopt_install_srcfiles`    | `0`                                         |
| `tlpdbopt_desktop_integration` | `0`                                         |
| `tlpdbopt_file_assocs`         | `0`                                         |
| `tlpdbopt_w32_multi_user`      | `0`                                         |

These are literal unquoted forward-slash paths, not `$HOME`, `%USERPROFILE%` or environment-variable expressions: `--profile` ignores environment variables. For another account, copy the profile to a temporary local file outside the checkout, replace `C:/Users/jglock` in **all seven** path values with that account's verified absolute profile path, then review every resulting line and destination before passing that temporary file to the installer. Do not edit the committed Korolev profile or assume installer expansion. Retain the reviewed profile with installation/recovery records.

The [official Windows documentation](https://tug.org/texlive/windows.html#install) recommends the [official installer](https://mirror.ctan.org/systems/texlive/tlnet/install-tl-windows.exe) and states that it runs the standard installer with command-line options. The [installer option reference](https://tug.org/texlive/doc/install-tl.html#OPTIONS) documents `--profile` (batch installation) and `--non-admin` (current user only). After owner approval, download and inspect that official installer, then run from standard-user PowerShell in the native checkout:

```powershell
$profile = (Resolve-Path -LiteralPath '.\windows\texlive.profile').Path
$installer = Join-Path $env:TEMP 'install-tl-windows.exe'
Invoke-WebRequest -Uri 'https://mirror.ctan.org/systems/texlive/tlnet/install-tl-windows.exe' -OutFile $installer
$install = Start-Process -FilePath $installer -ArgumentList @('--non-admin', '--profile', ('"{0}"' -f $profile)) -Wait -PassThru
if ($install.ExitCode -ne 0) { throw "TeX Live installer failed with exit $($install.ExitCode); inspect its log and partial state" }
```

For another account set `$profile` to the reviewed temporary profile instead. The profile disables documentation/source files, desktop integration, file associations and multi-user integration, while `instopt_adjustpath 1` with `--non-admin` adds only `C:\Users\jglock\texlive\2026\bin\windows` to **user** PATH. Open a fresh standard-user shell and inspect `Get-Command tlmgr, latexmk, biber, texlab`; require native per-user paths, the intended single user PATH entry and the actual project/editor smoke, not just installer completion. Review the installer log and resulting `tlpkg/texlive.profile`; installation is not claimed executed by this documentation.

```powershell
tlmgr --version
latexmk -v
biber --version
texlab --version
```

Package updates remain explicit standard-user maintenance:

```powershell
tlmgr update --self --all
```

There is no scheduler. TeX Live updates within a release year, not across annual releases: review and run a new official installation with a revised year-specific profile for the next release. Retain the previous accepted yearly tree, local package data and PATH backup until native project/TexLab acceptance passes; switch only the reviewed user PATH entry. An interrupted installation/update is nontransactional: inspect logs and partial state, repair with the supported installer/tlmgr workflow or restore the accepted tree and owned PATH from backup, preserving project data. Never add MiKTeX, a machine-scope fallback or WSL/Mac transport to conceal failure.

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

Ordinary-user maintenance is `chezmoi diff`, `chezmoi apply`, `chezmoi verify --exclude=scripts` from the persisted native checkout. Excluding the three always-run Windows scripts checks file convergence without treating their pending execution as drift. An unchanged document hash does not rerun WinGet; the script ledger is neither a live-drift detector nor a backup. Run independent `winget configure test --file $configuration` to inspect package/settings drift. After explicit review and approval, repair that drift by running the selected document directly with `winget configure --file $configuration --accept-configuration-agreements --disable-interactivity --suppress-initial-details`, then repeat tests and `chezmoi verify --exclude=scripts`. Do not force all setup scripts or delete chezmoi's state database to repair one resource. Changed owned user files converge through ordinary apply; restore only compatible owned backups/source if rejecting that change. Never run Administrator-profile chezmoi apply. Network/node/SSH recovery remains separately approved, with local Administrator recovery and no private-key/device-state copying.

GitHub CLI rewrites `AppData/Roaming/GitHub CLI/config.yml` with one final newline and no trailing blank line. The Windows chezmoi wrapper trims its own template newline to preserve that serialization and avoid repeated drift prompts.
