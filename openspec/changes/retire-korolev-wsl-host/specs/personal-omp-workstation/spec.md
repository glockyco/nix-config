# Spec Delta

## MODIFIED Requirements

### Requirement: Official standalone OMP distribution

Supported workstations SHALL use standalone upstream OMP outside Nix activation. The Mac SHALL retain the official platform installer; native Korolev SHALL use Tern-managed OMP as its sole installation. Nix SHALL provide no OMP wrapper, source updater, runtime plugin package or executable fallback. Both hosts SHALL install/upgrade the published personal plugin through OMP's user plugin manager and retain namespaced /personal:opsx-\* commands without legacy aliases.

#### Scenario: Install on either supported host

- **WHEN** the operator prepares OMP on macbook-pro or native Windows Korolev
- **THEN** the Mac uses its official native standalone installation and Korolev uses Tern's managed omp.exe
- **AND** the plugin manager records the independently released personal plugin in writable user state
- **AND** no developer checkout or Nix runtime plugin path is required
- **AND** Korolev adds no competing official-installer or Bun-global copy

### Requirement: Default upstream command

The default omp SHALL resolve to its platform-owned upstream executable in a fresh shell and preserve arguments/working directory. Personal behavior SHALL load once through the plugin manager without wrapper flags. Required ordinary tools SHALL resolve from Mac Nix packages or C3's native Windows tools, not a Linux launcher. Neither host SHALL declare a Zed OMP agent server.

#### Scenario: Resolve the installed command

- **WHEN** the user starts omp in a fresh shell after the platform setup
- **THEN** the Mac resolves its official installation and Korolev resolves Tern's copy at %LOCALAPPDATA%\\Tern\\omp\\bin\\omp.exe
- **AND** personal@glockyco loads once through OMP's user plugin manager
- **AND** OpenSpec, Plannotator and applicable language servers resolve natively

#### Scenario: Inspect editor configuration

- **WHEN** Mac or Windows Zed settings are inspected after cutover
- **THEN** no repository-declared OMP agent server exists
- **AND** unrelated themes, keymaps and language-server settings remain unchanged

### Requirement: Explicit upstream executable updates

OMP updates SHALL remain explicit host operations outside activation: omp update for the Mac's official installation and Tern's managed update flow on Korolev. Plugin upgrades SHALL use OMP's published marketplace/user-plugin commands. Neither operation SHALL require workstation patch pins or publication. Existing sessions SHALL not be interrupted automatically; acceptance SHALL use a fresh session on the observed installed version.

#### Scenario: Update the executable

- **WHEN** an authorized owner updates OMP through the platform's declared update flow
- **THEN** only that platform-owned executable installation is updated
- **AND** verification records its path and observed version in a new session
- **AND** Nix generations, authentication and session state remain outside update ownership

#### Scenario: Upgrade personal behavior

- **WHEN** the operator updates the marketplace and upgrades personal@glockyco in user scope
- **THEN** OMP's plugin manager upgrades the released plugin
- **AND** a fresh session verifies its released version and loaded capabilities

### Requirement: Tern terminal delivery

Tern SHALL remain the primary interactive OMP terminal on Mac and native Windows Korolev. The Mac SHALL retain its manual self-updating bundle, CLI PATH and Dock pin plus secondary Ghostty and Herdr. Korolev SHALL retain C3's native Tern/OMP ownership without a Linux session dependency. Activation SHALL not manage Herdr's OMP integration; owner installation remains explicit on the Mac.

#### Scenario: Activate the Mac terminal cutover

- **WHEN** reviewed Mac configuration activates after upstream OMP/plugin verification
- **THEN** Tern remains primary with its Dock entry and declared CLI path
- **AND** Ghostty and Herdr remain installed
- **AND** activation does not touch Herdr's OMP integration

#### Scenario: Start native Korolev work

- **WHEN** the owner starts a new interactive project session in Tern on Korolev
- **THEN** it runs native Windows OMP against the stable native checkout
- **AND** it requires no NixOS distribution or Linux terminal pane

### Requirement: Mutable runtime state boundary

Configuration/activation SHALL preserve writable OMP and plugin-manager state and SHALL not replace it with store symlinks or reconcile its registry. Cross-platform transfer SHALL be limited to architecture.md, product.md and style.md after source sessions finish, with owner reconciliation into exact-path native sharpshooter banks, plus the nonsecret litellm model definition. Authentication/session databases, browser profiles, queue and state.json SHALL never be imported.

#### Scenario: Activate over an existing OMP profile

- **WHEN** workstation configuration activates on a host with existing OMP runtime state
- **THEN** authentication, configuration, sessions, history and caches remain at their mutable paths
- **AND** activation does not overwrite or delete those files

#### Scenario: Port project decisions after sessions finish

