# repository-quality-gates Specification

## Purpose

Define how this repository enforces formatting before a commit and in continuous integration, so that the local gate and the remote gate read one configuration and cannot disagree.

## Requirements

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

### Requirement: Retiring a hook runner removes its hook

Replacing the hook runner SHALL leave no hook file from the previous runner in the working tree.

#### Scenario: Working tree carries the previous hook

- **WHEN** the hook runner is replaced in a working tree that already has the previous runner's hook installed
- **THEN** the previous hook file is removed or overwritten
- **AND** committing runs the new gate exactly once

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

### Requirement: One package-set instance per system

The repository SHALL instantiate one Nixpkgs package set per supported system. Host configurations and flake outputs for that system SHALL consume that instance. A host SHALL NOT instantiate a second package set. The overlay SHALL derive each local package attribute from a matching `packages/<name>/package.nix` directory, with package-set-only arguments. It SHALL explicitly re-export pinned external packages and apply the NixOS options override. Modules SHALL consume repository packages from that package set. A host package check SHALL assert the derivation that the host installs. Package outputs and program checks SHALL use `meta.platforms` rather than a host-kind branch to select supported systems.

#### Scenario: Compare a shared artifact

- **WHEN** an artifact appears both as a flake output and in a host's declared scope
- **THEN** both resolve to the same derivation
- **AND** the host package check fails if its declared packages contain a different derivation

#### Scenario: A host declares its own package-set options

- **WHEN** a host module declares package-set options that the supplied instance already fixes
- **THEN** evaluation fails rather than silently ignoring those options

#### Scenario: A package argument changes

- **WHEN** a maintainer changes an argument supplied by the shared package set
- **THEN** both the host-installed derivation and its program check change together
- **AND** no second package call can retain the old argument

#### Scenario: A package is unavailable on one platform

- **WHEN** a repository package declares platforms that exclude the current system
- **THEN** its package output and program check are absent on that system
- **AND** no output reads a host kind to make that package decision

### Requirement: OpenSpec package consistency

The workstation checks SHALL verify that the ordinary host-installed OpenSpec executable reports the version declared by its Nix package and is the same derivation exposed by the shared package set. They SHALL NOT require a hard-coded historical version after a reviewed update or depend on an OMP wrapper/runtime plugin package.

#### Scenario: Package and executable disagree

- **WHEN** the packaged executable reports a version different from its Nix package metadata
- **THEN** the workstation release gate fails

### Requirement: Archived change completeness

The portable local/CI OpenSpec gate SHALL reject archived changes with incomplete tasks and retain strict scenario/task-numbering validation for active contracts. It SHALL execute both all-contract and archived-contract validation and fail if the host CLI lacks archived support; retiring the Nix gate SHALL not weaken completeness.

#### Scenario: An incomplete change is archived

- **WHEN** an archived change contains an unchecked task
- **THEN** the portable local/CI OpenSpec gate fails

#### Scenario: Archived validation is unsupported

- **WHEN** the selected host or CI CLI lacks --archived
- **THEN** the gate fails clearly rather than omitting archived validation

### Requirement: One typed host declaration per host

Each host SHALL describe its identity through one standalone `hosts/<name>/host.nix` declaration validated by the module system, importing facts shared with user templates from home/.chezmoidata/\*.toml rather than duplicating them. The directory name SHALL set the host name. The declaration SHALL set the interactive user name, system, kind, builder capacity, and tailnet facts. The flake SHALL evaluate that declaration alone and expose the result through the read-only `fleet.hosts` registry. Each configuration SHALL receive the same facts through a typed `fleet.hosts` option. A module that needs a fact about its own host SHALL read `config.host`; a module that needs a fact about a peer SHALL read `config.fleet.hosts`. No host fact SHALL travel to a Nix module as an untyped argument; chezmoi SHALL read the same shared TOML facts directly.

#### Scenario: A host omits a required value

- **WHEN** a standalone declaration omits `host.username`, `host.system`, or `host.kind`
- **THEN** registry evaluation fails with an error that names the missing option
- **AND** the failure occurs before any host configuration consumes the value

