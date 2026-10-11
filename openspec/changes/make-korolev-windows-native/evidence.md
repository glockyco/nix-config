# Implementation evidence: make-korolev-windows-native

## Reviewed base and responsibilities (2026-10-07)

Reviewed revision: `5fe8e1cd0312f88175af3216de52c3331a4e8d13` on `feat/korolev-windows-native`. This includes the scheduling clarification and predecessor source cutovers. Change 0 is archived; changes 1/2 are merged/live on Korolev by owner-provided state; their remaining Mac gates remain in the shared owner-attended session. Source inspection found no Home Manager module/input or wrapped OMP declaration and no managed Zed `agent_servers.omp`. Legacy chezmoi removal entries mentioning Home Manager are cleanup ownership, not a live module. The predecessor uses `.chezmoiroot = home`, shared `home/.chezmoidata/{hosts,ssh}.toml` facts, persisted checkout `sourceDir`, and portable SSH templates. Windows platform extension is the next wave, not silently inferred from Linux `user`.

| Responsibility           | Source / boundary                                                                                                             |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| Windows apps/settings    | Hand-maintained `windows/configuration.winget`; ordinary account except approved Zen/Tailscale machine installers             |
| Administrator operations | Fixed `windows/apply-zen-policies.ps1` and `windows/apply-kbdneo.ps1`; explicit operations only                               |
| Intune exclusions        | Dated `windows/managed-applications.json`, old audited list minus only per-user Git                                           |
| Native gates             | `windows/check.ps1`, controlled `windows/tests/`, official schema/provenance under `windows/schemas/`                         |
| User destinations        | Existing `home/` chezmoi owner; remaining document user-file writers move together in wave 2                                  |
| Native runtime state     | Upstream OMP/plugin, Tern, app profiles/credentials/sessions; never Nix or whole-profile chezmoi                              |
| Network cutover          | Separate network slice and `docs/operations/korolev-remote-access.md`; no host changes in this source unit                    |
| Legacy renderer/checker  | Temporarily retain `packages/windows-configuration*` and `checks/windows-configuration.nix` until wave 2 removes every caller |

Existing live state supplied by owner, not repeated: Git 2.55.0.5 at `%LOCALAPPDATA%\Programs\Git`, Tern 0.6.0 at `%LOCALAPPDATA%\Programs\Tern` with PATH/Start-menu entry, official OMP 18.8.0 at `%LOCALAPPDATA%\omp\omp.exe`, personal plugin 0.2.0, native per-user Git Bash selected, owner logged in, Zed OMP agent-server entry removed. This is not native LSP/browser/session/network acceptance.

## One-time renderer capture

Ran exactly once at the reviewed base:

```sh
nix build .#windows-configuration --no-link --print-out-paths
```

Output: `/nix/store/yhl6v8idy915pai4m24rdkcf2axa3hh2-windows-workstation-configuration` (exit 0). Captured the three primary artifacts as ordinary source. Review assets remain in that immutable capture, identified below, not a new generated mirror. Python/PyYAML parsed the original YAML; JSON serialization followed by JSON parsing compared equal at the value level (PASS). Normalized document SHA-256 before resource migration: `939a1fc39b521897d8693cbee06151126f5a1f8822ac40bd33a3285a176c32d0`.

| Captured artifact                | SHA-256                                                            |
| -------------------------------- | ------------------------------------------------------------------ |
| `altsnap-package.json`           | `868d51eddc97c86314cc5d169c71261bda0a39f7dd840fcfed9b71338242dd45` |
| `altsnap-settings.json`          | `574ce4c1b36bedb8ea18ad19eafb59ca8e1e9ec21351e563ecd87cec23689e93` |
| `apply-kbdneo.ps1`               | `872e36b8c5eefcf8a5b13b94f7aa626cc59a8d1846513b2e0168056835b5e325` |
| `apply-zen-policies.ps1`         | `0e25199c5dd1e22e37347520ee66f48abf8870520819ce44dca2a690b69e3a6e` |
| `configuration.winget`           | `7ac0ac432e33bb3f40a103d3a737f39f93fc88a9f6917ca40a684c09f397a18e` |
| `fork-wslgit.json`               | `113fca19dbc0948e099e5af1fea859fc72bb437c859fcee1afdebf334e835003` |
| `kbdneo.json`                    | `8b4f20e2305ea346a13fdbaef5b1e620e22485a24b5272d69f92d535463aac6a` |
| `power-toys-settings.json`       | `1e0b9870a16e54cabbf874aeabebfc7da5adaed2d72a948a4ea1e52f5ef0872d` |
| `reneo-settings.json`            | `f7d6eea909a136d654986cda2d8c5c9e7be22e6394e72aa765987c8342f72718` |
| `start-reneo-elevated.ps1`       | `6885707577d59aded209933fdc9fbb2510dab6ef511b8176f62e94fc4fe5dbaf` |
| `terminal-settings.json`         | `23676aaa3fddac50e235291b1fcaf4272c0b8fdef1b7ba430d19262309ba535a` |
| `zed-catppuccin-theme.json`      | `2dccb9fb3ff888e646407b4f84d400304553e0d9a9688ac75d0f9fcd3f8bdf6a` |
| `zed-keymap.json`                | `d2fee38c50c624ce07fa50bde1dadc4ad9fc09927ae7e6fb20b4efc1f2e5bd1b` |
| `zed-settings.json`              | `da5b5a33ad3a3140da372f5fdfdb0974b24e61eac856b49190d07562e253e6b3` |
| `zen-catppuccin-logo.svg`        | `b41be8bf6c8659c532a0b1b984488696073adb31aec7a089211d4f4a7ecd9a83` |
| `zen-catppuccin-userChrome.css`  | `98ba97510bf2ecd8636686238242cb0f2e43552e2bb93c520818ed89da92189b` |
| `zen-catppuccin-userContent.css` | `297a3c45e624792892482ab45552625b2765e6d44947e878fe5c5731eb7cd44a` |
| `zen-catppuccin.json`            | `5c24f09462836fd70b5c0f8527e09f998e12a329f05c568764bf04015707f1a7` |
| `zen-policies.json`              | `3a46acc9e10964ac66b4fd33d5fb94c9a6a5d9aa0945ec83d72f174e91aae310` |

