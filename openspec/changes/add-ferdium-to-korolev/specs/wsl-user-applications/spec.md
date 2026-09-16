## Purpose

Define how Korolev installs and updates graphical user applications through Nix while WSLg provides the native Windows display surface.

## ADDED Requirements

### Requirement: Declarative Ferdium installation

Korolev SHALL install Ferdium in the interactive user's Home Manager profile from the Nixpkgs package selected by the repository lock. The installation SHALL provide the Ferdium executable and desktop entry. The declaration SHALL NOT install Ferdium on the Darwin host or add it to the separately rendered Windows configuration.

#### Scenario: Activate Korolev

- **WHEN** the operator activates the reviewed Korolev configuration
- **THEN** the interactive user can resolve the declared Ferdium executable
- **AND** the user profile contains Ferdium's desktop entry

#### Scenario: Evaluate another platform

- **WHEN** the repository evaluates the Darwin and Windows configurations
- **THEN** neither configuration gains Ferdium from Korolev's declaration

### Requirement: Nix-owned executable updates

Nix SHALL own the Ferdium executable and application resources. Ferdium SHALL NOT replace its executable through an in-application updater. A Ferdium update SHALL arrive through a reviewed Nixpkgs input update and a new Korolev generation. Activating an older retained generation SHALL restore its Ferdium package version without a separate installer.

#### Scenario: A newer Ferdium package enters Nixpkgs

- **WHEN** the reviewed Nixpkgs lock advances to a newer Ferdium package and the operator activates the resulting Korolev generation
- **THEN** the user resolves the newer Ferdium executable
- **AND** activation does not use Ferdium's in-application updater

#### Scenario: Roll back the generation

- **WHEN** the operator rolls Korolev back to a retained generation with an older Ferdium package
- **THEN** the user resolves that generation's Ferdium executable
- **AND** no separate Ferdium downgrade runs

### Requirement: Mutable Ferdium profile boundary

Ferdium SHALL own its writable profile, configured services, account sessions, and cache under the user's home directory. Nix activation and rollback SHALL preserve that mutable state. Activation SHALL NOT authenticate an account, add a service, launch Ferdium, or delete profile data.

#### Scenario: Activate over an existing profile

- **WHEN** the operator activates Korolev after the user has configured Ferdium
- **THEN** the existing services and sessions remain in place
- **AND** activation does not start Ferdium

#### Scenario: Remove the declaration

- **WHEN** a later reviewed configuration removes Ferdium from the user profile
- **THEN** the executable and desktop entry leave the active generation
- **AND** the user's mutable Ferdium profile remains available for explicit recovery or deletion

### Requirement: WSLg launch behavior

The declared Ferdium package SHALL launch through Korolev's existing WSLg environment. The change SHALL NOT add a display server, desktop environment, background updater, or startup service.

#### Scenario: Launch Ferdium interactively

- **WHEN** the user starts Ferdium in a Korolev session with WSLg available
- **THEN** a usable Ferdium window opens on the Windows desktop
- **AND** the application reports the version selected by the active Nix generation

#### Scenario: Start a new Korolev session

- **WHEN** Korolev starts after Ferdium is installed
- **THEN** no repository-owned unit starts Ferdium automatically
