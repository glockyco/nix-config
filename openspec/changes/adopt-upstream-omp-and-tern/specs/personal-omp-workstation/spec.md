## ADDED Requirements

### Requirement: Official standalone OMP distribution

Each supported workstation SHALL install upstream OMP through the official platform installer in standalone-binary mode, outside Nix activation. Nix SHALL NOT provide an OMP wrapper, source-generation updater, runtime plugin package, executable fallback, or patched OMP release. The personal plugin SHALL be installed in user scope with the install command defined by `publish-plugin-through-omp-plugin-manager`: `omp plugin marketplace add glockyco/omp-agent-setup`, then `omp plugin install --scope user personal@glockyco`. Upgrades SHALL use `omp plugin marketplace update glockyco`, then `omp plugin upgrade --scope user personal@glockyco`, followed by a fresh OMP session. OpenSpec commands SHALL appear as `/personal:opsx-*`, without aliases for the former bare commands.

#### Scenario: Install on either supported host

- **WHEN** the operator installs OMP on macbook-pro or in Korolev's WSL environment
- **THEN** the installer selects the host-native standalone upstream release
- **AND** the plugin manager records the independently released personal plugin in writable user state
- **AND** no developer checkout or Nix runtime plugin path is required

### Requirement: Default upstream command

The default `omp` command SHALL resolve to the official standalone executable from a fresh login shell and retain normal upstream argument and working-directory behavior. Personal extensions, skills, rules, commands, and LSP overrides SHALL load through the plugin manager, without wrapper-supplied `--extension` or `--plugin-dir` flags. OpenSpec, Plannotator, and language servers SHALL be ordinary host packages on the user's PATH, not wrapper runtime inputs. Zed SHALL NOT declare an OMP agent-server integration on either managed platform.

#### Scenario: Resolve the installed command

- **WHEN** the operator starts `omp` in a fresh login shell after activation
- **THEN** the executable is the official installation rather than a Nix store wrapper or Bun-global shim
- **AND** the published personal plugin loads once through the plugin manager
- **AND** OpenSpec, Plannotator, and the platform's language servers resolve from the declared host packages

#### Scenario: Inspect editor configuration

- **WHEN** Mac or rendered Windows Zed settings are inspected after the cutover
- **THEN** they contain no repository-declared OMP agent-server setting
- **AND** unrelated themes, keymaps, and language-server settings remain unchanged

### Requirement: Explicit upstream executable updates

OMP executable updates SHALL use `omp update` as an explicit operation on the requested host outside Nix activation. Personal plugin upgrades SHALL use the plugin-manager upgrade command defined by `publish-plugin-through-omp-plugin-manager`. Neither operation SHALL require workstation patch pins or publish repository changes. Existing sessions SHALL not be interrupted automatically; acceptance SHALL use a fresh session on the observed installed version.

#### Scenario: Update the executable

- **WHEN** an authorized operator runs `omp update`
- **THEN** the upstream command manages the official installation without a wrapper rejection
- **AND** verification records the executable path and observed version in a newly launched session
- **AND** Nix generations and OMP authentication and session state remain outside that update's ownership

#### Scenario: Upgrade personal behavior

- **WHEN** the operator runs the defined plugin upgrade command
- **THEN** the plugin manager upgrades the published plugin in user scope
- **AND** a fresh session verifies its released version and complete loaded capabilities

### Requirement: Tern terminal delivery

Tern SHALL be the primary terminal for interactive OMP sessions on the Mac. The Mac SHALL retain Tern's manually installed, self-updating bundle, its CLI PATH entry, and its Dock pin. Ghostty and Herdr SHALL remain available as secondary tools: the Mac keeps Ghostty's application, theme, configuration, and Dock pin, and both hosts keep the Herdr package. Activation SHALL NOT create, reconcile, or restart through Herdr's OMP integration; the owner installs it on demand with Herdr's supported integration command. Korolev's WSL OMP release proof SHALL also run in Tern for Windows.

#### Scenario: Activate the Mac terminal cutover

