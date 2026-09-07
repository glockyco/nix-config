## MODIFIED Requirements

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

The default `omp` command SHALL invoke the selected source generation with the immutable personal plugin and curated language tools. Both supported hosts SHALL use the same home-relative selection convention. The wrapper SHALL preserve the caller's working directory and arguments. It SHALL reject the leading executable-update subcommand with instructions to use `omp-dev-update` and SHALL NOT install an official release or invoke a fallback.

#### Scenario: Resolve the default command

- **WHEN** a user resolves `omp` from a fresh login shell on a supported host
- **THEN** the resolved executable is the Nix-managed workstation wrapper
- **AND** the wrapper invokes the selected verified source generation
- **AND** OMP discovers the packaged personal extension, skills, rule, and LSP overrides

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
- **THEN** the wrapper preserves the arguments and enables the immutable plugin and language tools
- **AND** nested `omp` commands continue to resolve to the Nix wrapper

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

## REMOVED Requirements

### Requirement: Explicit platform OMP updates

**Reason**: Official Homebrew and standalone updates replace the personal patches and are no longer the selected runtime update path.

**Migration**: Use `omp-dev-update` on both supported hosts. The default wrapper rejects upstream executable updates rather than using an official fallback.

## ADDED Requirements

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

- **WHEN** fetching, patch application, dependency preparation, native compilation, or verification fails
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

### Requirement: Independent cross-platform source acceptance

Acceptance SHALL require real host-local verification on macbook-pro and korolev, not cross-platform evaluation alone. Neither host SHALL depend on the borrowed Air, another workstation's checkout, or another workstation's native build output.

#### Scenario: Verify each supported host

- **WHEN** the source-update workflow is accepted
- **THEN** both hosts have independently prepared, launched, updated, and rolled back a patched generation
- **AND** the existing real wrapped-session plugin smoke passes on both hosts
- **AND** runtime evidence is recorded with this change rather than in current-state manuals
