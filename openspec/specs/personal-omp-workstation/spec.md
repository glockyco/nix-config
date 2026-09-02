# personal-omp-workstation Specification

## Purpose

This specification defines how the workstation packages, activates, and verifies an immutable OMP executable and personal plugin while preserving mutable runtime state.

## Requirements

### Requirement: Pinned executable and plugin inputs

The workstation SHALL resolve OMP and the personal plugin from independently locked flake inputs. The personal plugin input SHALL provide a valid OMP plugin directory and SHALL remain in the `omp-agent-setup` repository rather than being copied into `nix-darwin`.

#### Scenario: Build the workstation package

- **WHEN** the workstation OMP package is built for a supported host system
- **THEN** its OMP executable and personal plugin directory come from locked Nix store paths
- **AND** evaluation does not read a mutable source checkout

### Requirement: Default wrapped command

The default `omp` command SHALL invoke the pinned upstream OMP binary with the immutable personal plugin enabled. The wrapper SHALL add only the curated language-server executables required by the supported matrix to its `PATH`.

#### Scenario: Resolve the default command

- **WHEN** a user resolves `omp` from a fresh login shell
- **THEN** the resolved executable is the workstation wrapper
- **AND** the wrapper targets the pinned upstream OMP package
- **AND** OMP discovers the packaged personal extension, skills, rule, and LSP overrides

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

### Requirement: Signed Linux binary cache

The root flake SHALL advertise Numtide's substituter and trusted public key as additional Nix configuration. A supported Linux installation SHALL use the signed cached OMP output when the locked output is available from that substituter.

#### Scenario: Install a cached OMP output

- **WHEN** the operator evaluates the root flake and accepts its additional signed cache configuration
- **AND** the locked OMP output exists in the Numtide cache
- **THEN** Nix fetches that output instead of compiling OMP locally
- **AND** the default NixOS and Determinate substituters remain configured

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

- **WHEN** the supported command runs before the WSL user has started or authenticated OMP
- **THEN** the bootstrap creates only the missing `~/.omp/agent` directory required by Herdr
- **AND** Herdr's supported integration command creates its generated extension
- **AND** deterministic installation and verification complete without fabricating authentication, configuration, or state from another machine

### Requirement: Repository-specific Git identity

The WSL bootstrap SHALL configure the `nix-config` checkout to use `11704293+glockyco@users.noreply.github.com` for commits. It SHALL apply this email only to the repository-local Git configuration and SHALL preserve the WSL user's global work email.

#### Scenario: Bootstrap with a work email

- **WHEN** the WSL user's global Git email is `johann.glock@scch.at`
- **AND** the supported command runs from the `nix-config` checkout
- **THEN** `git config --local user.email` reports `11704293+glockyco@users.noreply.github.com`
- **AND** `git config --global user.email` remains `johann.glock@scch.at`

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
