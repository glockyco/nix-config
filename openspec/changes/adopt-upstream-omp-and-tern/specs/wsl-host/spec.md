## MODIFIED Requirements

### Requirement: Declarative WSL host configuration

The repository SHALL define the WSL host as one NixOS configuration for `x86_64-linux`. That configuration SHALL own the Linux system scope, including `/etc/wsl.conf`, the default user, systemd, the Nix settings, and the system package set. The host SHALL NOT require a distribution package manager, a separate Nix installer, or an imperative user-profile entry.

#### Scenario: Build the WSL host

- **WHEN** the WSL host configuration is built from the locked repository
- **THEN** its system closure resolves from the pinned nixpkgs
- **AND** the build requires no source-built compiler toolchain
- **AND** the closure contains OpenSpec and the curated language servers

#### Scenario: Own the WSL runtime settings

- **WHEN** the WSL host is running
- **THEN** `/etc/wsl.conf` matches the declared configuration
- **AND** systemd is process 1
- **AND** the declared default user owns the interactive session

#### Scenario: Report no failed system units

- **WHEN** the WSL host completes activation
- **THEN** `systemctl is-system-running` reports a running system
- **AND** no unit is in a failed state

### Requirement: WSL host activation and rollback

The WSL host SHALL activate a new generation with the supported NixOS command. Activation SHALL remain independent of the official OMP installation/version and plugin-manager state, SHALL not reconcile Herdr, and SHALL not install or invoke OMP. A failed Nix activation SHALL leave the previous generation available for selection. Activation and Nix rollback SHALL preserve user-owned OMP executable/plugin selections and application state.

#### Scenario: Activate a reviewed revision

- **WHEN** the WSL host is activated from a reviewed repository revision
- **THEN** it selects the declared ordinary OpenSpec, Plannotator, and WSL language-server closures without Roslyn
- **AND** no Herdr integration is created or reconciled
- **AND** activation neither installs nor invokes OMP

#### Scenario: Re-activate the same revision

- **WHEN** the WSL host activates the same revision again
- **THEN** the selected Nix closure remains current and user-owned OMP/plugin state is unchanged
- **AND** activation creates no duplicate profile entry

#### Scenario: Roll back a rejected generation

- **WHEN** a Nix generation fails verification
- **THEN** the previous generation remains selectable
- **AND** selecting it restores prior Nix packages/configuration without changing official OMP/plugin-manager selections or application state

### Requirement: Explicit WSL prerequisite boundary

The workstation SHALL provide a WSL 2 provisioning procedure for `x86_64-linux`. The procedure SHALL use Tern for Windows as the native terminal host for the repository-defined NixOS distribution. It SHALL identify manual Tern availability, Windows feature enablement, repository access, Nix activation, explicit official standalone OMP installation, personal-plugin manager installation as defined by `publish-plugin-through-omp-plugin-manager`, and interactive provider authentication as prerequisites. NixOS SHALL not install Tern, manage Windows policy, or authenticate providers.

#### Scenario: Start from a new Windows machine

- **WHEN** an operator follows the procedure on a machine without the personal OMP environment
- **THEN** the procedure establishes the prerequisites in dependency order
- **AND** it activates the NixOS host and installs official standalone OMP plus the published personal plugin before verification
- **AND** Tern opens the NixOS environment in the Linux user's home directory
- **AND** the procedure does not claim NixOS manages Windows policy, Windows applications, or provider authentication

#### Scenario: Provision without administrator rights

- **WHEN** the operator holds standard Windows user rights only
- **AND** WSL 2 is already enabled
- **THEN** distribution import, NixOS activation, and user-owned official OMP/plugin installation require no Windows administrator elevation
- **AND** any Linux sudo prompt is handled according to local policy by the owner in the terminal

#### Scenario: Use an unsupported architecture

- **WHEN** the operator attempts the procedure on a WSL architecture other than `x86_64-linux`
- **THEN** the procedure stops with an explicit unsupported-platform result before it changes the machine

### Requirement: Signed Linux binary cache

