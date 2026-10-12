# Korolev Windows

Korolev is a Windows 11 laptop managed by the employer through Intune. Work as the standard user `scch\jglock`. Administrator credentials are only typed into the prompts named below.

## What owns what

| Source                     | Owns                                                           |
| -------------------------- | -------------------------------------------------------------- |
| `windows/workstation.json` | Applications, their versions and user settings                 |
| `windows/npm/`             | Native language servers and OpenSpec, locked by npm            |
| `windows/Workstation.psm1` | The engine that tests and applies `workstation.json`           |
| `home/`                    | User files and app settings, applied by chezmoi                |
| `windows/apply-*.ps1`      | The only Administrator operations: Neo, Zen policies and SSH   |
| Applications themselves    | Profiles, credentials, sessions and anything not declared here |

`chezmoi apply` runs the engine first and then writes user files. Run the engine directly to see what differs without changing anything:

```powershell
pwsh -NoProfile -File .\windows\workstation.ps1 -DryRun
```

It prints one `desired:` or `drift:` line per resource and exits 0 when everything is in place, 1 on drift and 2 on errors.

## Set up a new machine

1. In Windows PowerShell, install PowerShell 7, Git and chezmoi for the current user. The script never elevates.

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\bootstrap.ps1
   ```

1. In PowerShell 7, clone the repository and initialize chezmoi. Select `korolev` when asked for the host.

   ```powershell
   $checkout = Join-Path $HOME 'src\github.com\glockyco\nix-config'
   git clone https://github.com/glockyco/nix-config.git $checkout
   Set-Location $checkout
   chezmoi init --source $checkout
   ```

1. Install the Neo keyboard driver. In an Administrator PowerShell 7, run `pwsh -NoProfile -File <checkout>\windows\apply-kbdneo.ps1`, then restart Windows.

1. Back in the standard-user shell, review and apply:

   ```powershell
   chezmoi diff
   chezmoi apply
   chezmoi verify --exclude=scripts
   ```

   Zen, Tailscale and Docker Desktop install for all users, so their installers ask for Administrator credentials. `verify` excludes scripts because the app stop/restart and Tern PATH scripts run on every apply.

1. After Zen is installed, run `pwsh -NoProfile -File <checkout>\windows\apply-zen-policies.ps1` in an Administrator PowerShell 7. The Administrator scripts accept `-Test` to check without changing anything.

1. Sign out and back in. Windows then picks up the UI language, input methods and the ReNeo launcher. ReNeo asks for Administrator credentials at every sign-in.

1. Finish the steps that stay manual:

   - Start Docker Desktop once and accept its subscription agreement.
   - Create a Zen profile, then run `chezmoi apply` again to install its theme.
   - Install Tern, OMP, the plugins and Plannotator as described below.
   - Install TeX Live as described below.
   - Enroll Tailscale and set up SSH as described in [Korolev remote access](korolev-remote-access.md).
   - Sign in to GitHub (`gh auth login --web --git-protocol https`), GitLab and Overleaf. Git Credential Manager stores the tokens.

## Keyboard layouts

German QWERTZ stays first and Neo second. Office derives its shortcuts from the first layout, so Neo first breaks copy and paste there. The UAC prompt only accepts QWERTZ and the Neo base layer, so switch to `Deutsch (Neo)` with `Win+Space` before typing a password there.

## Tern, OMP and Plannotator

Install Tern from the Stencil download page into `%LOCALAPPDATA%\Programs\Tern` and start it only through its Start-menu shortcut. Tern updates the executable it was started from. Accept Tern's offer to install OMP, or run Install omp from its command palette. Tern then keeps OMP current. Then install the plugins and Plannotator:

```powershell
omp plugin marketplace add glockyco/omp-agent-setup
omp plugin install --scope user personal@glockyco
omp plugin marketplace add glockyco/omp-booking
omp plugin install --scope user booking@glockyco-booking
pwsh -NoProfile -Command { $env:PLANNOTATOR_MINIMAL = '1'; & ([scriptblock]::Create((Invoke-RestMethod https://plannotator.ai/install.ps1))) -Version v0.28.7 -VerifyAttestation }
```

Plannotator needs the environment variable because its installer ignores the `-Minimal` switch. Without minimal mode it also installs vendor skills and commands.

Update the plugins with `omp plugin marketplace update <marketplace>` followed by `omp plugin upgrade --scope user <plugin>`, then start a new session.

## TeX Live

TeX Live is installed by hand, once a year, into the user profile. Download `install-tl-windows.exe` from CTAN and run it with the reviewed profile:

```powershell
$installer = Join-Path $env:TEMP 'install-tl-windows.exe'
Invoke-WebRequest https://mirror.ctan.org/systems/texlive/tlnet/install-tl-windows.exe -OutFile $installer
& $installer --non-admin --profile (Resolve-Path .\windows\texlive.profile)
```

The profile contains literal paths for `jglock`. Update packages within a release year with `tlmgr update --self --all`. For the next year, update the year in the profile and install again.

## Change or update something

Applications without a version in `workstation.json` stay current through their own updater or `winget upgrade`. The engine installs them when missing and never downgrades them.

To change a pinned version, an archive or a setting, edit `workstation.json` and run the dry run, then `chezmoi apply`. Pins exist only where a named consumer needs a version. Bun follows `omp-agent-setup/.bun-version` and OpenSpec follows the omp-agent-setup workflow.

To update the npm tools, edit `windows/npm/package.json`, then run `npm install --package-lock-only --ignore-scripts` in `windows/npm`. The next apply reinstalls the closure with `npm ci` when the lock changes.

## When something goes wrong

Windows has no generations, so a failed apply can leave earlier changes in place. The engine stops at the first failure and never retries. Read the error, fix the cause and apply again. The dry run shows what is left.

To return to an earlier configuration, check out that revision and apply it. This changes only what the older revision declares. It does not uninstall applications or restore files, so repair those with the vendor's installer.

If an apply was interrupted while applications were stopped, `%LOCALAPPDATA%\WindowsConfiguration\chezmoi-app-restarts.json` lists them and the next apply refuses to start. Restart them with the after-script, then apply again:

```powershell
$restart = Join-Path $env:TEMP 'chezmoi-apps-restart.ps1'
chezmoi execute-template --file .\home\run_after_windows-apps-restart.ps1.tmpl --output $restart
pwsh -NoProfile -File $restart
```

## Left to Windows Settings

Default apps, taskbar pins and Night light (sunset to sunrise, 50%) are set by hand in Windows Settings. Windows protects them against scripted changes.
