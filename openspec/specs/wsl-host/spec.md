# wsl-host Specification

## Purpose

Define NixOS/WSL host provisioning, isolation, interoperability, mutable OMP state, and live acceptance without assigning Windows resources to Linux activation.

## Requirements

### Requirement: Declarative WSL host configuration

The repository SHALL define the WSL host as one NixOS configuration for `x86_64-linux`. That configuration SHALL own the Linux system scope, including `/etc/wsl.conf`, the default user, systemd, the Nix settings, and the system package set. The host SHALL NOT require a distribution package manager, a separate Nix installer, or an imperative user-profile entry.

#### Scenario: Build the WSL host

- **WHEN** the WSL host configuration is built from the locked repository
- **THEN** its system closure resolves from the pinned nixpkgs
- **AND** the build requires no source-built compiler toolchain
- **AND** the closure contains the OMP wrapper and updater, OpenSpec, Herdr, and the curated language servers

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

The WSL host SHALL activate a new generation with the supported NixOS command. Activation SHALL reconcile Herdr through its supported integration interface and SHALL remain independent of source-generation presence or version. A failed Nix activation SHALL leave the previous generation available for selection. Activation and Nix rollback SHALL preserve source-generation selection and application state.

#### Scenario: Activate a reviewed revision

- **WHEN** the WSL host is activated from a reviewed repository revision
- **THEN** it selects the declared wrapper, updater, plugin, Herdr, OpenSpec, and language-server closures
- **AND** Herdr reconciliation completes
- **AND** activation neither prepares nor invokes OMP

#### Scenario: Re-activate the same revision

- **WHEN** the WSL host activates the same revision again
- **THEN** the selected Nix closure, source-generation selection, and Herdr integration remain current
- **AND** activation creates no duplicate profile entry

#### Scenario: Roll back a rejected generation

- **WHEN** a Nix generation fails verification
- **THEN** the previous generation remains selectable
- **AND** selecting it restores the prior immutable integration without changing OMP source selection or application state

### Requirement: WSL host network isolation

The WSL host SHALL expose no network service reachable from another host and SHALL remain unreachable from every other tailnet node by policy and by its own shields-up setting. Temporary annotation servers SHALL bind only to loopback and SHALL be reachable by the local Windows browser through WSL local connectivity. They SHALL NOT publish through Tailscale or require firewall openings. The host SHALL hold its tailnet device identity and one root-owned SSH client key dedicated to the Darwin builder. The private key SHALL remain outside the repository and Nix store. Its existing client access to the Darwin host for remote builds and SSH SHALL remain available. No other host SHALL drive it.

#### Scenario: Inspect the running host

- **WHEN** the WSL host is running
- **THEN** it runs no SSH server, no tailnet SSH server, and no other externally reachable inbound service
- **AND** its firewall declares no open TCP or UDP port
- **AND** the configuration declares no secret and no age recipient for this host

#### Scenario: Another node attempts to reach the WSL host

- **WHEN** the Darwin host, the Air, or the desktop attempts a tailnet connection to the WSL host
- **THEN** the connection is refused
- **AND** the tailnet policy tests assert that refusal at every policy apply

#### Scenario: The WSL host reaches the Darwin host

- **WHEN** the WSL host opens a remote build session to the Darwin host
- **THEN** tailnet policy permits the network connection and OpenSSH authenticates the dedicated builder key
- **AND** the client key is readable only by root, and only its public key and private-key path enter the configuration

#### Scenario: Open and end a local annotation review

- **WHEN** a local OMP session on WSL opens a visual annotation review
- **THEN** only a temporary loopback listener is created
- **AND** the local Windows browser can reach it without tailnet publication or a firewall change
- **AND** a terminal result, explicit cancellation, session navigation, or shutdown removes the owned listener
- **AND** tab closure alone can leave the review pending until `/plannotator-cancel` or another cancellation event

### Requirement: Declared host defaults

The WSL host SHALL declare the login shell, the time zone, and the time and measurement formats that its interactive session uses.

