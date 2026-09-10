# personal-omp-workstation Specification

## Purpose

This specification defines how the workstation wraps and verifies a host-local OMP source generation with an immutable personal plugin while preserving mutable runtime state.

## Requirements

### Requirement: Pinned executable and plugin inputs

The workstation SHALL resolve the personal plugin from an independently locked flake input in `omp-agent-setup`. The OMP runtime SHALL be a mutable, host-local source generation prepared from a stable upstream release and a reviewed, pinned Git patch series. Nix SHALL supply the wrapper and updater, not an OMP executable fallback. The patch input SHALL be accessible independently from both supported hosts.

#### Scenario: Build the workstation package

- **WHEN** the workstation OMP wrapper is built for a supported host system
- **THEN** its personal plugin directory comes from a locked Nix store path
- **AND** the wrapper targets the explicitly selected source generation
- **AND** the wrapper closure contains no Nix-packaged OMP executable

#### Scenario: Retrieve patches on another host

- **WHEN** either host prepares OMP from the reviewed patch input
- **THEN** it obtains the same pinned patch series without contacting the other workstation
- **AND** an unavailable or invalid patch input fails preparation without changing the selected runtime

### Requirement: Default wrapped command

The default `omp` command SHALL invoke the selected source generation with the immutable personal plugin, curated language tools, and pinned Plannotator executable. Both supported hosts SHALL use the same home-relative selection convention. The wrapper SHALL preserve the caller's working directory and arguments. It SHALL reject the leading executable-update subcommand with instructions to use `omp-dev-update` and SHALL NOT install an official release or invoke a fallback. Plannotator SHALL resolve from the declared package before user-provided alternatives, without changing the parent shell's environment.

#### Scenario: Resolve the default command

- **WHEN** a user resolves `omp` from a fresh login shell on a supported host
- **THEN** the resolved executable is the Nix-managed workstation wrapper
- **AND** the wrapper invokes the selected verified source generation
- **AND** OMP discovers the packaged personal extensions, skills, rule, and LSP overrides
- **AND** annotation commands resolve the unmodified vendor Plannotator executable from the declared commit-pinned input

#### Scenario: Start OMP from Windows Zed

- **WHEN** Windows Zed starts its configured OMP agent server for a NixOS/WSL workspace
- **THEN** Zed's native WSL remote server invokes the wrapped `omp acp` command with an absolute Linux working directory
- **AND** no explicit local `wsl.exe` bridge, native Windows OMP executable, or compatibility path is required

#### Scenario: Reject an upstream executable update

- **WHEN** the user runs `omp update`
- **THEN** the wrapper exits unsuccessfully with the `omp-dev-update` instruction
- **AND** neither the active source generation nor an official executable is modified

#### Scenario: Preserve normal command resolution

- **WHEN** the user starts a normal session or passes `update` outside the leading subcommand
- **THEN** the wrapper preserves the arguments and enables the immutable plugin, language tools, and Plannotator
- **AND** nested `omp` commands continue to resolve to the Nix wrapper
- **AND** the caller's shell environment is unchanged

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

The local verifier SHALL remain an explicit command outside Nix activation. On both hosts it SHALL report the selected upstream release, patch identity, runtime version, immutable plugin path, and current Herdr integration. It SHALL fail when the selected generation is absent or unusable.

#### Scenario: Verify a platform installation

- **WHEN** the operator runs the verifier with a prepared source generation selected
- **THEN** verification reports its release, patch identity, and runtime version
- **AND** it reports the personal plugin path under `/nix/store`
- **AND** Herdr reports its OMP integration as current

#### Scenario: Reject a missing executable

- **WHEN** the operator runs the verifier before the first successful source preparation
- **THEN** verification fails with an actionable error naming the expected location and `omp-dev-update`
- **AND** it does not use a different installation

### Requirement: Explicit personal OMP source updates

`omp-dev-update` SHALL prepare the latest stable upstream release with the pinned patch series on both macbook-pro and korolev. It SHALL prepare matching dependencies, native components, and the development runtime for the local platform. Only a successfully checked candidate SHALL become the default. Updates SHALL remain explicit operations outside activation and SHALL NOT publish commits, create custom releases, schedule future updates, or create global package links.

#### Scenario: Initialize on either supported host

- **WHEN** the operator first runs `omp-dev-update` on macbook-pro or korolev
- **THEN** the command prepares and verifies a complete host-native source generation
- **AND** the next wrapped `omp` invocation uses that generation with the immutable plugin
- **AND** no pre-existing developer checkout is required

#### Scenario: Select a stable upstream release

- **WHEN** upstream also offers prereleases or newer development commits
- **THEN** the updater selects a non-draft stable release rather than development HEAD
- **AND** the resulting generation identifies the exact upstream and patch commits

#### Scenario: Preserve the active runtime during preparation

- **WHEN** an update is preparing dependencies, native components, or checks
- **THEN** new `omp` invocations continue to use the previous verified generation
- **AND** existing sessions retain access to their original generation

#### Scenario: Reject a failed candidate

- **WHEN** fetching, patch application, dependency preparation, native preparation, or verification fails
- **THEN** the updater reports the failed phase and exits unsuccessfully
- **AND** the active runtime and OMP-owned application state remain unchanged
- **AND** patch conflicts are not resolved by discarding either side automatically

#### Scenario: Interrupt an update

