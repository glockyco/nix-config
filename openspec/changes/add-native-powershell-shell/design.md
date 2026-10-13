# Design

## Context

Korolev runs PowerShell 7.6 from the engine's per-user archive. Tern and Windows Terminal both start that `pwsh.exe` with the JetBrainsMonoNL Nerd Font, and no `$PROFILE` exists. On the Mac, `home/dot_zshrc.tmpl` wires Starship, zoxide, fzf and eza and reads the history size and fzf commands from the `portable` facts. `home/.chezmoiignore` keeps `.config/starship.toml`, `.config/fzf` and `.config/eza` off Windows.

The engine supports `winget`, `archive`, `npm` and `font` applications. Validation maps every role to exactly one application id, and only Zen, Tailscale and Docker Desktop may use machine scope. Starship's only WinGet installer is a per-machine WiX MSI.

A spike on Korolev on 2026-10-13 used a throwaway profile outside the repository and was removed afterwards. It showed that the shared `starship.toml` renders correctly in Windows Terminal. It also showed that PowerShell loads PSReadLine before `$PROFILE` only in interactive sessions, and it produced the timings under Risks.

## Goals / Non-Goals

**Goals:**

- One prompt configuration and one set of fzf, eza and history facts for zsh and PowerShell.
- Every new binary and module delivered by the engine in user scope from a reviewed integrity selection.
- A fast interactive start and no effect on non-interactive `pwsh` runs.

**Non-Goals:**

- Replacing PowerShell's `ls`, `dir`, `gci` or `cd`.
- Managing Tern or Windows Terminal settings, or a Windows PowerShell 5.1 profile.
- direnv, bat, Atuin or a terminal file manager on Windows.
- Automatic module upgrades.

## Decisions

### Starship rather than Oh My Posh

The Mac renders its prompt from `home/dot_config/starship.toml.tmpl`. Starship on Windows reads the same file from `~/.config/starship.toml`, so both machines show one prompt from one source. Oh My Posh installs per user through WinGet, but it would add a second prompt configuration to keep in step with the first.

### Starship as an archive application

The official `starship-x86_64-pc-windows-msvc.zip` contains only `starship.exe`. The `archive` kind already installs PowerShell and the GitHub CLI this way. It uses a reviewed URL and SHA-256, extracts below `%LOCALAPPDATA%\Programs`, checks the version through `--version` and adds the directory to the user PATH. The WinGet MSI would need a fourth machine-scope exception. zoxide and eza ship user-scope WinGet `zip` packages, like fzf and fd.

### A `psmodule` application kind

PSFzf and git-completion are distributed only through the PowerShell Gallery. A `psmodule` declaration uses the module name as `id` and adds `releaseVersion`, `url` and `sha256` for the reviewed `.nupkg`. The module root is `[Environment]::GetFolderPath('MyDocuments')\PowerShell\Modules`.

Test reads the highest manifest version below `<module root>\<id>` and accepts the reviewed or a newer version. Set downloads through the existing `Save-WorkstationDownload`, extracts into a work directory and removes the NuGet packaging entries (`_rels`, `package`, `[Content_Types].xml` and `<id>.nuspec`). It then checks the manifest's `ModuleVersion` and moves the result to `<module root>\<id>\<releaseVersion>`. It refuses to replace a newer version and never changes PATH.

Alternatives considered:

- `Install-PSResource` trusts the gallery at install time and has no hash pin, unlike every other delivery in `workstation.json`.
- Extending `archive` would need an executable, PATH handling and a root outside `LOCALAPPDATA` and `APPDATA`.
- Chezmoi externals would make chezmoi own installed code, but the engine owns installations.
- Vendoring the modules would bring third-party code and licences into the repository.

### Profile as a chezmoi template

`home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl` targets the PowerShell 7 current-user, current-host profile. It reads `portable.history.size` and the three `portable.fzf` commands and quotes them as single-quoted PowerShell strings, as `run_after_windows-tern-path.ps1.tmpl` does. Non-Windows hosts ignore the whole `Documents` tree, because chezmoi would otherwise manage the Mac's `~/Documents` directory and its private mode. The Windows ignore block stops listing `.config/starship.toml`, `.config/fzf` and `.config/eza`. The profile points `FZF_DEFAULT_OPTS_FILE` and `EZA_CONFIG_DIR` at those files.

### Interactive guard

