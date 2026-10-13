# user-configuration Specification

## Purpose

Define single-owner portable user configuration and setup, shared machine facts, private encrypted credentials, and verifiable cutover/recovery across managed workstations.

## Requirements

### Requirement: One owner for each user destination

Chezmoi SHALL own managed user files and user setup from the repository's home source root; platform configuration SHALL own packages, system preferences and service definitions. Home Manager SHALL own no scope. App-owned mutable state, OMP state, private keys and project data SHALL remain outside whole-file replacement ownership.

#### Scenario: Inspect a managed host

- **WHEN** a workstation configuration is built and applied
- **THEN** every declared user destination has one owner
- **AND** the system closure contains no Home Manager integration or activation

#### Scenario: Render platform-specific setup

- **WHEN** the Linux host applies the shared source
- **THEN** no Darwin-only user file, setup helper or Mac credential is applied
- **AND** shared shell, Git and CLI configuration remains available

#### Scenario: Retain secondary workstation tools

- **WHEN** the Mac and WSL user configurations are built
- **THEN** Herdr remains in each system-declared user package set
- **AND** the Mac retains Ghostty's host-owned cask/Dock entry and chezmoi-owned settings/Catppuccin theme
- **AND** Herdr's OMP integration remains an explicit owner operation (`herdr integration install omp`); neither activation nor chezmoi manages `~/.omp`

### Requirement: Local source and machine selection

Each machine's chezmoi configuration SHALL record its checkout as sourceDir and an explicit data.host selection. The repository SHALL designate home as its source root. User destination directories SHALL remain outside the source directory; applying user configuration SHALL not require a second checkout or a host-name inference.

#### Scenario: Initialize an existing checkout

- **WHEN** the operator initializes chezmoi from the local repository
- **THEN** subsequent apply uses that checkout and the selected machine data
- **AND** initialization is separate from apply so planned changes can be inspected

#### Scenario: Windows and WSL share a machine name

- **WHEN** Windows and Linux select the same host key
- **THEN** platform-qualified facts select their distinct users and paths without mixing home directories

### Requirement: Shared facts have one declaration

Facts consumed by both Nix and chezmoi SHALL live in shared TOML source data. Nix SHALL read them with builtins.fromTOML and validate them through the typed host registry. Templates and checks SHALL read the same values; platform-only facts and derived values SHALL retain one explicit computation owner.

#### Scenario: Change a Git identity or user path

- **WHEN** the owner changes a shared host fact
- **THEN** Nix configuration, rendered user files and their checks consume the new value without a second literal edit

#### Scenario: Supply invalid host data

- **WHEN** shared data omits a required user identity or declares an invalid resource value
- **THEN** typed host evaluation or user initialization fails before applying that value

### Requirement: Preserve shell interaction boundaries

Platform program configuration SHALL own shell plugins while chezmoi SHALL own portable user history, prompt, options and hooks without duplicate plugin initialization. Fzf zsh integration SHALL run after completion only when stdin is a tty. Fresh Mac shells SHALL resolve system-declared user tools ahead of Homebrew and include the declared Tern CLI path.

#### Scenario: Interactive shell has no terminal

- **WHEN** an interactive login shell starts with stdin detached
- **THEN** the fzf hook is not executed and no zle option warning occurs

#### Scenario: Interactive shell has a terminal

- **WHEN** the user starts a fresh tty login shell
- **THEN** completion, autosuggestions, highlighting, Starship, direnv, zoxide and guarded fzf bindings are available once
- **AND** history sharing, secret-leading-space exclusion and package precedence match the declaration

### Requirement: Merge app-owned user files

Chezmoi modify templates SHALL reapply declared Zed and Karabiner settings while preserving undeclared app state. They SHALL leave writable regular files, preserve private Karabiner modes and fail without rewriting unreadable or malformed state. Repeated apply SHALL not append duplicate entries or rewrite unchanged content.

#### Scenario: Preserve a UI change

