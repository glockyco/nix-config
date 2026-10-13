# Proposal

## Why

Korolev's PowerShell 7 sessions in Tern and Windows Terminal start without a profile. They lack the prompt, directory jumping, fuzzy pickers and listing aliases that this repository gives the Mac's zsh, so folder navigation stays manual. The shared Starship, fzf and eza configuration already exists, but `home/.chezmoiignore` withholds it from Windows and the workstation engine cannot deliver PowerShell Gallery modules.

## What Changes

- Declare Starship as a user-scope `archive` application from its official release zip, and zoxide and eza as user-scope WinGet packages, each with its own role.
- Add a `psmodule` application kind to the workstation schema, validation and engine. It installs a reviewed PowerShell Gallery package, identified by version and SHA-256, into the PowerShell 7 current-user module path. Declare PSFzf and git-completion with it.
- Add a chezmoi-owned PowerShell 7 profile for Windows. It provides the shared Starship prompt, zoxide, fzf bindings fed by the shared fd commands and Catppuccin options, menu Tab completion and Git completion. It also provides the zsh eza aliases except `ls`, the shared history size and leading-space history exclusion. PSFzf and git-completion load on first use. Non-interactive sessions skip the profile, and Windows Terminal learns the current folder.
- Deploy `.config/starship.toml`, `.config/fzf` and `.config/eza` on Windows, and ignore the new profile on other platforms.
- Extend the Windows declaration, engine and chezmoi tests, and update the Korolev runbook for the new module kind, the update path and profile ownership.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `windows-workstation-layer`: add the declared native shell tools and PowerShell Gallery module delivery.
- `user-configuration`: add PowerShell interaction parity for the chezmoi-owned Windows profile.

## Impact

Targets `windows/workstation.json`, `windows/workstation.schema.json`, `windows/Workstation.psm1`, `windows/Workstation.Delivery.ps1`, `windows/Workstation.Validation.ps1`, `windows/tests/`, `home/.chezmoiignore`, a new profile template under `home/Documents/PowerShell/`, `checks/chezmoi-render-check.py` and `docs/operations/korolev-windows.md`.

Apply runs as the standard user without elevation. It downloads Starship from its GitHub release and the two modules from the PowerShell Gallery. The Mac's zsh, Starship configuration and Nix packages are unchanged.

A spike on Korolev measured about 0.65 s of profile startup with lazy module loading, against 2.1 s when every module loads eagerly. The change only adds requirements, so it does not touch requirements that `make-korolev-windows-native` or `retire-korolev-wsl-host` modify.
