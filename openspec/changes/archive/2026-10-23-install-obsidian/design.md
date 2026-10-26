# Design

## Context

The Mac installs GUI applications from Homebrew casks listed as application records in `home/.chezmoidata/hosts.toml`. `modules/fleet/host.nix` types the records, `homebrew.nix` derives the cask set and `defaults.nix` derives the Dock. Activation sets Homebrew's `upgrade = false`, so self-updating casks keep their vendor updates. The configuration sets no `allowUnfree` policy.

Korolev's engine installs WinGet packages in user scope from `windows/workstation.json`. A WinGet declaration with `executable` and `directory` resolves that file below `%LOCALAPPDATA%` and adds its directory to the user PATH. Startup programs are current-user Run values, as for AltSnap and ReNeo. `Workstation.Validation.ps1` maps each role to exactly one application id.

Obsidian's settings reference lists no option to start at sign-in. From installer 1.12.7 on, the Windows installation ships `Obsidian.com`, a terminal redirector for the command-line client, beside the GUI's `Obsidian.exe`. The Homebrew cask links `obsidian` to the bundle's `Contents/MacOS/obsidian-cli`. The command-line client works only while Obsidian runs with its command-line interface setting turned on.

The settings and `register-cli` code in Obsidian 1.14.4's `obsidian.asar` show how the setting and the registration relate. Turning on the setting stores it at once and then opens a dialog that offers registration with Register and Skip. Skip only closes the dialog. Register appends the installation directory to the user PATH on Windows unless an entry already names that directory. On macOS it asks for Administrator rights to create `/usr/local/bin/obsidian`.

A spike on Korolev with stand-in `Obsidian.com` and `Obsidian.exe` files showed that PowerShell 7 and OMP's bash resolve `obsidian` to `Obsidian.com`, following PATHEXT, while Bun's `Bun.which` returns `Obsidian.exe`.

## Goals / Non-Goals

**Goals:**

- One owner for each fact: the Mac's application record owns the cask, the bundle path and the login start.
- No Administrator step on Korolev and no second owner of `obsidian` on either PATH.
- Vendor updates for Obsidian and gitleaks, as for the other present applications.

**Non-Goals:**

- Obsidian's settings, vaults, Sync connection or plugins, and any Obsidian file in chezmoi.
- The vault, its Git repository and its commit hook.
- A Dock entry for Obsidian.
- Fixing programs that resolve `obsidian` through `Bun.which`.

## Decisions

### Vendor packages with vendor updates

The Mac uses the `obsidian` cask, which declares `auto_updates`, like Zed and the browsers. Korolev uses the `Obsidian.Obsidian` WinGet package, whose per-user installer writes `%LOCALAPPDATA%\Programs\Obsidian` without elevation, with present policy.

Alternatives considered: the nixpkgs `obsidian` package is unfree, so it would need an `allowUnfree` policy, and a store path cannot take Obsidian's own updates. A machine-scope WinGet installer would need a fourth elevation exception.

### Login start from the application record

A new boolean `startAtLogin` on Darwin application records requires `appPath`. A module in the desktop role turns each such record into a launchd user agent named after the bundle. The agent runs `/usr/bin/open -a <appPath>` with `RunAtLoad` and `LimitLoadToSessionType = "Aqua"`, so only a graphical login starts the application and LaunchServices starts it as an ordinary app. The shared-facts check fills the new field's default like the other optional fields. Korolev declares a Run value `Obsidian` with `"%LOCALAPPDATA%\Programs\Obsidian\Obsidian.exe"`, as for AltSnap.

nix-darwin loads a new or changed user agent during activation, and `RunAtLoad` then runs it once. Activation sets up user agents before the Homebrew bundle, so on the activation that first installs the cask the agent finds no bundle and exits with status 1. Obsidian then starts from the next login, or from `launchctl kickstart gui/$(id -u)/org.nixos.open-obsidian`. Unchanged agents are not reloaded.

Alternatives considered: a Login Item created through System Events or `SMAppService` is imperative state that a rollback does not remove. A dedicated Obsidian module would repeat the bundle path, which the record already owns. A Startup-folder shortcut on Windows would need a `.lnk` file that neither the engine nor chezmoi declares.

### Obsidian's command on PATH without its registration

On the Mac, the cask's link in Homebrew's `bin` is already on the PATH of fresh shells. The owner skips Obsidian's registration, so no root-owned link outside the configuration appears. On Korolev, the WinGet declaration names `Obsidian.com` in `Programs\Obsidian`, so the engine adds that directory to the user PATH and checks that the redirector exists. PATHEXT order then makes `obsidian` the redirector. The owner skips the registration there too. If it runs anyway, it finds the directory already on the user PATH and changes nothing.

### Roles

The new required roles are `notes` for `Obsidian.Obsidian` and `secret-scanner` for `Gitleaks.Gitleaks`.

### gitleaks on Korolev only

The vault's Git checkout exists only on Korolev, because Obsidian Sync skips hidden folders such as `.git`, so commits and their hook run there. lefthook already comes from the workstation, and the vault has no development environment of its own. The `Gitleaks.Gitleaks` package is a portable zip, declared like ripgrep.

Alternatives considered: a scanner delivered by the vault repository would need its own downloader and integrity pin. The Mac has no consumer.

### Superseded plan

The original knowledge-management plan chose a desktop-only vault in Git without a sync layer and allowed one community plugin. This change and the vault set up on top of it replace that decision. At acceptance, the plan was marked superseded and retained with the historical records because material such as the RemNote export had no reviewed replacement.

## Risks / Trade-offs

- Risk: Obsidian opens a window at every sign-in. Mitigation: none needed, because Sync runs only while Obsidian runs.
- Risk: a program that resolves `obsidian` through `Bun.which` on Windows starts the GUI's `Obsidian.exe` instead of the redirector. Mitigation: callers name `Obsidian.com`, and the operations guide says so. This repository does not patch such programs.
- Risk: Tern's session daemon keeps the environment from its own start, so a running session misses the new PATH entry. Mitigation: new interactive PowerShell sessions append saved PATH entries, and a restarted daemon has them.
- Risk: an Obsidian update changes the command-line client. Mitigation: Obsidian owns its updates, and `obsidian version` in a fresh shell is the acceptance check.

## Migration Plan

On Korolev from the PR branch: the README's Windows checks, the workstation dry run, `chezmoi diff`, `chezmoi apply` and `chezmoi verify --exclude=scripts`. Then a fresh PowerShell session resolves `obsidian` and `gitleaks`, the owner turns on the command-line interface and skips the registration, `obsidian version` answers, and the next sign-in starts Obsidian.

On the Mac: the Nix checks pass in CI, then `darwin-switch` runs in a terminal while the owner types the password. The agent is loaded, a fresh zsh resolves `obsidian` to the cask's link, the owner turns on the command-line interface and skips the registration, `obsidian version` answers, and the next login starts Obsidian.

Rollback: reverting removes the cask and the launchd agent on the next Mac activation and leaves Obsidian's data. On Korolev, neither the engine nor chezmoi removes what a reverted declaration leaves behind. Uninstall Obsidian and gitleaks with WinGet and delete the Run value and the PATH entry by hand.
