# Spec Delta

## MODIFIED Requirements

### Requirement: One formatting configuration for both gates

Local and CI formatting SHALL consume the existing single platform-neutral formatter declaration. The PowerShell 7 Windows adapter SHALL use locked native tooling. It SHALL NOT format staged Nix files or invoke WSL, and it SHALL name staged Nix files as left to the Nix formatting checks in CI and on the Mac. Native-only work SHALL not require Nix. Missing tools SHALL fail rather than silently skip. Windows engine checks SHALL use proportional mocked behavior coverage, not mutations of a bespoke checker.

#### Scenario: Stage native-only work

- **WHEN** native Windows precommit checks native-only staged files
- **THEN** PowerShell 7 invokes declared formatters and the engine's static/schema boundary checks
- **AND** it does not invoke DSC document validation or a second PowerShell host

#### Scenario: Stage Nix without its environment

- **WHEN** a native Windows commit stages Nix files
- **THEN** the hook checks the other staged files and names the Nix files as checked by CI
- **AND** CI's Nix formatting check rejects a pull request with unformatted Nix

#### Scenario: Unformatted file reaches a commit

- **WHEN** staged content that the platform's hook formats differs from shared formatter output
- **THEN** the commit gate rejects it

#### Scenario: Unformatted file reaches continuous integration

- **WHEN** committed content differs from shared formatter output
- **THEN** CI fails

#### Scenario: A formatter is added

- **WHEN** the shared formatter declaration gains a formatter
- **THEN** both gates consume it without a duplicate list edit

### Requirement: The commit hook is installed from the development shell

Darwin SHALL retain pinned Nix-shell hook installation. Windows SHALL retain explicit repository-local native development bootstrap and lefthook installation, running all hooks and tooling under PowerShell 7. Only the separate minimal fresh-machine pwsh/Git/chezmoi prerequisite bootstrap MAY use Windows PowerShell 5.1. Re-entry SHALL not duplicate hooks or silently retire unrelated hooks. Git clients outside the declared environment SHALL resolve pinned tools or fail with an actionable diagnostic. No hook SHALL invoke WSL.

#### Scenario: Bootstrap native development

- **WHEN** a standard Windows user enters the native development environment
- **THEN** pinned tools and local test dependencies resolve and lefthook is installed for that checkout
- **AND** subsequent Git/Fork commits invoke the PowerShell 7 gate and propagate failures

#### Scenario: First entry into the shell

- **WHEN** the declared environment is entered without an installed hook
- **THEN** the hook is installed and subsequent commits run the gate

#### Scenario: Commit from an environment without the shell

- **WHEN** Git invokes a hook outside the declared environment
- **THEN** pinned tooling resolves or an actionable missing-environment error rejects the commit
- **AND** staged Nix files are either validated or named as left to CI, never skipped silently

### Requirement: A development shell on every supported system

Every declared Nix system SHALL retain a pinned shell; native Windows SHALL use its documented pinned bootstrap, not a Windows flake system. macbook-pro SHALL be the only managed Nix workstation; x86_64-linux SHALL remain CI-only for applicable generic checks. Every actual supported workstation SHALL install hooks through its own environment. Host-only tools SHALL remain only where their workflow can execute.

#### Scenario: Clone on a supported host

- **WHEN** a maintainer enters the repository on Mac or native Windows
- **THEN** that platform's declared environment resolves and installs the hook

#### Scenario: A supported system gains no shell

- **WHEN** a declared Nix system lacks its shell or Windows lacks its bootstrap
- **THEN** the repository check fails

#### Scenario: Host-specific tool outside its host

- **WHEN** an environment cannot execute a host-specific workflow
- **THEN** the tool is absent rather than present and unusable

### Requirement: Each gate runs its host's Nix implementation

Darwin gates SHALL use the Mac's declared Nix implementation, and generic Linux CI SHALL use its explicitly declared CI implementation without resolving a retired host. Windows SHALL use one native PowerShell 7 CI job named `check (windows-latest)` with applicable shared formatting, built-in JSON-schema validation, PSScriptAnalyzer, parser checks, privilege invariants and mocked Pester behavior tests. CI SHALL neither provision WinGet/DSC providers nor apply workstation resources. Pester 5 and PSScriptAnalyzer SHALL be pinned development dependencies installed through PSResourceGet into repository-local or runner-local paths, never an owner's global profile. Failed or skipped required checks SHALL not count as successful Windows acceptance.

#### Scenario: Run proportional Windows CI