#### Scenario: Inspect the interactive session

- **WHEN** the declared user starts a new interactive session
- **THEN** the session runs the shell that the portable module set configures
- **AND** the prompt, the shared history, and the completion behavior of that set are active

#### Scenario: Report local time and formats

- **WHEN** the host reports the date, the time, and a measured quantity
- **THEN** it uses the declared time zone
- **AND** it uses 24-hour time and metric measurement

### Requirement: Explicit WSL prerequisite boundary

The workstation SHALL provide a WSL 2 provisioning procedure for `x86_64-linux`. The procedure SHALL select Windows Terminal Stable as the native terminal host and the repository-defined NixOS distribution as its default profile. It SHALL identify Windows Terminal installation and settings, Windows feature enablement, repository access, explicit `omp-dev-update` preparation after Nix activation, and interactive provider authentication as prerequisites. The repository does not own Windows installation or provider authentication.

#### Scenario: Start from a new Windows machine

- **WHEN** an operator follows the procedure on a machine without the personal OMP environment
- **THEN** the procedure establishes the prerequisites in dependency order
- **AND** it activates the NixOS host, then prepares and selects a patched source generation with `omp-dev-update` before verification
- **AND** Windows Terminal Stable opens the NixOS profile in the Linux user's home directory
- **AND** the procedure does not claim to manage Windows policy, Windows applications, or provider authentication

#### Scenario: Provision without administrator rights

- **WHEN** the operator holds standard Windows user rights only
- **AND** WSL 2 is already enabled
- **THEN** distribution import, NixOS activation, and host-local source preparation complete without Windows administrator elevation

#### Scenario: Use an unsupported architecture

- **WHEN** the operator attempts the procedure on a WSL architecture other than `x86_64-linux`
- **THEN** the procedure stops with an explicit unsupported-platform result before it changes the machine

### Requirement: Signed Linux binary cache

The WSL host SHALL declare Numtide's substituter and trusted public key in its system Nix configuration for the remaining `llm-agents` packages. The WSL host SHALL NOT depend on client-specified flake configuration for that substituter. The WSL OMP executable SHALL NOT depend on that cache.

#### Scenario: Build the Nix-managed OMP integration

- **WHEN** the WSL host builds the personal OMP environment
- **THEN** Nix can fetch cached Herdr and OpenSpec outputs
- **AND** Nix does not compile or fetch an OMP executable package
- **AND** the default NixOS substituter remains configured

#### Scenario: Build as an unprivileged user

- **WHEN** an unprivileged user on the WSL host evaluates or builds a repository output
- **THEN** Nix does not report an ignored client-specified `trusted-public-keys` setting

### Requirement: WSL-local mutable runtime state

The WSL host SHALL leave OMP authentication, provider preferences, sessions, history, caches, blobs, logs, model configuration, and user-managed runtime configuration as writable state under the WSL user's home directory. It SHALL NOT import that state from another host. It SHALL NOT replace `~/.omp/agent` or `~/.omp/agent/config.yml` with a Nix store symlink.

#### Scenario: Bootstrap over existing WSL state

- **WHEN** activation runs for a WSL user with existing OMP runtime state
- **THEN** activation preserves authentication, configuration, sessions, history, and caches
- **AND** only Herdr's supported integration command creates or updates its generated extension

#### Scenario: Bootstrap a new WSL user

- **WHEN** activation runs before the WSL user has started or authenticated OMP
- **THEN** activation creates only the missing `~/.omp/agent` directory that Herdr requires
- **AND** deterministic verification completes without fabricating authentication, configuration, or state from another machine

### Requirement: Repository-specific Git identity

The WSL host SHALL declare `johann.glock@scch.at` as the global Git email. It SHALL declare `11704293+glockyco@users.noreply.github.com` for every Git worktree below `~/src/github.com/` through a conditional Git include. The global email SHALL remain effective below `~/src/gitlab.scch.at/` and outside the GitHub tree unless a repository-local email overrides it. A repository-local `user.email` SHALL override both declared identities. Activation SHALL NOT write repository-local Git configuration.

