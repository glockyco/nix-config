# personal-omp-workstation Specification

## Purpose

This specification defines how the workstation wraps and verifies a platform-owned OMP executable with an immutable personal plugin while preserving mutable runtime state.

## Requirements

### Requirement: Pinned executable and plugin inputs

The workstation SHALL resolve the personal plugin from an independently locked flake input. The personal plugin input SHALL provide a valid OMP plugin directory and SHALL remain in the `omp-agent-setup` repository rather than being copied into `nix-config`. The OMP executable SHALL be mutable platform-owned state: the official Homebrew formula on Darwin and the official prebuilt user-local binary in NixOS/WSL. No supported host SHALL retain a Nix-packaged OMP executable or fallback.

#### Scenario: Build the workstation package

- **WHEN** the workstation OMP wrapper is built for a supported host system
- **THEN** its personal plugin directory comes from a locked Nix store path
- **AND** the wrapper targets the platform-owned OMP executable
- **AND** the wrapper closure contains no Nix-packaged OMP executable

### Requirement: Default wrapped command

The default `omp` command SHALL invoke the platform-owned OMP executable with the immutable personal plugin enabled. On Darwin, the wrapper SHALL invoke the OMP executable from the stable Apple Silicon Homebrew prefix. In NixOS/WSL, the wrapper SHALL invoke the official prebuilt OMP executable from one fixed user-local path. The wrapper SHALL add only the curated language-server executables required by the supported matrix to its `PATH`.

#### Scenario: Resolve the default command

- **WHEN** a user resolves `omp` from a fresh login shell on a supported host
- **THEN** the resolved executable is the Nix-managed workstation wrapper
- **AND** the wrapper invokes the host's platform-owned OMP executable
- **AND** OMP discovers the packaged personal extension, skills, rule, and LSP overrides

#### Scenario: Start OMP from Windows Zed

- **WHEN** Windows Zed starts its configured OMP agent server for a NixOS/WSL workspace
- **THEN** Zed's native WSL remote server invokes the wrapped `omp acp` command with an absolute Linux working directory
- **AND** no explicit local `wsl.exe` bridge, native Windows OMP executable, or compatibility path is required

### Requirement: Mutable runtime state boundary

Home Manager SHALL leave OMP authentication, provider preferences, sessions, history, caches, blobs, logs, model configuration, and user-managed runtime configuration writable and in place. It SHALL NOT replace `~/.omp/agent` or `~/.omp/agent/config.yml` with a store symlink.

#### Scenario: Activate over an existing OMP profile

- **WHEN** Home Manager activates on a host with existing OMP runtime state
- **THEN** authentication, configuration, sessions, history, and caches remain at their existing mutable paths
- **AND** activation does not overwrite or delete those files

### Requirement: Supported Herdr integration reconciliation

Home Manager SHALL use Herdr's supported integration command to install the OMP integration when missing and reinstall it when stale. Nix SHALL NOT copy, patch, or own Herdr's generated extension source.

#### Scenario: Reconcile a missing integration

- **WHEN** activation detects that the Herdr OMP integration is missing or outdated
- **THEN** activation runs the pinned Herdr package's supported `integration install omp` command
- **AND** a subsequent Herdr status report marks the integration current

#### Scenario: Preserve a current integration

- **WHEN** activation detects a current Herdr OMP integration
- **THEN** activation leaves the generated extension unchanged

### Requirement: Representative language-server matrix

The workstation SHALL provide one primary server for C#, Python, TypeScript and JavaScript, Svelte, Nix, Markdown, and LaTeX and BibTeX. The personal plugin SHALL override OMP defaults only where required to select that primary server or correct root detection.

#### Scenario: Exercise the matrix

- **WHEN** the language smoke check runs against fixed representative projects
- **THEN** each server starts through the workstation environment
- **AND** diagnostics are requested for every language
- **AND** definition, references, and rename are exercised for each language where the server supports the operation
- **AND** a failed or missing server fails the check instead of being reported as a warning

### Requirement: Activation proof through a real session