#### Scenario: A host misstates its kind

- **WHEN** a declaration gives `host.kind` a value outside the permitted kinds
- **THEN** registry evaluation fails with a type error that names `host.kind`

#### Scenario: A module reads a host value

- **WHEN** a system or user-scope module needs its host name or interactive user name
- **THEN** it reads the declaration of the host that manages it
- **AND** the host passes that fact through no additional argument

#### Scenario: A peer-scope module reads a builder fact

- **WHEN** a module needs a builder's name, system, or logical core count
- **THEN** it reads the typed registry entry for that builder
- **AND** it does not force the builder's evaluated host configuration

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

### Requirement: Platform baselines contain no host role

A platform baseline SHALL contain only configuration required by every host of that platform. A host SHALL select its optional machine roles explicitly. A role SHALL live under the platform that can run it, and shared modules SHALL contain no platform branch.

#### Scenario: Add a second Darwin host

- **WHEN** a maintainer declares a Darwin host without desktop, database, container-client, or Air-client roles
- **THEN** the host receives the Darwin baseline
- **AND** it receives no Homebrew application set, Dock application list, PostgreSQL service, Colima profile, or Air endpoint

#### Scenario: Select a role

- **WHEN** a host imports one role
- **THEN** the role's system settings and matching chezmoi user configuration apply together
- **AND** no platform baseline imports that role implicitly

#### Scenario: Inspect shared modules

- **WHEN** repository validation inspects a shared module
- **THEN** the module contains no Darwin, NixOS, WSL, or Windows condition

#### Scenario: Remove the temporary Air integration

- **WHEN** the Air role, its package directory, Air check and output wiring, and `macbook-air` peer entry are removed
- **THEN** the host still evaluates with every durable role and release gate, including the desktop SSH configuration check
- **AND** no generated package, check, launchd agent, SSH alias, chezmoi file, policy entry, or credential reference names the Air

### Requirement: One declaration owns each host fact

Each host-specific fact SHALL have one declaration: name is the host directory key; facts shared with user configuration live in home/.chezmoidata/\*.toml and remaining system facts in hosts/<name>/host.nix. Nix SHALL validate them through config.host and config.fleet.hosts; chezmoi SHALL read the same shared TOML. Every generated file and check SHALL derive values from that owner. A check SHALL NOT repeat a machine name, user name, durable path, application, or resource value. The temporary Air integration SHALL remain role-owned until its removal under issue #17; it SHALL NOT gain a durable host endpoint declaration.

#### Scenario: Change a screenshot directory

- **WHEN** a host changes its declared screenshot directory
- **THEN** the system default and chezmoi directory preparation use the new path
- **AND** neither consumer needs an edit

#### Scenario: Change an application record

- **WHEN** a maintainer changes a declared Homebrew application's cask, application path, Dock position, or login start
- **THEN** the generated Homebrew cask set, Dock layout, and login agents change together
- **AND** no second application list exists

#### Scenario: Reject a login start without an application path

- **WHEN** an application record requests a login start but declares no application path
- **THEN** evaluation fails with a message that names the record

#### Scenario: Change a container resource

- **WHEN** a maintainer changes one declared Colima capacity or mount value
- **THEN** the generated profile and its configuration check use the new value
- **AND** no second resource literal needs an edit

#### Scenario: Keep the temporary endpoint removable

- **WHEN** the Air role is selected
- **THEN** its current SSH aliases, batch command, SMB agent, link, and checks are available
- **AND** durable host declarations and platform baselines contain no Air endpoint value

### Requirement: Nix policy uses supported platform interfaces

The Mac SHALL retain its pinned registry and disabled legacy channels, using Determinate automatic garbage collection without auto-optimise-store or another maintenance job. No native Windows Nix daemon, Linux weekly GC/optimisation timers or retired remote-builder trust SHALL be declared. Generic Nix CI SHALL retain its explicitly selected implementation/cache behavior.

#### Scenario: Evaluate each native adapter