- **WHEN** the reviewed Mac configuration activates after upstream OMP and the plugin pass pre-cutover verification
- **THEN** Tern is the primary terminal and keeps its Dock entry
- **AND** `tern` resolves to the installed bundle's CLI without an obsolete Homebrew link
- **AND** Ghostty and Herdr remain installed, and activation does not touch Herdr's OMP integration

## MODIFIED Requirements

### Requirement: Mutable runtime state boundary

Workstation configuration and activation SHALL leave OMP authentication, provider preferences, sessions, history, caches, blobs, logs, model configuration, and user-managed runtime configuration writable and in place. They SHALL NOT replace `~/.omp/agent` or `~/.omp/agent/config.yml` with a store symlink. The plugin manager SHALL own its mutable registry and installed plugin state; Nix SHALL NOT render or reconcile those files.

#### Scenario: Activate over an existing OMP profile

- **WHEN** workstation configuration activates on a host with existing OMP runtime state
- **THEN** authentication, configuration, sessions, history, and caches remain at their existing mutable paths
- **AND** activation does not overwrite or delete those files

### Requirement: Representative language-server matrix

The Mac SHALL provide one primary server for C#, Python, TypeScript and JavaScript, Svelte, Nix, Markdown, and LaTeX and BibTeX. WSL SHALL provide the same matrix except C#/Roslyn, which is Mac-only. The packages SHALL be `markdown-oxide`, `nixd`, `pyright`, `svelte-language-server`, `texlab`, and `typescript-language-server`, with `roslyn-language-server` added on the Mac. The personal plugin SHALL override OMP defaults only where required to select that primary server or correct root detection; a disabled Mac-only server SHALL not start on WSL. Project SDKs SHALL remain project-owned.

#### Scenario: Exercise the matrix

- **WHEN** the language smoke check runs against fixed representative projects on each supported host
- **THEN** each server in that host's matrix starts through the ordinary host package environment
- **AND** diagnostics are requested for every supported language
- **AND** definition, references, and rename are exercised for each language where the server supports the operation
- **AND** a failed or missing supported server fails the check instead of being reported as a warning
- **AND** WSL neither installs nor attempts to launch Roslyn

### Requirement: Activation proof through a real session

The cutover SHALL be accepted only after a real upstream OMP session is launched through the default official command in Tern in a disposable repository on each supported host. Upstream OMP and the published plugin SHALL pass an independent pre-cutover launch before the wrapper is removed.

#### Scenario: Verify personal behavior after activation

- **WHEN** the activation smoke session inspects its loaded plugin and performs a harmless preview operation
- **THEN** the session reports the plugin-manager installation path and released version
- **AND** the personal policy is active
- **AND** the `personal_commit` tool is registered
- **AND** the preview does not mutate repository state

### Requirement: Platform-owned OMP rollback

A Nix generation rollback SHALL restore the prior Nix-managed package/configuration paths without changing the independently installed OMP executable, plugin-manager selection, or application state. Migration SHALL retain the previous Nix generation and source generations until both replacement installations and real-session gates pass, and SHALL never delete a generation used by a running session. OMP version recovery SHALL be an explicit supported official-installer operation for a recorded accepted release, not a claimed Nix or source-updater rollback. User-owned OMP state SHALL not be deleted or copied between hosts.

#### Scenario: Roll back a Nix generation

- **WHEN** the operator restores a prior Nix generation on either supported host
- **THEN** its prior Nix package and configuration paths become active
- **AND** the official OMP installation, plugin-manager state, and OMP-owned mutable state remain unchanged
- **AND** restoring an old wrapper generation is identified as migration recovery, not an OMP version rollback

#### Scenario: Recover an OMP release

- **WHEN** an authorized operator restores a recorded accepted release through the official installer in binary mode
- **THEN** a fresh session reports that restored executable version
- **AND** application state remains in place
- **AND** recovery requires repeated personal-plugin and applicable host smoke checks

#### Scenario: No previous generation exists

- **WHEN** recovery is requested without a retained Nix generation or recorded accepted OMP release
- **THEN** the procedure identifies the missing recovery prerequisite
- **AND** it does not invent a rollback result or delete user state