The cutover SHALL be accepted only after a real OMP session is launched through the default wrapper in a disposable repository.

#### Scenario: Verify personal behavior after activation

- **WHEN** the activation smoke session inspects its loaded plugin and performs a harmless preview operation
- **THEN** the session reports the immutable plugin path
- **AND** the personal policy is active
- **AND** the `personal-commit` tool is registered
- **AND** the preview does not mutate repository state

### Requirement: Explicit platform verification

The local verifier SHALL be an explicit command outside Nix activation. It SHALL exercise the platform-owned OMP executable through the immutable wrapper configuration and fail clearly when the expected executable is absent. Both platforms SHALL verify the immutable personal plugin and current Herdr integration.

#### Scenario: Verify a platform installation

- **WHEN** the operator runs the verifier with the expected platform-owned OMP executable installed
- **THEN** the verifier reports the executable version
- **AND** it reports the personal plugin path under `/nix/store`
- **AND** Herdr reports its OMP integration as current

#### Scenario: Reject a missing executable

- **WHEN** the operator runs the verifier without the expected platform-owned OMP executable
- **THEN** verification fails with an actionable error that names the expected path and installation command

### Requirement: Explicit platform OMP updates

OMP executable updates SHALL remain explicit operations outside Nix activation. Darwin SHALL use the official Homebrew upgrade operation. NixOS/WSL SHALL use the official upstream installer in binary mode with a fixed installation directory. Each update path SHALL install an official prebuilt release and SHALL NOT build OMP from source.

#### Scenario: Update OMP on Darwin

- **WHEN** the operator runs the documented Homebrew upgrade operation
- **THEN** Homebrew updates the official OMP formula without a repository change
- **AND** the Nix-managed wrapper invokes the updated executable

#### Scenario: Update OMP in WSL

- **WHEN** the operator runs the documented official installer command in binary mode
- **THEN** the installer replaces the OMP executable at the wrapper's fixed user-local target
- **AND** the update needs no repository change or Nix generation

### Requirement: Platform-owned OMP rollback

A Nix generation rollback SHALL restore the prior wrapper, personal plugin, Herdr, OpenSpec, and language-server paths. It SHALL preserve the currently installed platform-owned OMP version. OMP version recovery SHALL use the owning platform installer rather than a Nix generation.

#### Scenario: Roll back a Nix generation

- **WHEN** the operator restores a prior Nix generation on either supported host
- **THEN** the prior immutable wrapper and plugin become active
- **AND** the platform-owned OMP installation remains unchanged
- **AND** OMP-owned mutable state remains unchanged

#### Scenario: Recover an OMP release

- **WHEN** a platform-owned OMP update fails deterministic verification or the real-session smoke
- **THEN** the recovery procedure uses Homebrew on Darwin or the official binary installer with an explicit release on WSL
- **AND** it does not present Nix generation rollback as an OMP version rollback

### Requirement: Bootstrap-era deployment removal

After activation proof passes, the workstation repository SHALL remove the global mutable bootstrap, managed symlink deployment, source patching, executable repointing, global installers, fleet scanner, and obsolete `omp-skill` and `omp-plans` command paths. No alias or compatibility shim SHALL preserve those paths.

#### Scenario: Inspect the final workstation closure

- **WHEN** the final Home Manager configuration is evaluated
- **THEN** it contains no bootstrap activation, mutable OMP source checkout, global tool installer, or obsolete command shim
- **AND** the default wrapped OMP command remains functional

### Requirement: OpenSpec package consistency

The workstation checks SHALL verify that the OpenSpec executable reports the version declared by its Nix package. They SHALL NOT require a hard-coded historical version after a reviewed update.

#### Scenario: Package and executable disagree

- **WHEN** the packaged executable reports a version different from its Nix package metadata
- **THEN** the workstation release gate fails

### Requirement: Generated OpenSpec adapter freshness

The workstation checks SHALL verify that tracked OpenSpec commands and skills match the selected generator. An OpenSpec update SHALL require review of generated changes before merge.

#### Scenario: Generator output changes