## Native validator findings and approved gate revision

Read-only Windows runtime: WinGet `1.29.380` / DesktopAppInstaller `1.29.380.0`; Windows build `10.0.26100.9448`; DSC `3.2.3`. `winget configure validate --file` returned **1**, both for the untouched Nix-built YAML and the value-equivalent normalized JSON document. Every native type produced module-not-provided/public-availability warnings. No resource was applied and no dependency installed.

This is not missing native resource discovery: read-only `dsc resource list <type>` found:

| Type                                                 | Manifest version | Distribution                                  |
| ---------------------------------------------------- | ---------------- | --------------------------------------------- |
| `Microsoft.WinGet/Package`                           | `1.29.380`       | DesktopAppInstaller `1.29.380.0`              |
| `Microsoft.Windows/Registry`                         | `1.0.0`          | Microsoft.DesiredStateConfiguration `3.2.3.0` |
| `Microsoft.DSC.Transitional/WindowsPowerShellScript` | `0.1.0`          | Microsoft.DesiredStateConfiguration `3.2.3.0` |

These are native DSC resources, not PowerShell Gallery modules. Their local manifests were discoverable without installation. [WinGet's `ValidateConfigurationSetUnitProcessors`](https://github.com/microsoft/winget-cli/blob/master/src/AppInstallerCLICore/Workflows/ConfigurationFlow.cpp) sets `foundIssue` for absent module metadata and nonpublic catalog details, then terminates with `S_FALSE`. Exit 1 is **not** accepted or suppressed. The integration owner approved replacing this unsuitable gate with official-schema/native checks plus read-only WinGet show parsing; design, proposal, task wording and spec deltas now record that decision.

`winget configure show --file` exited **0** for both baseline and native source (`BASELINE_SHOW_EXIT=0`, `NATIVE_SHOW_EXIT=0`). Show reports large inline values truncated for display; that is display behavior, not discarded source. The command wrapper later returned 1 only because the separate read-only `Get-Command pwsh.exe` query found no installed native PowerShell 7; the two WinGet statuses were explicitly captured before that query. Native PowerShell 7 provisioning has not occurred.

The official declared `2023/08` schema was pinned to the upstream [DSC v3.2.3 release](https://github.com/PowerShell/DSC/tree/v3.2.3/schemas/2023/08), with all seven referenced source documents preserved unchanged and URL/SHA-256 provenance. `windows/schemas/document.schema.json` inlines the external references without changing validation keywords. The native check verifies hashes and validates the shipped document. Official schema validation requires alphanumeric/space resource names and typed `resourceId()` dependency expressions; final resource migration corrects the baseline's bare dependencies. This correction is **after**, not part of, the value-equal normalization capture.

The unmodified upstream documents use `.schema` filenames so repository JSON formatting cannot rewrite their reviewed bytes. Local schema attributes keep the bundled validator at LF on Windows before user Git configuration and disable text conversion for `upstream/**`; provenance hashes remain portable. The upstream MIT license is retained.

## Reviewed native distributions

Each new WinGet ID/version/user x64 selection was re-queried read-only with `winget show --id <ID> --exact --source winget --version <version> --scope user --architecture x64 --accept-source-agreements --disable-interactivity` (all returned 0). Exact installer URLs/hashes were compared against the corresponding upstream [winget-pkgs manifests](https://github.com/microsoft/winget-pkgs/tree/master/manifests); per-resource distribution metadata retains the exact manifest URL. This proves catalog selection, not installation success. Machine Tailscale's manifest explicitly declares machine scope; its document command selects WiX/x64/machine, with no login/enrollment.

PowerShell 7.6.6 ZIP URL and SHA-256 were re-verified against [the official hashes file](https://github.com/PowerShell/PowerShell/releases/download/v7.6.6/hashes.sha256), including decoding its UTF-16 encoding. GitHub CLI 2.102.0 URL/SHA-256 were re-verified against [its official checksums](https://github.com/cli/cli/releases/download/v2.102.0/gh_2.102.0_checksums.txt). ZIP resource fixtures verify download hashes before extraction, executable versions, repeat state, drift and retained previous directories.

The official GitHub CLI ZIP was also downloaded into the investigation process, independently matched against SHA-256 `ae64e556ecc240b200f7eba60d550e4bb60d78e860e69dd88c449405b86067f4`, and inspected as an archive: it contains `LICENSE` and `bin/gh.exe` at the root, not a versioned enclosing directory. The resource uses that observed layout; no binary was installed on Windows.

Exact npm metadata was re-queried directly from registry version endpoints for pyright 1.1.411, TypeScript 5.9.3, typescript-language-server 5.3.0, svelte-language-server 0.17.31 and OpenSpec 1.14.0. An npm package-lock-only resolution produced 128 package records; every direct selected version/integrity matched registry metadata. The complete integrity lock is embedded in the resource for `npm ci --ignore-scripts`. No tool was installed on the live host. The user prefix is `%LOCALAPPDATA%\Programs\npm`; wrappers are in `node_modules\.bin`, and Node's actual ZIP directory supplies `npm.cmd`.

The standard npm lock contains an empty-string root package key. Preserve the lock as JSON text in the script specification; parse it with PowerShell 7 hashtables or Windows PowerShell 5.1's built-in `JavaScriptSerializer`, never discard that root record. This retains complete `npm ci` semantics on both hosts.

Plannotator stays the explicit official `install.ps1 -Minimal -Version v0.28.7 -VerifyAttestation` runbook step. OMP release `v18.8.0` was verified in official release metadata by the runbook author; existing owner-provided live installation is preserved.

Read-only release metadata reconfirmed Plannotator `v0.28.7`, `plannotator-win32-x64.exe` digest `798e65e03d8f3b811f0d9bd3ed64a8b5be895e271bb6e2ffe6b0b2f2f2d47b0f`, and three published attestation bundles. That is attestation availability, not cryptographic verification of a downloaded binary.

## Gate execution

After all source slices landed, the integration owner exercised the following gates. No live configure/chezmoi apply, tool installation, enrollment, activation or push occurred.

Final hand-maintained `windows/configuration.winget` SHA-256: `c62579c54baa799f0b5ef914a6410db80e348c949eea4ddbe9173193aadaa7a9`. This includes the reviewed migration; it is deliberately different from the baseline normalization hash.

| Gate                                                                                                       | Exercised result                                                                                                                                    |
| ---------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `nix fmt -- --fail-on-change`                                                                              | Exit 0; 3 formatted files, 0 changes after the initial formatter corrections                                                                        |
| `openspec validate make-korolev-windows-native --strict`                                                   | Exit 0; change valid                                                                                                                                |
| `nix flake check --print-build-logs`                                                                       | Exit 0; all local checks passed, including the retained renderer/checker                                                                            |
| `nix flake check --all-systems --print-build-logs`                                                         | Exit 0; full matrix evaluated, all applicable checks passed                                                                                         |
| Explicit `checks.aarch64-darwin` collection build                                                          | Exit 0; logs show actual builds on `ssh-ng://glockyco@macbook-pro`, including treefmt, OpenSpec, chezmoi and Mac system dependencies; no activation |
| Windows PowerShell 5.1 `windows/check.ps1`                                                                 | Exit 0; complete positive/negative schema, invariants, AST, installer, additional-script and public-entrypoint fixtures passed                      |
| PowerShell 7 via `nix shell nixpkgs#powershell -c pwsh -NoProfile -NonInteractive -File windows/check.ps1` | Exit 0; the same complete positive/negative fixture suite passed on Linux                                                                           |
| Read-only `winget configure show --file windows/configuration.winget`                                      | Exit 0 on final source (`FINAL_WINGET_SHOW_EXIT=0`), as well as baseline                                                                            |

The required Nix sequence was run strictly in order; the explicit Darwin check build followed it to prove actual Mac builder execution rather than only foreign-system evaluation. Native scripts were exercised with Windows PowerShell `-NoProfile -NonInteractive -ExecutionPolicy Bypass -File` against the source UNC path. The initial no-policy invocation was rejected by execution policy; the reviewed fixture invocation uses a process-only setting, changes no persistent policy and cannot override managed policy. PowerShell 5.1-specific default-parameter/UNC-provider handling, npm lock parsing and fixture dynamic-scope collisions were corrected before the complete successful run. Installer failures are asserted as terminating errors retaining native code 23. Exact/newer and self-updating/newer fixtures assert no downgrade or reinstall.

## Wave 1 migration handoff (historical)

`windows/check.ps1` is the native entrypoint. `-DocumentPath` selects a JSON-compatible WinGet document; `-AdditionalScriptPath` is a `string[]` of actual rendered PowerShell files (including the migrated ReNeo launcher/setup scripts). Default execution includes controlled positive/negative fixtures; `-SkipFixtures` is inspection-only, not acceptance. Run under Windows PowerShell 5.1 and PowerShell 7, plus Linux pwsh parity. CI's separate WinGet parse gate is `winget configure show`, not `validate`. Install only pinned runner dependencies; fail missing runtime/resource discovery, never skip or apply.

Retained document user-file resources requiring a single-owner chezmoi move:

- `fork wslgit`: replace its old bridge/settings with the verified native Git path, then remove only owned legacy payload/environment state after live Fork acceptance.
- `zed catppuccin theme`.
- `zen catppuccin theme`.
- `reneo elevation launcher`.
- `zed keymap`.
- `zed settings`.
- `reneo settings`.
- `power toys settings`.
- `package window tool`: preserve the AltSnap installer payload; move its declared INI writes/stop-write-restart behavior to chezmoi before removing that configuration writer.

`windows terminal settings` and `package terminal` are already removed, preserving unrelated Windows Terminal state. Old Fork wslgit/Zed WSL content remains only in transitional document user-file resources pending wave 2; do not perform a live whole-document apply before their replacement. Move every writer and then delete both renderer/checker packages and all flake/check callers. Keep the two fixed Administrator scripts and native settings/installer resources. Preserve shared checksum/theme-license metadata, app-owned data and UTF-8 without BOM.

Native facts: standard AD principal `scch\jglock`, profile `C:\Users\jglock`; read-only discovery confirmed `%LOCALAPPDATA%\Programs\Git\mingw64\bin\git-credential-manager.exe` and `bin\bash.exe` exist. GCM reports `2.9.1+6760f0ef069c994aa2bb1d703fb374986ee82a3e` when the disposable query process reconstructs PATH from the Windows Machine/User values. Its first WSL-inherited-PATH version query failed with code 82 because it could not locate Git; this is not a claim that a fresh native session lacks the owner-reported user PATH entry. Git >=2.56's documented `ucrt64/bin` transition must not become a fallback chain. Neo DLL/restart precedes document input registration. No automatic Administrator script/service operation belongs in user apply.

## Open acceptance risks

Source/fixture gates do not prove standard-user installers, npm/LSP compatibility, native OMP annotation listener cleanup, real Tern/Zed/Fork behavior, network/node/SSH cutover or reboot recovery. Those remain the owner-attended tasks in sections 6–8, not deferred implementation in this source unit. Mac LaTeX/TexLab uses project-owned workflows on the Mac; no native MiKTeX/TexLab/nixd/Roslyn or WSL fallback is introduced. Retain local recovery backups/accepted binaries/generations until those gates pass.

## Wave 2 review regression proof

Wave 2 moved all listed user-file writers into `home/` and removed the legacy Nix renderer/checker packages and their wiring. The WinGet AltSnap resource retains installer payloads, not INI settings. The earlier handoff list above records the migration boundary, not current competing ownership.

Before verification of the corrections, current standalone fixtures were executed against an immutable `git archive` snapshot of PR #67 revision `e13d06f7dff9080e98742ed130d516d563748b99`. Each requested regression failed against that original source:

| Fixture / case                               | Observed pre-fix failure                                                                                 |
| -------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `checkout-regressions.ps1`                   | Real `core.autocrlf=true` clone changed the pinned Zed asset SHA-256                                     |
| `checkout-regressions.ps1 -Case Interpreter` | Rendered Windows init did not declare the required built-in PowerShell interpreter                       |
| `app-regressions.ps1 -Case AltSnap`          | UTF-16LE BOM was not retained                                                                            |
| `app-regressions.ps1 -Case PowerToys`        | Restart list included child processes rather than only the canonical runner                              |
| `app-regressions.ps1 -Case Path`             | Original helper lacked the narrow registry/message seams needed to preserve and test raw expandable PATH |
| `wsl-hook-regressions.ps1`                   | Bare `wslpath` was unavailable under the modeled WSL exec PATH (exit 127)                                |
| `archive-regressions.ps1`                    | Archive extraction selected fake PATH `tar.exe` rather than the inbox absolute executable                |

The baseline cases ran with Linux PowerShell 7; AltSnap, PowerToys and PATH baseline failures were also reproduced with Windows PowerShell 5.1. Registry/process/message doubles never mutate the real profile or launch/stop real apps. Checkout fixtures clone isolated source snapshots, including a clone with spaces and Git line-ending conversion enabled. The AltSnap exception refines the former blanket UTF-8 rule: retain the existing INI encoding/BOM, while ordinary JSON/CSS/user.js remains UTF-8 without BOM. The runbook covers canonical-byte recovery for existing CRLF-converted clones and refreshing the persisted interpreter with init.

Actual Windows PowerShell 5.1 invoked the real same-checkout hook through `wsl.exe` on a disposable Windows-local clone whose path contains spaces. The absolute WSL bridge/bash transport, nonce proof, trusted host resolution of the checkout-declared Nix implementation and pinned `nix fmt -- --fail-on-change` returned zero. This was read-only with respect to the workstation/repository outside that disposable clone; it installed/configured no Windows tool or service and applied no user files. The first real attempts exposed duplicate System32/WindowsApps command discovery and WSL's quoted-option parsing; first-match executable selection and quoting only necessary argument values correct those boundaries, with fixture assertions.

The corrected full `windows/check.ps1` suite returned zero under Windows PowerShell 5.1 and Linux PowerShell 7, including rendered production-interpreter configuration, ASTs, isolated repeated app apply/verify, UTF-16LE drift/BOM preservation, canonical PowerToys restart, raw expandable PATH and message doubles, clone-byte pins, fake-PATH tar and WSL transport regressions. Windows used a temporary checksum-verified official chezmoi 2.73.0 binary, not a live installation. The Linux native development formatting/bootstrap/hook fixture suites also passed. The sequential release gates (`nix fmt -- --fail-on-change`, strict OpenSpec validation, host flake check and all-systems flake check) returned zero; all-systems evaluates foreign outputs and does not by itself prove a Darwin build.

The revised `checks.aarch64-darwin.macbook-pro-chezmoi` was then explicitly built with `nix build .#checks.aarch64-darwin.macbook-pro-chezmoi --no-link --print-build-logs`; logs show the successful actual build on `ssh-ng://glockyco@macbook-pro`. No host activation was performed.

### Hosted Windows stdin preamble regression

PR #67 run `37710458597` failed the standalone AltSnap BOM assertion on Windows PowerShell `5.1.26100.33438`, after the ordinary app apply/verify fixtures passed. A real Git-for-Windows clone of revision `0f9899b` with `core.autocrlf=true` into a Windows-local directory containing spaces passed on local `5.1.26100.9444`; the difference was reproduced deterministically by giving the parent console BOM-bearing UTF-8 input encoding. Before the transport fix, stdout began `EF-BB-BF-EF-BF-BD-EF-BF-BD-5B-00-47-00-65-00-6E` (248 bytes), with empty stderr.

The fixture's .NET Framework redirected-stdin `AutoFlush` writer emitted its inherited encoding preamble before the raw `BaseStream.Write`, prepending a UTF-8 BOM to the intended UTF-16LE payload. The production filter correctly interpreted those supplied bytes; stripping or overriding its BOM detection would hide transport corruption. The fixture now constructs the redirected input writer with BOMless UTF-8 and immediately restores the caller's console encoding. Its AltSnap case deliberately uses the problematic parent encoding, preserves binary stdout/stderr diagnostics on failure, and passes on both local Windows PowerShell 5.1 and Linux PowerShell 7. This changes fixture transport only, not application encoding policy or live user state.

### PowerShell 7 to Desktop interpreter boundary

Run `37713556480` passed the complete Windows PowerShell 5.1 leg after the stdin fix, then exposed a separate PowerShell 7.6.6 failure: chezmoi's configured `powershell.exe` could not discover `Get-FileHash`. An isolated, SHA-verified portable Windows PowerShell 7.6.6 reproduced it with a `ProcessStartInfo` child inheriting Core's `PSModulePath`; removing that variable from the child restored Desktop defaults and `Microsoft.PowerShell.Utility`.

The new core regression explicitly launches real chezmoi through PowerShell 7 into the persisted Windows PowerShell interpreter, against a disposable WinGet double and paths with spaces. With the new fixture but revision `cebc048`'s unmodified entry-point templates in a real Windows-local `core.autocrlf=true` clone, it failed with the same missing `Get-FileHash`, before the later shared-prelude assertions. The corrected shared prelude rebuilds only Desktop's process environment from its own modules, Windows PowerShell defaults and persisted user/machine paths; Core is unchanged. Every Windows entry-point template includes it before module cmdlets, and fixtures assert both that ordering and the module path actually seen by the native child. Inline fixture evaluations restore the caller's `PSModulePath`; no real user/machine environment value, shell profile, package, service or application is changed.

Run `37716661716` passed macOS/Linux and reached the Windows interpreter-boundary fixture, where the runner exposed both locked and preinstalled `pwsh` applications to `Get-Command`. The fixture had coerced their combined `.Source` values into one invalid executable name. Native application discovery now selects the first PATH-resolved application explicitly; the fixture appends a second failing `pwsh.cmd` candidate and requires multiple matches, so only the intended first runtime can be invoked. This changes the regression harness, not the production module prelude or any gate policy.

## Owner application-state decisions (2026-10-08)

Before the owner's first native Windows apply, read-only inspection of `%LOCALAPPDATA%\Microsoft\PowerToys\settings.json` established the chosen enabled map. The declaration now matches all 35 live module keys and values exactly: AlwaysOnTop, Awake, CmdPal, ColorPicker, FancyZones, File Explorer, File Locksmith, FindMyMouse, Image Resizer, Measure Tool, MouseHighlighter, Peek, PowerRename and Shortcut Guide are enabled; every other live module is disabled. The old `File Explorer Preview` declaration is omitted, rather than adding an absent obsolete module key to the live file.

Zed's `wsl_connections` is remembered-project UI state, not retired declaration-owned language-server wiring. Its removal is deleted; the removal helper remains necessary for the retired managed `lsp.nixd`, `lsp.texlab` and `agent_servers.omp` entries. Both isolated app convergence and the standalone Zed regression assert remembered WSL projects survive while those retired integrations are removed. No live application settings were written and no system activation was performed.

## Merged release and native bootstrap checkpoint (2026-10-08)

Owner-reported exercised results: PRs #67 and #68 merged with all four required checks green, including `check (windows-latest)`. The Linux/Darwin Nix release gates, native Windows PowerShell 5.1 and 7 gates, and hosted Windows gates passed. With owner authorization, the merged tailnet policy deployed successfully (run `37736626521`, `apply=success`) and protected main gained `check (windows-latest)` as a required check. These results complete tasks 1.1–5.5 and repository/publication gates 6.1–6.2; they do not prove live application or network cutover.

Native bootstrap (6.3): the checkout was cloned at `C:\Users\jglock\src\github.com\glockyco\nix-config`, chezmoi 2.73.0 installed per user, and `chezmoi init --promptString host=korolev` completed with its diff reviewed. Local backups at `%LOCALAPPDATA%\nix-config-cutover-20261008-0803` retain 420 files plus user PATH. The user PATH registry type was restored to `REG_EXPAND_SZ` after installers had converted it. No full user apply is claimed.

Partial 6.5: Tern 0.6.0 was copied from the spike folder into `%LOCALAPPDATA%\Programs\Tern`, with user PATH and Start-menu shortcut; it has not yet passed installation through the reviewed user setup and actual native terminal acceptance. Partial 6.6: official `install.ps1 -Binary -Ref v18.8.0` installed OMP 18.8.0, personal plugin 0.2.0 is installed, and the selected shell is per-user Git Bash. The owner logged in natively with the SCCH account preference. Plannotator is not yet installed natively, and these facts are not full provider/session acceptance.

PR #68 records the owner's current PowerToys module selection and preservation of Zed `wsl_connections`, as detailed above. Tasks 6.4–8.6 remain unchecked, including partial 6.5 and 6.6: approved input/restart/apply, native application/session/provider gates, network cutover and recovery, and final acceptance/archive have not been completed by this checkpoint.

## Tern launch, session daemon and OMP ownership (2026-10-09)

After a Windows shutdown and a Tern update, no session was restored. Observed causes, from `%LOCALAPPDATA%\Tern\Logs\tern.log`, `tern-daemon.log`, the System event log and the taskbar shortcut:

- The 12:26 loss was a Start-menu power-off (System event 1074), which ended the session daemon and WSL; it was not a Tern crash.
- The taskbar pin, created on 2026-10-07, targeted the spike `%TEMP%\tern-win-spike\tern\tern.exe`. Tern updates the executable it was started from, so the spike reached 0.7.0 while `%LOCALAPPDATA%\Programs\Tern` stayed at 0.6.0. The only daemon that ever held sessions (2026-10-07 to 2026-10-09) ran with `TERN_CONFIG_DIR` set to the spike's config directory, so its `daemon.state` was invisible to later default launches.
- Every window launch since then, from the spike pin, the Start-menu shortcut of the stable copy, or after an update (0.6.0, 0.6.3, 0.7.0), logged `session daemon unavailable; running programs in window`: the window first contacts the daemon it spawned 14–25 s after launch, but that daemon exits `idle` after 10 s. A manually started `tern daemon` with nothing to restore also exited after 10 s. Only a window started while a daemon was already running attached (`daemon attached` within 0.1 s).
- An isolated reproduction (own `TERN_CONFIG_DIR`, daemon socket and log directory, removed afterwards) confirmed: an attached window's tab survived closing the window; a daemon restoring two saved panes stayed up past 16 s with no window; **Restart session daemon** did not reattach a window that had fallen back.

Remediation: the stable 0.6.0 (`0e39682`) was retained as `%LOCALAPPDATA%\Programs\Tern-0.6.0-0e39682`, and the spike's 0.7.0 files were copied into `%LOCALAPPDATA%\Programs\Tern` with matching SHA-256 (`tern --version`: 0.7.0 `9ca00e4`). The owner removed the spike pin. The live session moved to a window of the stable build attached to the default daemon (`tern whoami` resolves the pane; `TERN_PANE_SOCKET=\\.\pipe\tern-JGlock`). The race is a Tern defect to report to Stencil; no repository workaround is added.

The owner chose Tern-managed OMP. Tern installed OMP 18.8.7 at `%LOCALAPPDATA%\Tern\omp\bin`, first on user PATH; the official-installer copy at `%LOCALAPPDATA%\omp` and its user PATH entry were removed (`REG_EXPAND_SZ` preserved). The resumed session runs `%LOCALAPPDATA%\Tern\omp\bin\omp.exe`; `omp plugin list` shows `personal@glockyco (0.2.0) (user)`. Tasks 6.5 and 6.6 remain open: the taskbar re-pin, a cold-launch daemon attach and the full native session gates are not yet exercised.

## Native document tool distribution review (2026-10-11)

Task 2.6 uses native user installations only. Read-only catalog selections were repeated with `winget show --id <ID> --exact --source winget --version <version> --scope user --architecture x64 --accept-source-agreements --disable-interactivity`: Poppler 25.07.0-0 and Pandoc 3.12.1 both exited **0**. The [Poppler manifest](https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/o/oschwartz10612/Poppler/25.07.0-0/oschwartz10612.Poppler.installer.yaml) selects portable ZIP SHA-256 `435e6265738470b7ae6498b8a298a4025bacb9349656207ef54d0f069687ce57`, with pdftotext/pdfinfo aliases and an employer-owned VC runtime prerequisite. The [Pandoc manifest](https://raw.githubusercontent.com/microsoft/winget-pkgs/master/manifests/j/JohnMacFarlane/Pandoc/3.12.1/JohnMacFarlane.Pandoc.installer.yaml) explicitly offers user-scope WiX MSI (`ALLUSERS=2`), SHA-256 `b6bf9f2c8408a1689272be5722e45f93ed9da17ba74321d0f7ef4e5a196605e8`. Its documented `APPLICATIONFOLDER` install-location switch grounds the explicit user `Programs\Pandoc` destination; no machine installer or dependency install was run.

The real Poppler ZIP was also hashed before temporary extraction, matching its catalog digest. Native `pdftotext.exe -v` and `pdfinfo.exe -v` both exited **0**, reporting `25.07.0` (the catalog's packaging revision is `-0`). Their version text is on stderr; the resource captures it with a locally restored PowerShell error preference and still checks the native exit code. Both executables, native versions and the exact catalog registration are required for convergence. The paths contained spaces, and the payload was removed (`POPPLER_TEMP_REMOVED=True`); no Poppler installation or persistent PATH change occurred.

Official GitHub release API metadata was read for [TexLab v5.26.0](https://api.github.com/repos/latex-lsp/texlab/releases/tags/v5.26.0), [QPDF v12.4.2](https://api.github.com/repos/qpdf/qpdf/releases/tags/v12.4.2) and [ImageMagick 7.1.2-33](https://api.github.com/repos/ImageMagick/ImageMagick/releases/tags/7.1.2-33). Each exact asset was downloaded into a native temporary directory whose path contained spaces, hashed with `Get-FileHash -Algorithm SHA256` **before** extraction and compared with the release asset digest:

| Asset                                           | Observed SHA-256                                                   | Native payload/version                                             |
| ----------------------------------------------- | ------------------------------------------------------------------ | ------------------------------------------------------------------ |
| `texlab-x86_64-windows.zip`                     | `cb028d44c3d2b85d36a2ed52d41a0ff43a341b1f04c500c56c4524c4eb72b316` | `texlab.exe --version`: `texlab 5.26.0`                            |
| `qpdf-12.4.2-msvc64.zip`                        | `db87077e683630c1217e0e8f9a20a9749d952ab676e881c3689187763a5de25d` | `qpdf-12.4.2-msvc64\bin\qpdf.exe --version`: `qpdf version 12.4.2` |
| `ImageMagick-7.1.2-33-portable-Q16-HDRI-x64.7z` | `61643fe060510984d801d3b139f12b61e30e71025a7dea604044d38af56a74be` | root `magick.exe -version`: `ImageMagick 7.1.2-33 Q16-HDRI x64`    |

The absolute inbox `%SystemRoot%\System32\tar.exe -xf <archive> -C <expanded>` extracted **all three** real archives with exit **0**, including ImageMagick's actual `.7z`; native version invocations also exited **0**. `tar.exe --version` reported `bsdtar 3.8.8`, `libarchive 3.8.8`. The temporary archives/extracted binaries were removed in `finally` (`TEMP_ARCHIVES_REMOVED=True`), with no installer, persistent PATH change, live package/apply or elevation. ImageMagick needs neither Intune's 7-Zip nor a repository-added extractor. Its exact revision is compared as four version components (`7.1.2.33`), not just `7.1.2`.

The [official install-tl profile reference](https://tug.org/texlive/doc/install-tl.html#PROFILES) documents every key in `windows/texlive.profile`: selected scheme, all seven path options, `instopt_adjustpath`, and the five `tlpdbopt_` options for documentation/source and Windows integration. The [option reference](https://tug.org/texlive/doc/install-tl.html#OPTIONS) documents `--non-admin` and that `--profile` ignores environment variables; therefore the profile has reviewed literal user paths rather than assumed variable expansion. The [official 2026 guide](https://tug.org/texlive/doc/texlive-en/texlive-en.html) identifies the current release; the runbook records the official standard-user installer, native tlmgr/latexmk/biber verification, explicit `tlmgr update --self --all` and yearly reinstall. **TeX Live was not downloaded or installed**; owner-run task 6.8 and actual native editor/project acceptance remain open.

## Bun native compatibility selection (2026-10-11)

Task 2.7 aligns the native Windows pin to **1.3.13** because Mac nixpkgs and personal-plugin development already select that version and the plugin requires its exact local Bun pin. No installed Bun is being downgraded. Read-only `winget show --id Oven-sh.Bun --exact --source winget --version 1.3.13 --scope user --architecture x64 --accept-source-agreements --disable-interactivity` exited **0**, selecting `https://github.com/oven-sh/bun/releases/download/bun-v1.3.13/bun-windows-x64.zip` with SHA-256 `85b14f3e0584218e9b63407b3aa6b90c4835ec5c32435c1f12cb6fc13667c7c9`. The document metadata, embedded test/set specification and active version lists use that selection; OMP remains Tern-managed, not Bun-global.

## Tasks 2.6/2.7 repository verification (2026-10-11)

After implementation and shared formatting, the canonical WSL checkout ran the required gates **sequentially**: `openspec validate make-korolev-windows-native --strict`, `nix fmt -- --fail-on-change`, and `nix flake check --print-build-logs`. Captured statuses were `OPENSPEC_EXIT=0`, `FORMAT_EXIT=0`, `FLAKE_CHECK_EXIT=0`; formatting reported zero changed files and the flake ran its 17 applicable Linux checks successfully. This is not a Darwin host execution claim.

The tools/profile/docs checkpoint is `24c7f23` (`feat(windows): add native LaTeX and document tools`); the Bun compatibility checkpoint is `d8ec55e` (`fix(windows): align Bun with the plugin toolchain`). Both commits ran WSL lefthook/treefmt with hooks enabled and no bypass. `personal_commit` supplied the structured-message previews; the integration owner's established WSL Git transport created the commits because the native tool has no WSL commit transport. Partially staged evidence exposed a trailing/section newline formatting failure at each first commit attempt; the ordinary formatter corrections were staged, and both successful attempts reported zero changed files. Neither commit was pushed.

A native throwaway clone required command-only `git -c safe.directory=//wsl.localhost/NixOS/home/user/src/github.com/glockyco/nix-config/.git` to trust the WSL source; no global trust setting was changed. The first long temporary name exceeded Windows checkout path limits. The retry used a short `%TEMP%\nxdoc-<suffix>` path and clone-local `core.longpaths=true`, preserving every source/test file rather than narrowing the checkout. The initial 600-second check wrapper expired before capturing a result, so it supplies no passing check evidence; the full native check was restarted with a longer deadline.

Read-only native `winget configure show --file .\windows\configuration.winget` successfully parsed the throwaway clone, including all five new tools and Bun 1.3.13, without applying any resource. Its display abbreviates inline scripts; the source resources remain intact. The full Windows PowerShell 5.1 check first failed after its schema/profile/metadata/privilege and WinGet fixture controls passed: the newly exact archive argument assertion found that the PowerShell function double retained an array-valued argument as one object, unlike a native application's expansion. `9aec769` corrects the double's native calling convention by expanding argument values; it retains the exact assertions and every negative control. The full host check is repeated after that correction, not skipped or narrowed.

The next full PowerShell 5.1 run passed every archive scenario (including all new tools and ImageMagick revision drift), checkout byte preservation, chezmoi core/apps and existing inbox-tar smoke checks, then exposed an unguarded optional `application` metadata read in the new standalone ImageMagick smoke test. `6d3d285` guards optional application metadata and WinGet-only policy in that strict-mode host; strict mode and all assertions remain enabled. The standalone `windows/tests/archive-regressions.ps1 -RepositoryRoot <native-clone>` then passed (exit 0): the actual 7z fixture extracted through absolute inbox `tar.exe` despite a fake `tar.exe` placed first on PATH. A fresh full check follows that correction; partial-run output is not a substitute for its final result.

The final complete `powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File .\windows\check.ps1` run on committed revision `6d3d285` **passed (exit 0, 823.71 seconds)** in the native throwaway clone. Terminal output included `PASS ImageMagick actual 7z extraction with absolute inbox tar and fake PATH tar first`, `PASS WSL hook absolute transport, host PATH, checkout proof and failure regressions`, and `windows/check.ps1: native document invariants and script parsing passed`. No fixture was skipped; existing negative controls, all five new tool resources, TeX profile validation, drift/hash/extraction/version/discovery, prior-directory preservation, paths with spaces and full native chezmoi/checkout/app/hook regressions ran. The throwaway clone was removed afterwards (`NATIVE_CLONE_REMOVED=True`, exit 0); distribution-download temporary directories were also removed.

Tasks **2.6 and 2.7 remain unchecked**: native PowerShell 7 is not installed locally, so the Windows CI `check (windows-latest)` job must exercise its PowerShell 7 leg after an owner-authorized push. No publication or native runtime installation is authorized by these source checks. TeX Live installation and real native editor/project smoke tests remain explicit owner-attended gates.

## Hosted PowerShell 7 leg and first live apply (2026-10-11)

PR #72 (merge `d8f8d60`) passed all required checks, including `check (windows-latest)` (30m26s) with its PowerShell 7 leg, so tasks 2.6 and 2.7 are complete.

The first owner-attended `chezmoi apply` on Korolev then stopped before changing anything: `winget configure` (WinGet v1.29.380) failed with `0x8A15C007` because `package native npm tools` declared `dependsOn` with the schema-required `[resourceId('Microsoft.DSC.Transitional/WindowsPowerShellScript', 'package javascript runtime')]`. Minimal documents reproduced it: `winget configure test` accepts the `resourceId()` form, but apply reports "dependency ... was not found" for it with or without spaces in names, and resolves only plain unit names, which the official DSC schema rejects. A five-unit probe showed apply runs units in document order. The document therefore declares no `dependsOn`; Node precedes the npm tools, and the native contract rejects any `dependsOn` and any npm resource ordered before the JavaScript runtime, with fixtures for both. Read-only `winget configure show`/`test` and the source checks had not exercised apply-time dependency resolution.