### Requirement: Bootstrap-era deployment removal

After migration acceptance, the workstation SHALL contain no OMP wrapper, patched-source updater, patch pins, verifier, activation-managed Herdr integration, repository OMP update skill, obsolete command shim, global package link, executable fallback, or superseded `restart-sessions-and-prune-omp-generations` change. Official OMP and plugin installation/update SHALL remain explicit operations outside activation.

#### Scenario: Inspect the final workstation closure

- **WHEN** the final workstation configuration is evaluated
- **THEN** both hosts expose ordinary OpenSpec, Plannotator, and platform language-server packages
- **AND** activation contains no mutable checkout preparation, OMP build, global link installation, or OMP invocation
- **AND** the default command uses the official standalone installation

### Requirement: Preserved runtime acceptance

Dependency automation SHALL retain deterministic ordinary-package/OpenSpec checks, activation-state preservation checks, and conditional real-session smoke in Tern. Removed wrapper, source-updater, and Herdr behavior checks SHALL not remain release prerequisites or aliases.

#### Scenario: Automation implementation changes

- **WHEN** repository automation changes without changing OMP runtime behavior
- **THEN** deterministic checks pass without a model call and the upstream runtime acceptance path remains available

### Requirement: Shared user-scope module set

Both supported hosts SHALL consume one portable user-scope module set for the shell, command-line tools, Git, the GitHub CLI, the repository root, and the language tools. A module that depends on a macOS interface SHALL apply to the Darwin host only.

#### Scenario: Build the shared set on both hosts

- **WHEN** each host configuration is built
- **THEN** both include the portable user-scope modules
- **AND** the WSL host includes no module that names a macOS interface

#### Scenario: Add a portable module

- **WHEN** a portable user-scope module changes
- **THEN** the change applies to both hosts without a second declaration

## REMOVED Requirements

### Requirement: Pinned executable and plugin inputs

**Reason**: Runtime delivery moves to the official installer and OMP's plugin manager; patch and runtime plugin pins are retired.
**Migration**: Install and verify upstream OMP plus the published plugin before removing wrapper delivery; keep any plugin input needed exclusively for OpenSpec build-time checks.

### Requirement: Default wrapped command

**Reason**: The default command must be the upstream executable, including its supported update command; Zed OMP integration is unused.
**Migration**: Use the default upstream command and ordinary packages, remove both Zed agent-server consumers, and verify fresh shells in Tern.

### Requirement: Supported Herdr integration reconciliation

**Reason**: Tern is the primary terminal, and activation no longer couples Nix generations to OMP's mutable extension directory.
**Migration**: Remove the activation and check wiring. Herdr stays installed as a secondary tool; the owner installs its OMP integration on demand with `herdr integration install omp`, and activation neither creates nor removes it.

### Requirement: Explicit platform verification

**Reason**: `verify-personal-omp` reports a wrapper/source/Herdr contract that no longer exists.
**Migration**: Record official executable path/version, plugin-manager identity/path/version, ordinary tools, and real-session checks directly without a replacement verifier shim.

### Requirement: Explicit personal OMP source updates

**Reason**: The patched source-generation workflow is retired.
**Migration**: Use `omp update` for the official executable and the published plugin's manager upgrade command; retain old generations only for the controlled migration/recovery window.

### Requirement: Verified native components without a local compile

**Reason**: Workstation-owned addon acquisition and native compilation existed only for the deleted source updater.
**Migration**: Install the official host-native standalone binary and verify actual startup and sessions on each host.

### Requirement: Shared package cache with isolated candidate state

**Reason**: The source updater and its candidate preparation/cache are deleted.
**Migration**: Leave OMP-owned state unchanged; retire old updater caches only after acceptance and after all old processes exit.

### Requirement: Independent cross-platform source acceptance

**Reason**: Source generation prepare/update/rollback is no longer a supported workflow.
**Migration**: Require independent official-installer launch, `omp update`, published-plugin load/upgrade, and Tern real-session acceptance on both hosts, recording actual versions and paths with this change.