- **WHEN** a pull request changes the Windows layer
- **THEN** one pwsh-only job runs the schema, analyzer, invariants and mocked behavior tests
- **AND** applicable shared formatting runs once and timings are recorded
- **AND** no Windows PowerShell 5.1 matrix, WinGet Configuration provider provisioning or live apply runs

#### Scenario: Isolate test dependencies

- **WHEN** local checks or CI provision Pester and PSScriptAnalyzer
- **THEN** pinned modules are available only from the selected development dependency path
- **AND** missing modules fail with an actionable setup command rather than skip tests

#### Scenario: An output evaluates on one implementation only

- **WHEN** a flake output fails under its host's declared Nix despite passing under the runner default
- **THEN** that system's CI leg fails

#### Scenario: Inspect gate equivalence

- **WHEN** local and CI gate commands are compared
- **THEN** Nix hosts use the same declared Nix and Windows uses the same PowerShell 7 static/mock check set

### Requirement: One declaration for each cross-platform fact

A shared user/platform fact SHALL have one declaration consumed by applicable Mac Nix, native Windows chezmoi and checks. Portable user intent SHALL not imply identical platform package ownership. The Nix binary-cache declaration SHALL remain shared between Mac and applicable CI; Windows SHALL not consume Linux Nix settings. Retired host data SHALL not remain a second owner.

#### Scenario: Rotate the binary cache key

- **WHEN** the declared cache public key changes
- **THEN** Mac and applicable Nix CI consume that declaration without a second edit
- **AND** no Korolev/Linux Nix-settings check remains

#### Scenario: Compare user-package and chezmoi wiring of both hosts

- **WHEN** Mac and native Windows setup are compared
- **THEN** shared user facts come from one declaration
- **AND** Mac Nix and Windows native owners apply only their platform-specific package/program behavior

#### Scenario: Check each host against the declaration

- **WHEN** applicable host checks run
- **THEN** they assert their host's declared facts instead of literal copies
- **AND** Mac cache assertions read the shared cache declaration while native Windows checks retain their actual native tool ownership

### Requirement: Hosts declared by directory

Each managed Nix host SHALL have hosts/<name>/{host,default}.nix with standalone typed facts keyed by its directory. Only Darwin host configurations SHALL remain; Windows SHALL keep platform-qualified chezmoi facts and durable peer policy data, not a Nix configuration. Host systems SHALL derive from the registry, with Linux CI-only support explicitly declared separately. Adding a same-system Darwin host SHALL need no new output branch.

#### Scenario: Add a second host on an existing system

- **WHEN** a complete second Darwin host directory is added on an existing system
- **THEN** its configuration and generic host gates appear without changing supported host systems

#### Scenario: A host directory is incomplete

- **WHEN** a host directory lacks host.nix or default.nix
- **THEN** fleetSurface fails and names the missing file

#### Scenario: A host declares an unknown kind

- **WHEN** a Nix host declares any kind other than darwin
- **THEN** typed evaluation fails naming host.kind and its permitted kind

#### Scenario: A host declares a mismatched system

- **WHEN** a generated host configuration disagrees with its registry system
- **THEN** fleetSurface fails for that host

### Requirement: Nix policy uses supported platform interfaces

The Mac SHALL retain its pinned registry and disabled legacy channels, using Determinate automatic garbage collection without auto-optimise-store or another maintenance job. No native Windows Nix daemon, Linux weekly GC/optimisation timers or retired remote-builder trust SHALL be declared. Generic Nix CI SHALL retain its explicitly selected implementation/cache behavior.

#### Scenario: Evaluate each native adapter

- **WHEN** the Mac evaluates Nix settings and native Windows setup is inspected
- **THEN** the Mac retains its registry/channel policy and Determinate automatic GC without automatic store optimisation
- **AND** Windows declares no Nix/WSL maintenance service
- **AND** the Mac no longer trusts a non-root SSH user solely for importing retired Korolev builder paths

### Requirement: Archived change completeness

The portable local/CI OpenSpec gate SHALL reject archived changes with incomplete tasks and retain strict scenario/task-numbering validation for active contracts. It SHALL execute both all-contract and archived-contract validation and fail if the host CLI lacks archived support; retiring the Nix gate SHALL not weaken completeness.

#### Scenario: An incomplete change is archived

- **WHEN** an archived change contains an unchecked task
- **THEN** the portable local/CI OpenSpec gate fails

#### Scenario: Archived validation is unsupported

- **WHEN** the selected host or CI CLI lacks --archived
- **THEN** the gate fails clearly rather than omitting archived validation

## ADDED Requirements

### Requirement: Managed Nix host gates