- **WHEN** Zed or Karabiner has undeclared settings or profiles added through its UI
- **THEN** apply preserves them while restoring the declared managed keys and rules

#### Scenario: Repeat the same apply

- **WHEN** app state already satisfies the declared managed values
- **THEN** content and modification times remain unchanged and managed rule entries are not duplicated

#### Scenario: App configuration cannot be parsed

- **WHEN** an existing app-owned file is malformed
- **THEN** apply fails visibly and leaves the original file intact

### Requirement: Private age credentials remain host-local

Managed credentials SHALL use chezmoi built-in age encryption and private source attributes, with decrypted files readable only by their intended user. The Mac SHALL reuse its existing age identity without committing or exporting it. Conversion SHALL occur on the Mac without plaintext entering repository files, Nix store, recorded output or another host. The persistent plaintext-at-rest trade-off SHALL be documented.

#### Scenario: Convert existing credentials

- **WHEN** the operator migrates the Fastmail, Cloudflare DNS and Cloudflare Workers tokens on the Mac
- **THEN** only ciphertext enters the source tree
- **AND** the existing identity decrypts all replacements before old ciphertext is retired

#### Scenario: Apply credentials and verify consumers

- **WHEN** the Mac applies its encrypted credential source
- **THEN** destination files have mode 0600 under a private directory
- **AND** Fastmail and the opt-in direnv helpers read the new paths without printing values

#### Scenario: Apply on another platform

- **WHEN** WSL or Windows applies user configuration without a separately enrolled key
- **THEN** Mac credential sources are excluded and no Mac token or private age identity is copied

### Requirement: System switch precedes user apply

The Mac switch command SHALL complete the system switch before invoking chezmoi apply as the ordinary user. WSL SHALL document the same ordered flow. System-switch failure SHALL prevent user apply; user-apply failure SHALL be visible as a partial operation, not reported as complete or hidden by automatic rollback.

#### Scenario: Switch succeeds

- **WHEN** an authorized host switch completes
- **THEN** user apply resolves helpers and resources from the selected system generation
- **AND** chezmoi runs without root ownership of user destinations

#### Scenario: A phase fails

- **WHEN** system switch or user apply fails
- **THEN** the operation exits unsuccessfully and identifies the failed phase
- **AND** retained generations and local backups remain available

### Requirement: User-file recovery is separate from system rollback

Recovery SHALL restore user files by applying a previous chezmoi source revision, and SHALL restore the previous system generation only when packages or system settings changed. Documentation SHALL NOT describe a system rollback as restoring chezmoi destinations. Recovery SHALL leave unrelated mutable state untouched, including OMP state, Colima data, project repositories and private keys.

#### Scenario: Reject a user-file change

- **WHEN** live verification rejects a chezmoi source change
- **THEN** the operator applies the previous source revision
- **AND** the managed destinations match that revision

#### Scenario: Roll back a system generation

- **WHEN** the operator selects the previous system generation
- **THEN** managed user files stay unchanged until a chezmoi source revision is applied
- **AND** OMP state, Colima data, project repositories and private keys remain intact

### Requirement: Acceptance proves actual consumer behavior

A user-configuration change SHALL be accepted only after builds/checks on both supported systems, chezmoi verify on each affected host and actual consumer smokes. Mac activation SHALL run in an agent terminal with the owner typing any sudo password; agents SHALL not obtain that password. Publication and merges SHALL require explicit owner authorization.

#### Scenario: Accept both live hosts

- **WHEN** the reviewed source has been applied on Mac and WSL
- **THEN** shell, Git identity, SSH endpoints and applicable credential consumers pass
- **AND** Mac keyboard, Karabiner, default apps, screenshot destination and Colima profile pass live checks
- **AND** both hosts pass chezmoi verify and repeated apply without unexpected writes

#### Scenario: Static checks pass without live access

- **WHEN** only evaluation, builds and sandbox checks have passed
- **THEN** the change remains unaccepted until owner-assisted live activation and consumer verification finish

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