The WSL host SHALL declare Numtide's substituter and trusted public key in its system Nix configuration for the remaining `llm-agents` packages, including OpenSpec. The WSL host SHALL NOT depend on client-specified flake configuration for that substituter. The official WSL OMP executable and plugin-manager runtime installation SHALL NOT depend on that cache.

#### Scenario: Build the Nix-managed OMP integration

- **WHEN** the WSL host builds its ordinary workflow environment
- **THEN** Nix can fetch cached OpenSpec outputs
- **AND** Nix does not compile or fetch an OMP executable package, Herdr, or runtime personal-plugin package
- **AND** the default NixOS substituter remains configured

#### Scenario: Build as an unprivileged user

- **WHEN** an unprivileged user on the WSL host evaluates or builds a repository output
- **THEN** Nix does not report an ignored client-specified `trusted-public-keys` setting

### Requirement: WSL-local mutable runtime state

The WSL host SHALL leave OMP authentication, provider preferences, sessions, history, caches, blobs, logs, model configuration, user-managed runtime configuration, and plugin-manager state as writable state under the WSL user's home directory. It SHALL NOT import that state from another host. It SHALL NOT replace `~/.omp/agent` or `~/.omp/agent/config.yml` with a Nix store symlink. Official installation and plugin-manager operations SHALL be explicit user operations outside activation.

#### Scenario: Bootstrap over existing WSL state

- **WHEN** activation runs for a WSL user with existing OMP runtime state
- **THEN** activation preserves authentication, configuration, sessions, history, caches, and plugin-manager state
- **AND** no Herdr-generated extension is created or updated

#### Scenario: Bootstrap a new WSL user

- **WHEN** activation runs before the WSL user has started or authenticated OMP
- **THEN** activation does not fabricate OMP application or plugin-manager state
- **AND** deterministic verification completes without importing authentication, configuration, or state from another machine

### Requirement: WSL release proof through a real session

WSL support SHALL be accepted only after a real upstream OMP session starts through the official installed default command in a disposable WSL repository hosted by Tern for Windows. The release record SHALL identify the tested Tern version, Windows version, WSL version, NixOS release, host architecture, official OMP path/version, plugin-manager installation identity/version, and locked repository revision.

#### Scenario: Verify personal behavior on WSL

- **WHEN** the WSL smoke session inspects its loaded plugin and performs a harmless `personal_commit` preview
- **THEN** the session reports the plugin-manager installation path and released version
- **AND** the personal policy is active
- **AND** the `personal_commit` tool is registered
- **AND** the preview does not mutate repository state

#### Scenario: Reject package-only evidence

- **WHEN** Linux evaluation and deterministic host checks pass without a real upstream session in Tern on WSL
- **THEN** the change remains unaccepted for WSL runtime support

### Requirement: Managed browser compatibility on WSL

The NixOS/WSL host SHALL provide the shared-library ABI required by OMP's managed Linux Chromium through the system's declarative foreign-binary loader. OMP SHALL continue to own the Chromium executable, browser profiles, cache, and browser runtime state. Nix activation SHALL NOT download, replace, patch, or invoke the browser.

#### Scenario: Open a page with the managed browser

- **WHEN** the operator uses OMP's managed browser after activating the WSL host
- **THEN** Chromium starts without a missing-library error
- **AND** it loads and renders a public HTTPS page

#### Scenario: Inspect the system browser ABI

- **WHEN** the WSL host closure is inspected before activation
- **THEN** its foreign-binary library path contains every shared-library name required by the supported OMP browser runtime
- **AND** the closure contains no Nix-packaged Chromium executable

#### Scenario: Activate over browser runtime state

- **WHEN** the operator activates or rolls back a NixOS generation
- **THEN** OMP's downloaded Chromium, browser profiles, cache, and browser configuration remain unchanged

#### Scenario: Update OMP on WSL

- **WHEN** `omp update` installs a new official release
- **THEN** the operator repeats the managed-browser smoke before accepting the update
- **AND** a new browser ABI requirement fails visibly instead of causing activation to mutate OMP state