- **WHEN** the Mac evaluates Nix settings and native Windows setup is inspected
- **THEN** the Mac retains its registry/channel policy and Determinate automatic GC without automatic store optimisation
- **AND** Windows declares no Nix/WSL maintenance service
- **AND** the Mac no longer trusts a non-root SSH user solely for importing retired Korolev builder paths

### Requirement: Installed and activation programs are packages with behavior checks

Each reusable repository-owned user, setup or modify-filter program SHALL be a package under `packages/<name>/package.nix`, with `meta.description`, `meta.mainProgram`, and `meta.platforms`. Each SHALL have `packages/<name>/tests.nix` that runs the built program against doubles or fixtures and asserts observable behavior. Python programs SHALL also run their stdlib unit tests during package builds. A module SHALL NOT interpolate a source script path into activation. Thin chezmoi scripts SHALL invoke installed packaged helpers; a modify filter SHALL change only declared keys and preserve unrelated app state.

#### Scenario: Inspect a program a host installs

- **WHEN** a maintainer lists the repository-owned user and activation programs used by the configuration
- **THEN** each resolves to `packages/<name>/package.nix`
- **AND** each has a sibling `tests.nix` that exercises its behavior
- **AND** the tested helper, modify-filter and switch-wrapper derivations match those installed in the host's system-declared user package set

#### Scenario: A program regresses

- **WHEN** a change makes a packaged program write where the current state already matches, or exit zero on an error it does not document
- **THEN** the program's check fails

#### Scenario: A Python program is imported by its test

- **WHEN** a test imports a packaged Python program
- **THEN** the import performs no subprocess call, reads no command-line argument, and exits nothing
- **AND** the program exposes `main(argv: Sequence[str] | None = None) -> int`, which owns `argparse`, parses `sys.argv[1:]` when `argv` is `None`, and returns the console script's exit status

### Requirement: Packaged program behavior checks

A packaged program's check SHALL execute the packaged program against controlled fixtures and stub executables. It SHALL assert observable exit status, output, and calls rather than script source text.

#### Scenario: Program source changes without behavior changing

- **WHEN** a program's source text changes but its observable behavior remains the same
- **THEN** its behavior check passes

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

### Requirement: Encrypted source validation covers every managed secret

Repository checks SHALL require every declared managed secret to have a private encrypted chezmoi source with a valid age payload. Missing ciphertext, plaintext substitution or removal of its private/encrypted attributes SHALL fail without decrypting production data. Format validation SHALL not be reported as proof of recipient access.

#### Scenario: Add a secret with a new name

- **WHEN** a new managed credential is declared
- **THEN** its source is checked independent of the credential name
- **AND** missing, plaintext or nonprivate source state fails with the file path

#### Scenario: Commit plaintext instead of ciphertext

- **WHEN** a tracked managed secret contains plaintext or a malformed age payload
- **THEN** repository validation fails and names the source path without printing its contents

#### Scenario: Prove the detector

- **WHEN** positive encrypted fixtures and plaintext, truncated, missing and incorrectly attributed fixtures run
- **THEN** encrypted fixtures pass and every invalid fixture fails
- **AND** an isolated synthetic age round trip verifies private file permissions without a production identity

#### Scenario: Preserve encryption metadata

- **WHEN** repository validation examines a supported age encoding
- **THEN** it validates encryption framing rather than treating an age header alone as sufficient
- **AND** live recipient access remains a separate Mac acceptance gate

### Requirement: User configuration checks render the tracked source

Each host's user-configuration check SHALL render its actual chezmoi source in an isolated home using the same shared facts as the host configuration. It SHALL retain effective shell, SSH, package and container assertions formerly derived from Home Manager. Checks SHALL not access production secrets, live applications or remote services.

#### Scenario: A template regresses

- **WHEN** an SSH endpoint, shell hook or Colima profile template changes incorrectly
- **THEN** its host's rendered configuration check fails on the affected effective assertion

#### Scenario: Validate without host credentials

- **WHEN** checks run in CI without production keys or provider access
- **THEN** ordinary user configuration and synthetic-secret fixtures are verified
- **AND** no live user setup command, production decryption or remote connection runs

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
