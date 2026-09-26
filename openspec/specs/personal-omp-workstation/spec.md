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

### Requirement: Shared user-scope module set

Both supported hosts SHALL consume one portable user-scope module set for the shell, command-line tools, Git, the GitHub CLI, the repository root, OMP, and the language tools. A module that depends on a macOS interface SHALL apply to the Darwin host only.

#### Scenario: Build the shared set on both hosts

- **WHEN** each host configuration is built
- **THEN** both include the portable user-scope modules
- **AND** the WSL host includes no module that names a macOS interface

#### Scenario: Add a portable module

- **WHEN** a portable user-scope module changes
- **THEN** the change applies to both hosts without a second declaration
