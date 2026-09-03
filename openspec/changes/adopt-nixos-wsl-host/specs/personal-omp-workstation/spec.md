## ADDED Requirements

### Requirement: Declarative WSL host configuration

The repository SHALL define the WSL host as one NixOS configuration for `x86_64-linux`. That configuration SHALL own the Linux system scope, including `/etc/wsl.conf`, the default user, systemd, the Nix settings, and the system package set. The host SHALL NOT require a distribution package manager, a separate Nix installer, or an imperative user-profile entry.

#### Scenario: Build the WSL host

- **WHEN** the WSL host configuration is built from the locked repository
- **THEN** its system closure resolves from the pinned nixpkgs
- **AND** the build requires no source-built compiler toolchain
- **AND** the closure contains OMP, OpenSpec, Herdr, and the curated language servers

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

The WSL host SHALL activate a new generation with the supported NixOS command. Activation SHALL reconcile Herdr through its supported integration interface and SHALL run deterministic local verification without a model call. A failed verification SHALL leave the previous generation available for selection.

#### Scenario: Activate a reviewed revision

- **WHEN** the operator activates the WSL host from a reviewed repository revision
- **THEN** the host selects the package closures from the current lock
- **AND** Herdr reports its OMP integration as current
- **AND** deterministic verification succeeds without provider authentication

#### Scenario: Re-activate the same revision

- **WHEN** the operator activates the same revision again
- **THEN** the selected closure and the Herdr integration remain current
- **AND** activation creates no duplicate entry in any profile

#### Scenario: Roll back a rejected generation

- **WHEN** a generation fails local verification
- **THEN** the previous generation remains selectable
- **AND** selecting it restores the previous executable, plugin, and language-server paths
- **AND** the rollback changes no OMP-owned authentication, configuration, session, history, or database

### Requirement: Shared user-scope module set

Both supported hosts SHALL consume one portable user-scope module set for the shell, command-line tools, Git, the GitHub CLI, the repository root, OMP, and the language tools. A module that depends on a macOS interface SHALL apply to the Darwin host only.

#### Scenario: Build the shared set on both hosts

- **WHEN** each host configuration is built
- **THEN** both include the portable user-scope modules
- **AND** the WSL host includes no module that names a macOS interface

#### Scenario: Add a portable module

- **WHEN** a portable user-scope module changes
- **THEN** the change applies to both hosts without a second declaration

### Requirement: WSL host network isolation

The WSL host SHALL expose no listening network service. No other host SHALL drive it. The host SHALL hold no decryption key and no shared secret.

#### Scenario: Inspect the running host

- **WHEN** the WSL host is running
- **THEN** it runs no SSH server and no other inbound service
- **AND** the configuration declares no secret and no age recipient for this host

### Requirement: Container runtime on the WSL host

The WSL host SHALL provide a rootless container runtime that accepts Docker commands. The runtime SHALL run inside the WSL distribution. The workstation SHALL NOT require a Windows container product, and SHALL NOT require nested virtualization.

#### Scenario: Run a container

- **WHEN** the user runs a container image on the WSL host after activation
- **THEN** the container starts and exits with its own status
- **AND** the runtime requires no root privileges and no separate virtual machine

#### Scenario: Use the Docker command name

- **WHEN** a project command invokes the Docker command name
- **THEN** the declared runtime serves that command

#### Scenario: Preserve the boundary

- **WHEN** the host configuration is reviewed
- **THEN** it declares no Windows container product
- **AND** it declares no listening container service that another host can reach

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

## MODIFIED Requirements

### Requirement: Explicit WSL prerequisite boundary

The workstation SHALL provide a WSL 2 provisioning procedure for `x86_64-linux`. The procedure SHALL select Windows Terminal Stable as the native terminal host and the repository-defined NixOS distribution as its default profile. It SHALL identify Windows Terminal installation and settings, Windows feature enablement, repository access, and interactive provider authentication as manual prerequisites that the repository does not own.

#### Scenario: Start from a new Windows machine

- **WHEN** an operator follows the procedure on a machine without the personal OMP environment
- **THEN** the procedure establishes the prerequisites in dependency order
- **AND** Windows Terminal Stable opens the NixOS profile in the Linux user's home directory
- **AND** the procedure does not claim to manage Windows policy, Windows applications, or provider authentication

#### Scenario: Provision without administrator rights

- **WHEN** the operator holds standard Windows user rights only
- **AND** WSL 2 is already enabled
- **THEN** distribution import and host activation complete without elevation

#### Scenario: Use an unsupported architecture

- **WHEN** the operator attempts the procedure on a WSL architecture other than `x86_64-linux`
- **THEN** the procedure stops with an explicit unsupported-platform result before it changes the machine

### Requirement: Signed Linux binary cache

The WSL host SHALL declare Numtide's substituter and trusted public key in its system Nix configuration. The WSL host SHALL NOT depend on client-specified flake configuration for that substituter.

#### Scenario: Install a cached OMP output

- **WHEN** the locked OMP output exists in the Numtide cache
- **THEN** Nix fetches that output instead of compiling OMP locally
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

The WSL host SHALL declare `johann.glock@scch.at` as the global Git email. It SHALL declare `11704293+glockyco@users.noreply.github.com` for personal repository trees through a conditional Git include. It SHALL NOT write repository-local Git configuration during activation.

#### Scenario: Bootstrap with a work email

- **WHEN** the WSL host declares `johann.glock@scch.at` as the global Git email
- **AND** the user commits in a personal repository tree
- **THEN** the effective commit email is `11704293+glockyco@users.noreply.github.com`
- **AND** `git config --global user.email` remains `johann.glock@scch.at`

#### Scenario: Commit in a personal repository

- **WHEN** the user commits in a personal repository tree on the WSL host
- **THEN** Git reports the GitHub no-reply address
- **AND** the global Git email remains `johann.glock@scch.at`

#### Scenario: Commit outside a personal repository tree

- **WHEN** the user commits in a repository outside the declared personal trees
- **THEN** Git reports the work email

#### Scenario: Inspect a fresh checkout

- **WHEN** the user clones a personal repository after activation
- **THEN** the correct identity applies without any repository-local Git configuration

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

## REMOVED Requirements

### Requirement: Single post-Nix bootstrap command

**Reason**: The requirement describes a user-profile entry that one repository-specific command installs, migrates, and rolls back. The NixOS host replaces that mechanism with supported NixOS activation and generations, so the requirement no longer describes the workstation.

**Migration**: `Declarative WSL host configuration` and `WSL host activation and rollback` carry the retained behavior: one supported activation path, Herdr reconciliation, deterministic verification without a model call, idempotent re-entry, and recovery of the previous environment.
