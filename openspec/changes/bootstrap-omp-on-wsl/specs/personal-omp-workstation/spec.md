## ADDED Requirements

### Requirement: Explicit WSL prerequisite boundary

The workstation SHALL provide a WSL 2 bootstrap procedure for `x86_64-linux`. The procedure SHALL select Windows Terminal Stable as the native terminal host and Ubuntu WSL 2 as its default profile. It SHALL identify terminal installation and settings, Windows feature enablement, Linux user creation, Nix installation, repository access, and interactive provider authentication as manual prerequisites that the repository does not own.

#### Scenario: Start from a new Windows machine

- **WHEN** an operator follows the procedure on a machine without the personal OMP environment
- **THEN** the procedure establishes the prerequisites in dependency order
- **AND** Windows Terminal Stable opens the Ubuntu WSL 2 profile in the Linux user's home directory
- **AND** the procedure does not claim to manage Windows policy, Windows applications, or provider authentication

#### Scenario: Use an unsupported architecture

- **WHEN** the operator attempts the procedure on a WSL architecture other than `x86_64-linux`
- **THEN** the procedure stops with an explicit unsupported-platform result before it changes the Nix profile

### Requirement: Single post-Nix bootstrap command

After Nix and the repository are available, the workstation SHALL expose one supported command that installs or updates the locked personal OMP and OpenSpec packages in the user profile. The same command SHALL reconcile Herdr through its supported integration interface and run deterministic local verification without requiring a model call.

#### Scenario: Bootstrap a clean WSL user profile

- **WHEN** the operator runs the supported command from the locked repository on supported WSL 2
- **THEN** `omp` and `openspec` resolve from the user profile
- **AND** `omp` invokes the locked wrapper with the immutable personal plugin and curated language servers
- **AND** Herdr reports its OMP integration as current
- **AND** deterministic verification succeeds without provider authentication

#### Scenario: Re-enter the bootstrap

- **WHEN** the operator runs the supported command again for the same locked revision
- **THEN** the selected package versions and Herdr integration remain current
- **AND** the command completes without creating duplicate profile entries

#### Scenario: Apply a reviewed revision

- **WHEN** the repository lock changes and the operator reruns the supported command
- **THEN** the user profile selects the package closures from the new lock
- **AND** verification fails rather than retaining a partially updated environment

### Requirement: WSL-local mutable runtime state

The WSL bootstrap SHALL leave OMP authentication, provider preferences, sessions, history, caches, blobs, logs, model configuration, and user-managed runtime configuration as writable state under the WSL user's home directory. It SHALL NOT import that state from another host or replace `~/.omp/agent` or `~/.omp/agent/config.yml` with a Nix store symlink.

#### Scenario: Bootstrap over existing WSL state

- **WHEN** the supported command runs for a WSL user with existing OMP runtime state
- **THEN** the command preserves authentication, configuration, sessions, history, and caches
- **AND** only Herdr's supported integration command can create or update its generated extension

#### Scenario: Bootstrap a new WSL user

- **WHEN** the supported command runs before the WSL user has authenticated OMP
- **THEN** deterministic installation and verification complete without fabricating authentication or copying state from another machine
- **AND** OMP can create its mutable state during the later interactive session

### Requirement: WSL release proof through a real session

WSL support SHALL be accepted only after a real OMP session starts through the installed default wrapper in a disposable WSL repository hosted by Windows Terminal Stable. The release record SHALL identify the tested Windows Terminal version, Windows version, WSL version, Linux distribution, host architecture, and locked repository revision.

#### Scenario: Verify personal behavior on WSL

- **WHEN** the WSL smoke session inspects its loaded plugin and performs a harmless `personal_commit` preview
- **THEN** the session reports the personal plugin path under `/nix/store`
- **AND** the personal policy is active
- **AND** the `personal_commit` tool is registered
- **AND** the preview does not mutate repository state

#### Scenario: Reject package-only evidence

- **WHEN** Linux evaluation and deterministic package checks pass without a real wrapped session on WSL
- **THEN** the change remains unaccepted for WSL runtime support