The profile starts with `if (-not (Get-Module PSReadLine)) { return }`. PowerShell imports PSReadLine before `$PROFILE` only for an interactive console. The spike's temporary `$PROFILE` confirmed this for `pwsh -NoExit`, where PSReadLine was loaded, and for `pwsh -Command`, where it was not. The guard plays the role of the zsh `[[ -t 0 ]]` check and keeps engine, hook and agent runs of `pwsh -Command` free of prompt and module setup.

### Saved PATH entries

Right after the guard, the profile appends every saved machine and user PATH entry that the inherited PATH lacks. Tern's session daemon outlives window restarts and starts each shell with the environment from its own start, so tools from a later apply were missing until a reboot or a daemon restart. Restarting the daemon ends every running session. Windows Terminal reloads the environment for new tabs, which the merge leaves unchanged. Appending keeps the inherited entries first, and the merge runs in its own scope so it leaves no variables behind.

Alternatives considered: a runbook step to restart Tern only helps after a daemon restart that ends live sessions. Replacing PATH with the saved value would drop entries a parent added on purpose.

### Deferred loading

Ctrl+T, Ctrl+R and Alt+C start as small PSReadLine handlers. Each imports PSFzf globally, applies its chord options and calls the matching PSFzf handler, and PSFzf then replaces the placeholders with its own bindings. Git completion is a native argument completer for `git` that imports git-completion on first use. git-completion 2.0 needs this explicit registration anyway. Eager loading cost 0.40 s for PSFzf and 0.26 s for git-completion on every start.

### Line editing and history

Tab uses `MenuComplete`, which matches the zsh completion menu and shows git-completion's tooltips. Predictions keep PSReadLine's default inline view, which matches zsh-autosuggestions. `MaximumHistoryCount` comes from `portable.history.size`, and `HistoryNoDuplicates` mirrors the zsh duplicate options. An `AddToHistoryHandler` returns `SkipAdding` for lines that start with whitespace. Every other line goes to `GetDefaultAddToHistoryOption`, which keeps PSReadLine's sensitive-command filter.

### Listing commands

An `eza` function calls `eza.exe --icons auto --git`, and `ll`, `la`, `lla` and `lt` call that function as the zsh aliases do. `ls` stays the `Get-ChildItem` alias because PowerShell pipelines depend on its objects.

### Folder reporting and zoxide

`Invoke-Starship-PreCommand` writes OSC 9;9 with the current file-system path only when `WT_SESSION` is set. Windows Terminal uses it for duplicated tabs and panes. Other terminals may treat OSC 9 as a notification, so Tern receives nothing.

zoxide initializes last, as its documentation requires, and keeps `z` and `zi` instead of replacing `cd`. A replaced `cd` would turn a script's `cd` into a missing folder into a jump somewhere else instead of a failure.

### Roles

The new required roles are `prompt` for `Starship.Starship`, `directory-jumper` for `ajeetdsouza.zoxide`, `file-lister` for `eza-community.eza`, `picker-bindings` for `PSFzf` and `git-completion` for `git-completion`.

## Risks / Trade-offs

- Risk: an interactive start costs about 0.65 s for Starship and zoxide initialization, and each prompt about 0.2 s for the Starship process. Mitigation: deferred module loading. Tuning the prompt only for Windows would need a second Starship source.
- Risk: a redirected Documents folder, for example through OneDrive, would separate chezmoi's `Documents/PowerShell` target from `$PROFILE` and the module root. Mitigation: Korolev's Documents folder is local. Acceptance compares `$PROFILE` with the managed path, and the engine resolves the module root through the shell folder API.
- Risk: PowerShell Gallery package URLs redirect to a CDN. Mitigation: the SHA-256 check guards the content wherever it comes from.
- Risk: a 100 000-entry history file slows PSReadLine's startup read as it grows. Mitigation: the size is a shared fact, so one edit lowers it for both shells.
- Risk: the merge re-adds a saved entry that a parent removed on purpose, such as a deactivated virtual environment. Mitigation: it only runs in interactive sessions and appends after the inherited entries, so the parent's choices keep precedence.
- Risk: a module installed earlier by hand at the same path counts as present. Mitigation: only the reviewed or a newer version is desired, so an older copy is drift.

## Migration Plan

Apply follows the repository's Windows flow from the PR branch on Korolev: the workstation dry run, `chezmoi diff`, `chezmoi apply` and `chezmoi verify --exclude=scripts`. Then open a fresh Tern session and a Windows Terminal tab.

Neither the engine nor chezmoi removes what a reverted declaration leaves behind. To roll back, revert the change, delete the profile and the three configuration files, uninstall zoxide and eza with WinGet, and delete the Starship directory, its PATH entry and both module directories.
