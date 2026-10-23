# notes-application Specification

## Purpose

Provides Obsidian, the notes application, on both workstations, and the tools the notes vault's Git backup needs, while leaving Obsidian's own state to Obsidian.

## Requirements

### Requirement: Obsidian on both workstations

The Mac SHALL install Obsidian from its Homebrew cask. Korolev SHALL install the `Obsidian.Obsidian` WinGet package in the standard user's scope under the `notes` role. Neither SHALL pin a version, and Obsidian's own updater SHALL own updates. Installation on Korolev SHALL NOT request Administrator credentials.

#### Scenario: Install Obsidian

- **WHEN** the Mac activates or Korolev applies its declarations while Obsidian is missing
- **THEN** Obsidian is installed as a native application
- **AND** no step on Korolev requests Administrator credentials

#### Scenario: Keep a vendor update

- **WHEN** Obsidian has updated itself past the version that was first installed
- **THEN** the Korolev dry run reports it as desired
- **AND** neither Mac activation nor Korolev apply reinstalls or downgrades it

### Requirement: Obsidian starts at sign-in

Signing in to a graphical session SHALL start Obsidian on both workstations. The Mac SHALL derive the start from Obsidian's application record and SHALL load it only in the graphical login session. Korolev SHALL declare the start as a current-user Run value.

#### Scenario: Sign in

- **WHEN** the user signs in to the graphical session of either workstation
- **THEN** Obsidian starts without further action

#### Scenario: Open a terminal session on the Mac

- **WHEN** the user logs in to the Mac over SSH without a graphical session
- **THEN** the login does not start Obsidian

### Requirement: Obsidian command on PATH

A fresh interactive shell on both workstations SHALL resolve `obsidian` to Obsidian's command-line client: on the Mac the command that the cask links, on Korolev the `Obsidian.com` terminal redirector in the installation directory, which the engine adds to the user PATH. The configuration SHALL NOT depend on Obsidian's own command registration.

#### Scenario: Query a running Obsidian

- **WHEN** Obsidian runs with its command-line interface turned on, and a fresh zsh on the Mac or a fresh PowerShell 7 session on Korolev runs `obsidian version`
- **THEN** the command prints Obsidian's version
- **AND** the resolved command is the cask's link on the Mac and `Obsidian.com` on Korolev

#### Scenario: Resolve without Obsidian's registration

- **WHEN** Obsidian's own command registration has not run
- **THEN** a fresh shell on either workstation still resolves `obsidian` as above

### Requirement: Obsidian-owned state

Obsidian SHALL own its account sign-in, vault registry, Sync connection, application and vault settings, its command-line interface setting and its community plugins. Activation and apply SHALL NOT write, copy or reset that state. Turning on the command-line interface SHALL remain an owner step on each machine.

#### Scenario: Apply over a configured Obsidian

- **WHEN** the Mac activates or Korolev applies after the owner configured Obsidian
- **THEN** Obsidian's account, vaults, Sync connection, settings and plugins are unchanged

#### Scenario: Remove the declaration

- **WHEN** a later reviewed configuration removes Obsidian
- **THEN** the vault folders and Obsidian's settings remain in place
- **AND** deleting them stays an explicit owner operation

### Requirement: Secret scanner on Korolev

Korolev SHALL install the `Gitleaks.Gitleaks` WinGet package in the standard user's scope under the `secret-scanner` role with present policy, so that Git hooks can run `gitleaks` from PATH. Installation SHALL NOT request Administrator credentials.

#### Scenario: Run the scanner in a fresh shell

- **WHEN** a fresh PowerShell 7 session or a Git hook on Korolev runs `gitleaks version` after apply
- **THEN** it prints the installed version
- **AND** no step requested Administrator credentials