- **WHEN** a project's WSL sessions have ended and the owner approves its decision migration
- **THEN** only architecture.md, product.md and style.md are copied or reconciled into the bank computed from the exact resolved native checkout path
- **AND** a fresh native session discovers those decisions
- **AND** queue, state.json, transcripts and authentication/session databases are not imported

#### Scenario: Reproduce nonsecret provider configuration

- **WHEN** the owner prepares Windows models.yml for the migrated SCCH provider
- **THEN** it defines litellm with baseUrl https://vllm-api.scch.at/v1 while preserving other native definitions
- **AND** the owner establishes authentication natively, without copying secrets or authentication files

### Requirement: Representative language-server matrix

The Mac SHALL retain its declared C#, Python, TypeScript/JavaScript, Svelte, Nix, Markdown and LaTeX/BibTeX servers. Native Korolev SHALL use C3's Windows language/document tools, including native TexLab, with no nixd or C#/Unity server for this role. Project SDKs SHALL remain project-owned. Plugin overrides SHALL select only the intended primary server/root behavior; no server SHALL resolve through the retired Linux environment.

#### Scenario: Exercise the matrix

- **WHEN** language smoke checks run against representative projects on each supported host
- **THEN** each server in that host's matrix starts natively
- **AND** diagnostics are requested for each supported language
- **AND** definition, references and rename are exercised where supported
- **AND** a missing or failed supported server fails rather than being reported as a warning
- **AND** Korolev installs/launches no Mac-only Nix or C#/Unity server

### Requirement: Activation proof through a real session

Workstation support SHALL require a real upstream OMP session in Tern in a disposable local repository on Mac and native Windows Korolev. Evidence SHALL identify each platform-owned executable and plugin installation. A former Linux session or static package check SHALL not satisfy native Windows acceptance.

#### Scenario: Verify personal behavior after activation

- **WHEN** the real host-local smoke session inspects its plugin and performs a harmless preview
- **THEN** it reports the plugin-manager path and released version
- **AND** personal policy is active and personal_commit is registered
- **AND** preview does not mutate repository state
- **AND** native Windows annotation acceptance uses the released support-native-windows plugin

### Requirement: Platform-owned OMP rollback

Mac Nix rollback SHALL restore Nix-managed paths without changing OMP, plugin selection or mutable state; Windows recovery SHALL use Tern and supported plugin releases, not Nix. Recovery SHALL retain accepted revisions/backups and never delete state used by running sessions. State SHALL not be copied across hosts except the explicitly bounded decision/model migration. A private WSL export SHALL be retained before unregister and restored only with owner approval.

#### Scenario: Roll back a Nix generation

- **WHEN** the owner restores a retained Mac Nix generation
- **THEN** its prior Nix package/configuration paths become active
- **AND** official OMP/plugin/state remain unchanged
- **AND** Windows recovery is not represented as a Nix rollback

#### Scenario: Recover an OMP release

- **WHEN** an authorized operator recovers an accepted OMP release through the Mac installer or Windows Tern flow
- **THEN** a fresh session reports the recovered executable version
- **AND** application state remains in place
- **AND** personal-plugin and applicable host smokes are repeated

#### Scenario: No previous generation exists

- **WHEN** recovery lacks a retained Mac generation or accepted platform runtime/backup
- **THEN** the procedure names the missing prerequisite
- **AND** it invents no rollback result and deletes no user state

### Requirement: Bootstrap-era deployment removal

Accepted workstations SHALL contain no OMP wrapper, patched updater, patch pin, obsolete verifier/skill/shim, global package link or executable fallback. Nix/chezmoi SHALL not invoke OMP or manage Herdr integration. Mac official installation and native Korolev Tern delivery plus plugin-manager operations SHALL remain explicit. Removing Linux host tooling SHALL not remove Mac-required ordinary packages.

#### Scenario: Inspect the final workstation closure

- **WHEN** the final Mac closure and native Windows setup are inspected
- **THEN** both provide ordinary platform-native OpenSpec, Plannotator and supported language tools
- **AND** activation contains no OMP build/invocation, mutable checkout preparation or global link installation
- **AND** each default omp uses only its declared platform owner

### Requirement: Shared user-scope module set

Mac and native Windows Korolev SHALL consume one portable chezmoi source for applicable Git, GitHub CLI and repository-root facts with OS-specific behavior owned once. Mac Nix SHALL own ordinary user packages and shell plugins; native Windows tools SHALL keep C3's ownership. Mac-only setup SHALL apply only to Darwin. Home Manager and Korolev/Linux user configuration SHALL own no scope.

#### Scenario: Build the shared set on both hosts

- **WHEN** the Mac configuration is built and native Windows fixtures render the shared source
- **THEN** each consumes the intended shared facts and platform-owned tools
- **AND** Windows applies no Darwin user setup or Linux package list

#### Scenario: Add a portable module

- **WHEN** portable user configuration changes
- **THEN** both actual hosts consume the change without duplicating its declaration
