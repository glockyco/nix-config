## MODIFIED Requirements

### Requirement: One formatting configuration for both gates

Local and CI formatting gates SHALL consume one platform-neutral declaration of formatter identities, file patterns, exclusions and options. Nix and native Windows adapters SHALL use pinned equivalents from that declaration without a second formatter list. Native Windows SHALL reject staged Nix files unless the declared Nix environment can check that same checkout; CI SHALL retain the native Linux/Darwin Nix formatting gates.

#### Scenario: Unformatted file reaches a commit

- **WHEN** a maintainer commits a file that the formatting configuration would rewrite
- **THEN** the commit is rejected

#### Scenario: Unformatted file reaches continuous integration

- **WHEN** the branch contains a file that the formatting configuration would rewrite
- **THEN** the continuous integration job fails

#### Scenario: A formatter is added

- **WHEN** a formatter is added to the formatting configuration
- **THEN** both gates apply it without a second edit

#### Scenario: Stage Nix from native Windows without Nix

- **WHEN** a native Windows commit stages a `.nix` file and no usable declared Nix environment exists
- **THEN** the hook fails with an actionable environment diagnostic
- **AND** no platform skip or missing-tool condition turns that failure into success

#### Scenario: Stage native-only work

- **WHEN** a standard Windows session stages only files supported by the native formatter adapter
- **THEN** the local gate uses the shared declaration and pinned native tools without requiring Nix
- **AND** native precommit runs `windows/check.ps1 -SkipFixtures`, retaining shipped document contracts, pinned official schema validation and shipped script AST/Administrator-boundary checks
- **AND** full on-demand and CI gates retain all isolated fixtures, including rendered chezmoi coverage

### Requirement: The commit hook is installed from the development shell

Entering the declared development environment SHALL install lefthook in that checkout. Darwin/Linux SHALL retain the pinned Nix shell; Windows SHALL use an explicit native bootstrap with pinned tools. Git clients outside the environment SHALL resolve those pinned tools or fail with a missing-environment diagnostic. Platform-specific dispatch SHALL never silently skip staged Nix validation. Native Windows precommit SHALL invoke `windows/check.ps1 -SkipFixtures`, retaining shipped document contracts, pinned official schema validation and shipped script AST/Administrator-boundary checks, and SHALL propagate checker failure. Full on-demand and CI gates SHALL retain the complete isolated fixture suite.

#### Scenario: First entry into the shell

- **WHEN** a maintainer enters the development shell in a working tree with no installed hook
- **THEN** the hook is installed
- **AND** a following commit runs the formatting gate

#### Scenario: Commit from an environment without the shell

- **WHEN** a Git client outside the development shell triggers the hook
- **THEN** the hook either runs with the pinned tools or fails with a message that names the missing environment
- **AND** it does not silently skip the gate

#### Scenario: Install from native Windows

- **WHEN** the user bootstraps the declared native Windows development environment
- **THEN** lefthook is installed for the native checkout and works from native Git and Fork
- **AND** re-entry installs no duplicate hook and retires no unrelated hook without review

#### Scenario: Default native Windows gate fails

- **WHEN** the real default Windows precommit gate invokes the checker
- **THEN** it forwards `-SkipFixtures` and propagates a nonzero checker exit as a failed commit
- **AND** isolated hook fixtures assert both behaviors without replacing the default Windows gate

### Requirement: A development shell on every supported system

Every declared Nix system SHALL retain a pinned development shell. Native Windows SHALL have a documented pinned native development environment rather than a fictitious Windows Nix flake system. Every supported host SHALL install its commit hook through its own environment. Shared repository tools SHALL be usable there; platform-only tools SHALL stay on the hosts that can execute their workflows.

#### Scenario: Clone on a supported host

- **WHEN** a maintainer enters the repository on any supported host
- **THEN** the declared development environment for that platform resolves
- **AND** the commit hook is installed in that working tree

#### Scenario: A supported system gains no shell

- **WHEN** the repository declares a supported Nix system without a development shell, or native Windows support without its bootstrap
- **THEN** a repository check fails

#### Scenario: Host-specific tool outside its host

- **WHEN** a maintainer enters the development shell on a host that cannot complete a host-specific tool's workflow
- **THEN** that tool is absent from that environment rather than present and unusable

### Requirement: Each gate runs its host's Nix implementation

Each Linux/Darwin CI gate SHALL use the Nix implementation declared by that host. Windows CI SHALL use native Windows tools for official DSC document-schema validation, read-only WinGet show parsing, PowerShell tests and applicable shared formatting, not Nix or a WSL-only substitute. Applicable Windows formatting SHALL run once; all existing non-format gates and the full fixture suite SHALL run in parallel Windows PowerShell 5.1 and locked PowerShell 7 jobs. Download caches SHALL contain archives only, not extracted installations; restored archives SHALL be verified against lock hashes on every use and CI SHALL provision fresh tools directories. The required `check (windows-latest)` SHALL aggregate all Windows children and fail when any child fails, is cancelled or is skipped. Windows checks SHALL be required alongside Linux, Darwin and live policy checks before main deployment can be accepted.

#### Scenario: An output evaluates on one implementation only

- **WHEN** a flake output evaluates under the runner's default Nix and fails under the Nix its host declares
- **THEN** the continuous-integration leg for that system fails

#### Scenario: Inspect gate equivalence

- **WHEN** a maintainer compares the gate command of a system's continuous-integration leg with the gate command on that system's host
- **THEN** both run the same Nix implementation and the same check set

#### Scenario: Windows configuration regresses

- **WHEN** the Windows document, script syntax or privilege/app ownership invariant fails native checks
- **THEN** the Windows job and protected-main acceptance fail even if both Nix jobs pass
- **AND** no successful Linux-only completion authorizes tailnet deployment

#### Scenario: A Windows child does not succeed

- **WHEN** any Windows formatting or host-check child fails, is cancelled or is skipped
- **THEN** the required `check (windows-latest)` aggregate fails
- **AND** successful sibling jobs do not authorize protected-main acceptance or tailnet deployment

#### Scenario: Restore a cached tool download

- **WHEN** a Windows CI job restores a downloaded archive from cache
- **THEN** it verifies the archive against its lock hash before extraction on that use
- **AND** it builds a fresh tools directory rather than restoring an extracted installation
