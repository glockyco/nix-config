## MODIFIED Requirements

### Requirement: Platform-owned OMP rollback

Mac Nix rollback SHALL restore Nix-managed paths without changing OMP, plugin selection or mutable state; Windows recovery SHALL use Tern and supported plugin releases, not Nix. Recovery SHALL retain accepted revisions/backups and never delete state used by running sessions. State SHALL not be copied across hosts except the explicitly bounded decision/model migration. A private WSL export SHALL be retained before unregister and restored only with owner approval.

#### Scenario: Roll back a Nix generation

- **WHEN** the owner restores a retained Mac Nix generation
- **THEN** its prior Nix package/configuration paths become active
- **AND** official OMP/plugin/state remain unchanged
- **AND** Windows recovery is not represented as a Nix rollback

#### Scenario: Recover an OMP release

- **WHEN** an authorized operator recovers an accepted OMP release through a supported Tern recovery flow on the requested host
- **THEN** a fresh session reports the recovered executable version
- **AND** application state remains in place
- **AND** personal-plugin and applicable host smokes are repeated

#### Scenario: No previous generation exists

- **WHEN** recovery lacks a retained Mac generation or accepted platform runtime/backup
- **THEN** the procedure names the missing prerequisite
- **AND** it invents no rollback result and deletes no user state

### Requirement: Bootstrap-era deployment removal

Accepted workstations SHALL contain no OMP wrapper, patched updater, patch pin, obsolete verifier/skill/shim, global package link or executable fallback. Nix/chezmoi SHALL not invoke OMP or manage Herdr integration. Tern delivery on Mac and native Korolev plus plugin-manager operations SHALL remain explicit. Removing Linux host tooling SHALL not remove Mac-required ordinary packages.

#### Scenario: Inspect the final workstation closure

- **WHEN** the final Mac closure and native Windows setup are inspected
- **THEN** both provide ordinary platform-native OpenSpec, Plannotator and supported language tools
- **AND** activation contains no OMP build/invocation, mutable checkout preparation or global link installation
- **AND** each default omp uses only its declared platform owner

### Requirement: Official standalone OMP distribution

Supported workstations SHALL use standalone upstream OMP outside Nix activation. Both the Mac and native Korolev SHALL use Tern-managed OMP as their declared installation. Nix SHALL provide no OMP wrapper, source updater, runtime plugin package or executable fallback. Both hosts SHALL install/upgrade the published personal plugin through OMP's user plugin manager and retain namespaced /personal:opsx-\* commands without legacy aliases.

#### Scenario: Install on either supported host

- **WHEN** the operator prepares OMP on macbook-pro or native Windows Korolev
- **THEN** the Mac and Korolev use Tern's managed upstream executable
- **AND** the plugin manager records the independently released personal plugin in writable user state
- **AND** no developer checkout or Nix runtime plugin path is required
- **AND** neither host installs a competing official-installer or Bun-global copy

### Requirement: Default upstream command

The default omp SHALL resolve to its platform-owned upstream executable in a fresh shell and preserve arguments/working directory. Personal behavior SHALL load once through the plugin manager without wrapper flags. Required ordinary tools SHALL resolve from Mac Nix packages or C3's native Windows tools, not a Linux launcher. Neither host SHALL declare a Zed OMP agent server.

#### Scenario: Resolve the installed command

- **WHEN** the user starts omp in a fresh shell after the platform setup
- **THEN** the Mac resolves $HOME/Library/Application Support/Tern/omp/bin/omp ahead of ~/.local/bin in non-interactive and interactive zsh shells, and Korolev resolves Tern's copy at %LOCALAPPDATA%\\Tern\\omp\\bin\\omp.exe
- **AND** personal@glockyco loads once through OMP's user plugin manager
- **AND** OpenSpec, Plannotator and applicable language servers resolve natively

#### Scenario: Inspect editor configuration

- **WHEN** Mac or Windows Zed settings are inspected after cutover
- **THEN** no repository-declared OMP agent server exists
- **AND** unrelated themes, keymaps and language-server settings remain unchanged

### Requirement: Explicit upstream executable updates

OMP updates SHALL remain explicit host operations outside activation: Tern's managed update flow on both hosts. Plugin upgrades SHALL use OMP's published marketplace/user-plugin commands. Neither operation SHALL require workstation patch pins or publication. Existing sessions SHALL not be interrupted automatically; acceptance SHALL use a fresh session on the observed installed version.

#### Scenario: Update the executable

- **WHEN** an authorized owner updates OMP through the platform's declared update flow
- **THEN** only that platform-owned executable installation is updated
- **AND** verification records its path and observed version in a new session
- **AND** Nix generations, authentication and session state remain outside update ownership

#### Scenario: Upgrade personal behavior

- **WHEN** the operator updates the marketplace and upgrades personal@glockyco in user scope
- **THEN** OMP's plugin manager upgrades the released plugin
- **AND** a fresh session verifies its released version and loaded capabilities
