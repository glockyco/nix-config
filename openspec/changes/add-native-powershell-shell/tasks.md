# Tasks

## 1. PowerShell Gallery module delivery

- [x] 1.1 Add a `psmodule` application variant to `windows/workstation.schema.json` with `name`, `kind`, `id`, `roles`, user-only `scope`, `versionPolicy`, `releaseVersion`, an `https://` `url` and `sha256`, following the archive variant's pinned-policy rules, and verify schema tests reject a module without `sha256` or with machine scope.
- [x] 1.2 Implement module test and set functions in `windows/Workstation.Delivery.ps1` and dispatch them from `windows/Workstation.psm1` as design.md describes, and verify Pester tests in `windows/tests/Workstation.Delivery.Tests.ps1` cover a missing module, a hash mismatch, a manifest version mismatch, a newer installed version and a dry run without download or write.
- [x] 1.3 Update the ownership table and the update section of `docs/operations/korolev-windows.md` for PowerShell modules and their release, URL and SHA-256 update path, and verify `pwsh -NoProfile -File .\windows\dev\format.ps1 -Check` passes.

## 2. Shell tool declarations

- [ ] 2.1 Declare `Starship.Starship` 1.26.0 as an archive from `starship-x86_64-pc-windows-msvc.zip` with its published SHA-256 below `Programs\starship`, and verify `pwsh -NoProfile -File .\windows\check-workstation.ps1 -StaticOnly` accepts it.
- [ ] 2.2 Declare `ajeetdsouza.zoxide` and `eza-community.eza` as user-scope WinGet `zip` packages with present policy and their executables, and verify the static check accepts them.
- [ ] 2.3 Declare PSFzf 2.7.12 and git-completion 2.0.0 as `psmodule` applications with their PowerShell Gallery package URLs and the package SHA-256 values reviewed for this change, and verify the static check accepts them.
- [ ] 2.4 Add the `prompt`, `directory-jumper`, `file-lister`, `picker-bindings` and `git-completion` roles to the required-role map in `windows/Workstation.Validation.ps1`, and verify validation tests fail on a missing role, on a role owned by another application and on a machine-scope Starship declaration.
- [ ] 2.5 Run `pwsh -NoProfile -File .\windows\dev\ci.ps1` and verify the declaration, mocked engine tests and chezmoi fixtures pass with the new applications.

## 3. Profile and shared configuration

- [ ] 3.1 In `home/.chezmoiignore`, stop ignoring `.config/starship.toml`, `.config/fzf` and `.config/eza` on Windows and ignore `Documents/PowerShell` on other platforms, and verify the Windows chezmoi fixture manages the three configuration paths.
- [ ] 3.2 Create `home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl` with the interactive guard, shared fzf commands and options file, eza theme directory, history size and leading-space handler, menu completion, deferred PSFzf bindings and Git completer, eza commands, Windows Terminal folder reporting, Starship initialization and zoxide initialization last, and verify the rendered profile passes the PowerShell 7 parser and PSScriptAnalyzer checks.
- [ ] 3.3 Extend `windows/tests/chezmoi-core.ps1` so the Windows fixture manages the profile, renders the shared history size and fzf commands from fixture data, and leaves prompt, key bindings, modules and environment unchanged when a non-interactive session runs the profile, and verify `ci.ps1` passes.
- [ ] 3.4 Cover the interactive path with a behavior test that loads PSReadLine and stubs `starship` and `zoxide`. Verify that it binds Tab, Ctrl+T, Ctrl+R and Alt+C, leaves PSFzf and git-completion unloaded, and returns `SkipAdding` for a leading-space line and `MemoryOnly` for a sensitive one.
- [ ] 3.5 Extend `checks/chezmoi-render-check.py` so the Mac fixture renders no `Documents/PowerShell` target and the Windows render manages the profile and the shared configuration files, and verify the check passes in the Nix checks.

## 4. Live acceptance

- [ ] 4.1 Run the README's Windows checks and `openspec validate add-native-powershell-shell --strict` from the PR branch, and record that they pass.
- [ ] 4.2 Run the workstation dry run and `chezmoi diff` on Korolev from the PR branch, and record that drift covers only the five new applications and the diff only the profile and the three configuration files.
- [ ] 4.3 Run `chezmoi apply` on Korolev, then record a zero-exit dry run, a passing `chezmoi verify --exclude=scripts` and that PowerShell 7's `$PROFILE` is the managed file.
- [ ] 4.4 In a fresh Tern session, verify the Mac Starship layout, `z` and `zi`, `ll`, menu Tab completion, `git switch` branch completion, Ctrl+T, Ctrl+R and Alt+C, no loaded PSFzf or git-completion at the first prompt, a leading-space command absent from history, and no folder sequence.
- [ ] 4.5 In Windows Terminal, verify the same prompt and that Ctrl+Shift+D opens the duplicated tab in the current folder.
- [ ] 4.6 Run `pwsh -Command '(Get-Module PSFzf, git-completion).Count; $env:FZF_DEFAULT_OPTS_FILE'` without `-NoProfile` and verify it prints `0` and an empty line.
- [ ] 4.7 Record the owner's confirmation that the Mac's Nix checks pass and that `chezmoi diff` on the Mac shows no PowerShell profile or zsh change.