- **WHEN** preparation is interrupted before promotion
- **THEN** the next `omp` invocation still uses the previous verified generation
- **AND** a subsequent updater invocation can proceed without a stale process lock

#### Scenario: Serialize concurrent operations

- **WHEN** another update or rollback already owns the local update lock
- **THEN** a second operation cannot concurrently modify the active selection

#### Scenario: Repeat an unchanged update

- **WHEN** the selected stable release and patch input are unchanged
- **THEN** the updater reports the current generation without rebuilding or creating another generation

### Requirement: Verified native components without a local compile

The updater SHALL prepare the host native addon for each candidate. It SHALL install the addon that upstream published for the candidate release and platform, and it SHALL verify the published integrity digest and provenance before installation. It SHALL compile the addon inside the candidate development environment only when the pinned patch range changes native sources, or when no verified published addon matches the candidate release and platform. A failed verification SHALL fail the update. The updater SHALL NOT install an unverified artifact and SHALL NOT substitute a release executable.

#### Scenario: Install a published addon

- **WHEN** the pinned patch range changes no native source and the published addon matches the candidate release and platform
- **THEN** the updater installs that verified addon into the candidate
- **AND** the candidate loads the addon and passes the existing native and launch checks
- **AND** preparation runs no local compilation of native sources

#### Scenario: Patch range changes native sources

- **WHEN** the pinned patch range changes the Rust crates, the native package, or the workspace build files
- **THEN** the updater compiles the addon in the candidate development environment instead of installing a published one
- **AND** promotion still requires the existing native loading and launch verification

#### Scenario: Reject an unverifiable addon

- **WHEN** the published addon fails its integrity or provenance verification
- **THEN** the updater reports the native phase and exits unsuccessfully
- **AND** the selected generation and OMP-owned application state remain unchanged
- **AND** the candidate does not receive the rejected artifact

### Requirement: Shared package cache with isolated candidate state

The updater SHALL keep one persistent package cache for downloaded dependencies under its state root. Candidate preparation and verification SHALL continue to use their own home, configuration, agent, and session directories, separate from operator state. The cache SHALL hold downloaded packages only. Removing the cache SHALL NOT change any prepared generation, recorded metadata, or current selection.

#### Scenario: Repeat preparation after a completed update

- **WHEN** a later update prepares a new candidate on the same host
- **THEN** dependency installation reuses the previously downloaded packages
- **AND** the new candidate still receives its own isolated home and agent state

#### Scenario: Remove the cache

- **WHEN** the operator deletes the package cache
- **THEN** the selected generation continues to launch unchanged
- **AND** the next update downloads the packages it needs again

### Requirement: Platform-owned OMP rollback

A Nix generation rollback SHALL restore the prior wrapper, personal plugin, Herdr, OpenSpec, and language-server paths without changing the selected OMP source version or application state. `omp-dev-update --rollback` SHALL select the previous verified source generation without network access. Successful generations SHALL remain usable after Nix garbage collection while retained for launch or rollback.

#### Scenario: Roll back a Nix generation

- **WHEN** the operator restores a prior Nix generation on either supported host
- **THEN** the prior immutable wrapper and plugin become active
- **AND** the source-generation selection and OMP-owned mutable state remain unchanged

#### Scenario: Recover an OMP release

- **WHEN** the operator runs `omp-dev-update --rollback` after a successful update
- **THEN** the previous verified source generation becomes active without a download or rebuild
- **AND** application state remains unchanged
- **AND** the displaced generation remains available

#### Scenario: No previous generation exists

- **WHEN** rollback is requested before a previous verified generation exists
- **THEN** the command fails clearly without changing the active selection

### Requirement: Bootstrap-era deployment removal

The explicit source-generation updater SHALL be the sole owner of personal OMP runtime preparation. The workstation SHALL NOT restore bootstrap activation, global installers, fleet scanners, obsolete command shims, or automatic executable fallbacks. After migration acceptance, the temporary local launcher and obsolete platform update routing SHALL no longer select the default runtime.

#### Scenario: Inspect the final workstation closure

- **WHEN** the final Home Manager configuration is evaluated
- **THEN** it exposes the shared wrapper, updater, and verifier on both hosts
- **AND** activation contains no mutable checkout preparation, OMP build, global link installation, or OMP invocation
- **AND** the default wrapped command uses only the selected source generation

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

### Requirement: Independent cross-platform source acceptance

Acceptance SHALL require real host-local verification on macbook-pro and korolev, not cross-platform evaluation alone. Neither host SHALL depend on the borrowed Air, another workstation's checkout, or another workstation's native build output.

#### Scenario: Verify each supported host

- **WHEN** the source-update workflow is accepted
- **THEN** both hosts have independently prepared, launched, updated, and rolled back a patched generation
- **AND** the existing real wrapped-session plugin smoke passes on both hosts
- **AND** runtime evidence is recorded with this change rather than in current-state manuals

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

### Requirement: Declarative WSL Windows interoperability

The WSL host SHALL register Windows executable interoperability through the supported NixOS-WSL module. User-initiated browser launch SHALL work without an OMP fallback or a manual kernel-entry script. Activation SHALL register the handler without launching a Windows application.

#### Scenario: Restore a missing Windows executable handler

- **WHEN** the host activates its declared configuration with no existing Windows executable handler
- **THEN** the standard `/init` interoperability handler is registered
- **AND** subsequent user-initiated Windows commands and local browser launch work
- **AND** activation itself launches no Windows application