- **WHEN** the selected OpenSpec package would rewrite a tracked adapter
- **THEN** the release gate fails until the generated difference is reviewed and committed

### Requirement: Archived change completeness

The workstation checks SHALL reject an archived OpenSpec change that contains an incomplete task. Strict validation SHALL also retain scenario and task-numbering checks for active contracts.

#### Scenario: An incomplete change is archived

- **WHEN** an archived change contains an unchecked task
- **THEN** the workstation release gate fails

### Requirement: Preserved runtime acceptance

Dependency automation SHALL retain wrapper-shape checks, Herdr reconciliation tests, activation verification, and the conditional real wrapped-session smoke.

#### Scenario: Automation implementation changes

- **WHEN** repository automation changes without changing OMP runtime behavior
- **THEN** deterministic checks pass without a model call and the existing runtime acceptance path remains available

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

The WSL host SHALL activate a new generation with the supported NixOS command. Activation SHALL reconcile Herdr through its supported integration interface and SHALL remain independent of the platform-owned OMP executable's presence or version. A failed Nix activation SHALL leave the previous generation available for selection. Activation and Nix generation rollback SHALL preserve the platform-owned OMP executable.

#### Scenario: Activate a reviewed revision

- **WHEN** the operator activates the WSL host from a reviewed repository revision
- **THEN** the host selects the wrapper, plugin, Herdr, OpenSpec, and language-server closures from the current lock
- **AND** Herdr reconciliation completes
- **AND** activation does not install, update, or invoke the user-local OMP executable

#### Scenario: Re-activate the same revision

- **WHEN** the operator activates the same revision again
- **THEN** the selected Nix closure, user-local OMP executable, and Herdr integration remain current
- **AND** activation creates no duplicate entry in any profile

#### Scenario: Roll back a rejected generation

- **WHEN** a generation fails local verification
- **THEN** the previous generation remains selectable
- **AND** selecting it restores the previous wrapper, plugin, Herdr, OpenSpec, and language-server paths
- **AND** the rollback changes neither the user-local OMP executable nor OMP-owned mutable state

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

### Requirement: Explicit WSL prerequisite boundary

The workstation SHALL provide a WSL 2 provisioning procedure for `x86_64-linux`. The procedure SHALL select Windows Terminal Stable as the native terminal host and the repository-defined NixOS distribution as its default profile. It SHALL identify Windows Terminal installation and settings, Windows feature enablement, repository access, official prebuilt OMP installation, and interactive provider authentication as manual prerequisites that the repository does not own.

#### Scenario: Start from a new Windows machine

- **WHEN** an operator follows the procedure on a machine without the personal OMP environment
- **THEN** the procedure establishes the prerequisites in dependency order
- **AND** it installs the official prebuilt OMP binary at the wrapper's fixed user-local path before verification
- **AND** Windows Terminal Stable opens the NixOS profile in the Linux user's home directory
- **AND** the procedure does not claim to manage Windows policy, Windows applications, or provider authentication

#### Scenario: Provision without administrator rights

- **WHEN** the operator holds standard Windows user rights only
- **AND** WSL 2 is already enabled
- **THEN** distribution import, user-local OMP installation, and host activation complete without elevation

#### Scenario: Use an unsupported architecture

- **WHEN** the operator attempts the procedure on a WSL architecture other than `x86_64-linux`
- **THEN** the procedure stops with an explicit unsupported-platform result before it changes the machine

### Requirement: Signed Linux binary cache

The WSL host SHALL declare Numtide's substituter and trusted public key in its system Nix configuration for the remaining `llm-agents` packages. The WSL host SHALL NOT depend on client-specified flake configuration for that substituter. The WSL OMP executable SHALL NOT depend on that cache.

#### Scenario: Install a cached OMP output

- **WHEN** the WSL host builds the personal OMP environment
- **THEN** Nix can fetch cached Herdr and OpenSpec outputs
- **AND** Nix does not compile or fetch an OMP package
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

- **WHEN** the official OMP installer replaces the user-local OMP release
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
