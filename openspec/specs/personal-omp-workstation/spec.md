# personal-omp-workstation Specification

## Purpose

TBD - created by archiving change consume-personal-omp-plugin. Update Purpose after archive.

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