#### Scenario: Bootstrap with a work email

- **WHEN** the WSL host declares `johann.glock@scch.at` as the global Git email
- **AND** the user inspects the effective email in a GitHub worktree
- **THEN** Git reports `11704293+glockyco@users.noreply.github.com`
- **AND** the global Git email remains `johann.glock@scch.at`

#### Scenario: Commit in a personal repository

- **WHEN** the user commits in a Git worktree below `~/src/github.com/`
- **THEN** Git uses `11704293+glockyco@users.noreply.github.com`
- **AND** the result does not depend on the repository owner

#### Scenario: Commit outside a personal repository tree

- **WHEN** the user commits in a Git worktree below `~/src/gitlab.scch.at/`
- **THEN** Git uses `johann.glock@scch.at`

#### Scenario: Use a repository-local override

- **WHEN** a repository below either declared host tree has a repository-local `user.email`
- **THEN** Git uses the repository-local email

#### Scenario: Inspect a fresh checkout

- **WHEN** the user clones a repository below `~/src/github.com/` after activation
- **THEN** Git reports the GitHub no-reply address without repository-local Git configuration

### Requirement: WSL release proof through a real session

WSL support SHALL be accepted only after a real OMP session starts through the installed default wrapper in a disposable WSL repository hosted by Windows Terminal Stable. The release record SHALL identify the tested Windows Terminal version, Windows version, WSL version, NixOS release, host architecture, and locked repository revision.

#### Scenario: Verify personal behavior on WSL

- **WHEN** the WSL smoke session inspects its loaded plugin and performs a harmless `personal_commit` preview
- **THEN** the session reports the personal plugin path under `/nix/store`
- **AND** the personal policy is active
- **AND** the `personal_commit` tool is registered
- **AND** the preview does not mutate repository state

#### Scenario: Reject package-only evidence

- **WHEN** Linux evaluation and deterministic host checks pass without a real wrapped session on WSL
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

- **WHEN** `omp-dev-update` selects a new verified patched source generation
- **THEN** the operator repeats the managed-browser smoke before accepting the update
- **AND** a new browser ABI requirement fails visibly instead of causing activation to mutate OMP state

### Requirement: On-demand authenticated browser relay

The workstation SHALL provide an on-demand path from OMP in WSL to a dedicated Chromium-based Windows browser profile. The relay browser SHALL remain separate from the declared interactive browser and SHALL NOT start automatically. OMP SHALL own the unpacked relay extension, and its installation SHALL remain an explicit user operation outside NixOS and Windows configuration activation.

#### Scenario: Use an authenticated web interface

- **WHEN** the operator opens the dedicated relay profile with one intended tab and requests a relay-backed browser session
- **THEN** OMP adopts that tab
- **AND** the authenticated profile remains available for interactive login or multi-factor authentication
- **AND** ordinary browsing remains outside the relay profile

#### Scenario: Start the workstation without browser automation

- **WHEN** Windows starts and the operator signs in
- **THEN** the relay browser and relay daemon remain stopped until requested
- **AND** Zen remains the declared interactive browser

#### Scenario: Activate either configuration layer

- **WHEN** the operator applies the NixOS or Windows declaration
- **THEN** activation does not load an unpacked extension into a browser profile
- **AND** activation does not write OMP browser configuration or browser runtime state

### Requirement: Declarative WSL Windows interoperability

The WSL host SHALL register Windows executable interoperability through the supported NixOS-WSL module. User-initiated browser launch SHALL work without an OMP fallback or a manual kernel-entry script. Activation SHALL register the handler without launching a Windows application.

#### Scenario: Restore a missing Windows executable handler

- **WHEN** the host activates its declared configuration with no existing Windows executable handler
- **THEN** the standard `/init` interoperability handler is registered
- **AND** subsequent user-initiated Windows commands and local browser launch work
- **AND** activation itself launches no Windows application
