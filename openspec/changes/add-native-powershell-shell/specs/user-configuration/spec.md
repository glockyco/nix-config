## ADDED Requirements

### Requirement: Windows PowerShell profile ownership

Chezmoi SHALL own the PowerShell 7 current-user profile on native Windows hosts and SHALL render no PowerShell profile on other platforms. The profile SHALL configure only interactive sessions that run the PowerShell line editor. Other sessions, such as `pwsh -Command` runs, SHALL return from the profile before changing the prompt, key bindings, modules or environment.

#### Scenario: Run a non-interactive command

- **WHEN** a tool runs `pwsh -Command` without `-NoProfile`
- **THEN** the profile returns before changing the prompt, key bindings, modules or environment variables

#### Scenario: Apply on Korolev

- **WHEN** the standard user runs chezmoi apply on Korolev
- **THEN** the PowerShell 7 `$PROFILE` path holds the chezmoi-managed profile
- **AND** chezmoi verify reports no difference for it

#### Scenario: Render on the Mac

- **WHEN** the Mac applies the shared source
- **THEN** no PowerShell profile is written
- **AND** the zsh configuration is unchanged

### Requirement: Shared prompt and navigation in PowerShell

Interactive PowerShell sessions SHALL show the Starship prompt rendered from the one shared Starship configuration and SHALL provide zoxide directory jumping, menu Tab completion and Git command completion. Ctrl+T, Ctrl+R and Alt+C SHALL open fzf for paths, history and subdirectories, fed by the shared fd commands and the shared Catppuccin fzf options.

#### Scenario: Start an interactive session

- **WHEN** the user opens a PowerShell 7 session in Tern or Windows Terminal
- **THEN** the prompt shows the same segments and Catppuccin palette as the Mac's Starship prompt
- **AND** `z` and `zi` jump to previously visited folders

#### Scenario: Pick a subdirectory

- **WHEN** the user presses Alt+C and selects a directory
- **THEN** the session changes to that directory and the prompt updates

#### Scenario: Insert a path

- **WHEN** the user presses Ctrl+T and selects a file
- **THEN** its path is inserted at the cursor

#### Scenario: Complete a Git command

- **WHEN** the user presses Tab after `git sw` in a repository
- **THEN** completion offers `switch`
- **AND** completion after `git switch ` offers the repository's branches

#### Scenario: Change the shared fzf commands

- **WHEN** the shared fzf commands change
- **THEN** Mac zsh and the Windows profile use the new commands without a second literal edit

### Requirement: PowerShell listing aliases

Interactive PowerShell sessions SHALL provide `eza` with icons and Git status by default and the `ll`, `la`, `lla` and `lt` listing commands that zsh declares, using the shared eza theme. `ls`, `dir` and `gci` SHALL keep PowerShell's object-returning built-in behavior.

#### Scenario: List a repository

- **WHEN** the user runs `ll` in a Git repository
- **THEN** eza lists the folder with icons, the Catppuccin eza theme and a Git status column

#### Scenario: Pipe a built-in listing

- **WHEN** the user runs `ls *.txt | Remove-Item -WhatIf`
- **THEN** PowerShell passes file objects through the pipeline as it does without the profile

### Requirement: PowerShell history parity

Interactive PowerShell sessions SHALL keep the shared portable history size and SHALL NOT keep commands that start with a space in recall or the history file. Commands that PowerShell's line editor classifies as sensitive SHALL stay out of the history file.

#### Scenario: Keep a secret out of history

- **WHEN** the user runs a command that starts with a space
- **THEN** neither history recall nor the history file contains it

#### Scenario: Keep the sensitive-command filter

- **WHEN** the user runs a command with a password argument
- **THEN** the history file does not contain it

#### Scenario: Change the history size

- **WHEN** the shared portable history size changes
- **THEN** Mac zsh and the Windows profile use the new size without a second literal edit

### Requirement: Deferred PowerShell module loading

Interactive PowerShell sessions SHALL NOT import PSFzf or git-completion at startup. The first fzf key binding in a session SHALL import PSFzf before running its action, and the first Git completion SHALL import git-completion before completing.

#### Scenario: Start without the modules

- **WHEN** a new interactive session reaches its first prompt
- **THEN** neither PSFzf nor git-completion is loaded

#### Scenario: Use a binding first

- **WHEN** the user presses Ctrl+R in a new session
- **THEN** PSFzf loads and fzf opens over the history on that keypress

### Requirement: Windows Terminal folder reporting

Interactive PowerShell sessions in Windows Terminal SHALL report the current file-system folder with each prompt so that duplicated tabs and panes start there. Sessions outside Windows Terminal SHALL emit no folder report.

#### Scenario: Duplicate a tab

- **WHEN** the user changes folder and duplicates the Windows Terminal tab
- **THEN** the new tab starts in that folder

#### Scenario: Use another terminal

- **WHEN** a session runs in Tern
- **THEN** the prompt emits no Windows Terminal folder sequence

### Requirement: Saved PATH in long-lived terminals

Interactive PowerShell sessions SHALL append saved machine and user PATH entries that the inherited PATH lacks, so tools installed after a terminal daemon started resolve in its new sessions. Inherited entries SHALL keep their order and precedence. Sessions without the interactive line editor SHALL keep the inherited PATH unchanged.

#### Scenario: Open a tab from a terminal daemon started before an apply

- **WHEN** a Tern daemon that started before an apply opens a new PowerShell 7 session
- **THEN** the tools the apply installed resolve in that session
- **AND** the prompt renders without restarting the daemon

#### Scenario: Keep inherited precedence

- **WHEN** the inherited PATH already lists a directory ahead of the saved entries
- **THEN** that directory stays first and each saved entry appears once