Checks reading managed Nix configuration SHALL be generated per registry host, named with its host prefix, and consume typed facts. Every system gate SHALL read config.system.build.toplevel. Native Windows checks SHALL use Windows fixtures, not a phantom Linux registry host. No Korolev/Linux host closure, builder, credential, container, browser ABI, font, automount or Mac-batch gate SHALL remain.

#### Scenario: Rename a host

- **WHEN** a managed Nix host directory is renamed
- **THEN** all its gates use the new prefix and none use the old prefix
- **AND** no host-specific lookup outside that directory needs editing

#### Scenario: Inspect the remaining system gates

- **WHEN** remaining Nix system gates are inspected
- **THEN** each reads its Darwin configuration's system.build.toplevel
- **AND** no gate reads nixosConfigurations.korolev

#### Scenario: Rename a user's account

- **WHEN** a host changes its declared username
- **THEN** its rendered chezmoi/system-user-package gates use that user without a second edit

### Requirement: Declared managed-host and native-peer facts

Modules SHALL read managed Nix peer facts from the typed registry and non-Nix peer policy facts from their single declared peer source, without evaluating another host configuration. Native Windows Korolev SHALL remain a durable reachable peer after its Nix host is removed. Policy SHALL derive synthetic/unreachable deny targets from declared reachability, not a hard-coded Linux host. No root daemon-builder client SHALL remain.

#### Scenario: A declared peer changes its name or tag

- **WHEN** a peer's source declaration changes
- **THEN** consuming endpoints/policy use the new declared facts
- **AND** no consumer evaluates another host's system configuration or generates a root builder key path

#### Scenario: An unreachable host is added

- **WHEN** a synthetic managed-host fixture declares tailnet.reachable = false
- **THEN** rendered policy denies port 22 to its tag from every reachable source without a renderer edit

### Requirement: Portable strict OpenSpec consumer gate

Local lefthook SHALL use host OpenSpec (Mac Nix package, Windows exact npm pin), require --archived support and run both openspec validate --all --strict --no-interactive and openspec validate --archived --strict --no-interactive. CI SHALL call the released omp-agent-setup reusable workflow at a reviewed full commit SHA. Neither path SHALL delegate to WSL, silently skip or retain personal-omp-plugin as a Nix check dependency.

#### Scenario: Validate from an actual local host

- **WHEN** a Mac or native Windows commit triggers OpenSpec validation
- **THEN** the host's declared CLI runs both strict noninteractive validations in that checkout
- **AND** missing tools, unsupported archived validation or either nonzero status fail the hook

#### Scenario: Validate the caller revision in CI

- **WHEN** nix-config CI calls glockyco/omp-agent-setup/.github/workflows/openspec.yml at its reviewed released SHA with openspec-root '.'
- **THEN** the reusable workflow pins its own OpenSpec and validates the caller's checkout with both commands
- **AND** no caller-selected version, weakened flag set or archived opt-out is passed

#### Scenario: Complete the consumer cutover

- **WHEN** portable local and CI validation are accepted
- **THEN** personal-omp-plugin and its OpenSpec/adapter-freshness wiring are removed from the flake and lock
- **AND** personal runtime plugins remain OMP-manager-owned
- **AND** omp-agent-setup's own CI owns adapter freshness while its lib.openspecCheck remains available to unmigrated consumers

## REMOVED Requirements

### Requirement: Darwin gates run from the Linux host

**Reason**: Korolev no longer has a Linux Nix caller, root builder client or delegated Windows Nix hook.
**Migration**: Run Nix evaluation, builds and activation on the Mac and applicable CI; Windows rejects staged Nix files with actionable Mac/CI guidance. Native user SSH preserves command status but is not a restored remote-builder gate.

### Requirement: Generated OpenSpec adapter freshness

**Reason**: nix-config owns no generated plugin adapters; its input duplicates omp-agent-setup's release gate.
**Migration**: Require portable strict consumer validation from the reusable workflow and local host CLI. Adapter freshness runs in omp-agent-setup's own CI; remove openspecAdapters and personal-omp-plugin only after consumer cutover acceptance.

### Requirement: Host gates generated per host

**Reason**: Its Darwin-versus-NixOS system-gate scenario requires the configuration kind and host that this change removes.
**Migration**: Use `Managed Nix host gates`, preserving per-host generation, typed facts, rename behavior and real system-closure validation for the remaining Darwin hosts, alongside native Windows fixtures.

### Requirement: Peer facts come from the registry

**Reason**: Its remote-builder/root-key scenario is retired and non-Nix native Windows membership must not be represented as a Nix host.
**Migration**: Use `Declared managed-host and native-peer facts`, preserving one declaration per peer, no cross-host configuration evaluation and synthetic reachability checks without a daemon builder.
