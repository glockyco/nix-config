# repository-quality-gates Specification

## Purpose

Define how this repository enforces formatting before a commit and in continuous integration, so that the local gate and the remote gate read one configuration and cannot disagree.

## Requirements

### Requirement: One formatting configuration for both gates

Local and CI formatting SHALL consume the existing single platform-neutral formatter declaration. The PowerShell 7 Windows adapter SHALL retain locked native tooling and same-checkout staged Nix validation. Native-only work SHALL not require Nix. Missing tools and unavailable staged Nix validation SHALL fail rather than silently skip. Windows engine checks SHALL use proportional mocked behavior coverage, not mutations of a bespoke checker.

#### Scenario: Stage native-only work

- **WHEN** native Windows precommit checks native-only staged files
- **THEN** PowerShell 7 invokes declared formatters and the engine's static/schema boundary checks
- **AND** it does not invoke DSC document validation or a second PowerShell host

#### Scenario: Stage Nix without its environment

- **WHEN** staged Nix cannot be checked in the same checkout's declared Nix environment
- **THEN** the hook rejects the commit with an actionable diagnostic

#### Scenario: Unformatted file reaches a commit

- **WHEN** staged content differs from shared formatter output
- **THEN** the commit gate rejects it

#### Scenario: Unformatted file reaches continuous integration

- **WHEN** committed content differs from shared formatter output
- **THEN** CI fails

#### Scenario: A formatter is added

- **WHEN** the shared formatter declaration gains a formatter
- **THEN** both gates consume it without a duplicate list edit

### Requirement: The commit hook is installed from the development shell

Darwin/Linux SHALL retain pinned Nix-shell hook installation. Windows SHALL retain explicit repository-local native development bootstrap and lefthook installation, running all hooks and tooling under PowerShell 7. Only the separate minimal fresh-machine pwsh/Git/chezmoi prerequisite bootstrap MAY use Windows PowerShell 5.1. Re-entry SHALL not duplicate hooks or silently retire unrelated hooks. Git clients outside the declared environment SHALL resolve pinned tools or fail with an actionable diagnostic.

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
- **AND** staged Nix validation is never silently skipped

### Requirement: Retiring a hook runner removes its hook

Replacing the hook runner SHALL leave no hook file from the previous runner in the working tree.

#### Scenario: Working tree carries the previous hook

- **WHEN** the hook runner is replaced in a working tree that already has the previous runner's hook installed
- **THEN** the previous hook file is removed or overwritten
- **AND** committing runs the new gate exactly once

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

Linux and Darwin SHALL retain each host's declared Nix implementation. Windows SHALL use one native PowerShell 7 CI job named `check (windows-latest)` with applicable shared formatting, built-in JSON-schema validation, PSScriptAnalyzer, parser checks, privilege invariants and mocked Pester behavior tests. CI SHALL neither provision WinGet/DSC providers nor apply workstation resources. Pester 5 and PSScriptAnalyzer SHALL be pinned development dependencies installed through PSResourceGet into repository-local or runner-local paths, never an owner's global profile. The job SHALL emit gate durations and aim for about two minutes. Failed or skipped required checks SHALL not count as successful Windows acceptance.

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

### Requirement: Darwin gates run from the Linux host

The Linux host SHALL be able to build every `aarch64-darwin` check of the repository through the declared Darwin remote builder. The result SHALL be the same derivation that the Darwin host builds locally. A gate that reads the Darwin store, such as the build-plan inspection, SHALL run on the Darwin host through the tailnet SSH endpoint.

#### Scenario: Run all checks from one host

- **WHEN** the operator runs `nix flake check --all-systems` on the Linux host while the Darwin host is connected
- **THEN** every `x86_64-linux` check builds locally, every `aarch64-darwin` check builds on the Darwin host, and the command exits 0

#### Scenario: Compare with the Darwin host's own gate

- **WHEN** the same revision is checked on the Darwin host with `nix flake check`
- **THEN** each `aarch64-darwin` check resolves to the same derivation path as the one built from the Linux host

#### Scenario: Inspect build plans from the Linux host

- **WHEN** the operator runs the documented build-plan inspection command from the Linux host
- **THEN** the inspection executes on the Darwin host over the tailnet SSH endpoint and reports its result to the Linux host
- **AND** the SSH client's exit status equals the remote command's exit status

#### Scenario: A remote gate fails

- **WHEN** a gate on the Darwin host exits nonzero
- **THEN** the Linux caller receives that nonzero status without a parsing wrapper or success fallback

### Requirement: OpenSpec package consistency

The workstation checks SHALL verify that the ordinary host-installed OpenSpec executable reports the version declared by its Nix package and is the same derivation exposed by the shared package set. They SHALL NOT require a hard-coded historical version after a reviewed update or depend on an OMP wrapper/runtime plugin package.

#### Scenario: Package and executable disagree

- **WHEN** the packaged executable reports a version different from its Nix package metadata
- **THEN** the workstation release gate fails

### Requirement: Generated OpenSpec adapter freshness

The workstation checks SHALL verify that the personal plugin's tracked OpenSpec commands and skills match the selected generator independently of its runtime installation. The independently pinned build-time `lib.openspecCheck` and required generator tooling SHALL remain available after removal of plugin runtime package exports. An OpenSpec update SHALL require review of generated changes in `omp-agent-setup` before publication and review of the check-tool pin here before merge. Published marketplace commands SHALL use `/personal:opsx-*` without compatibility aliases; this repository SHALL NOT run `openspec init` or duplicate generated adapters.

#### Scenario: Generator output changes

- **WHEN** the selected OpenSpec package would rewrite a tracked adapter
- **THEN** the release gate fails until the generated difference is reviewed and committed in its owning plugin repository

### Requirement: Archived change completeness

The workstation checks SHALL reject an archived OpenSpec change that contains an incomplete task. Strict validation SHALL also retain scenario and task-numbering checks for active contracts.

#### Scenario: An incomplete change is archived

- **WHEN** an archived change contains an unchecked task
- **THEN** the workstation release gate fails

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

The repository SHALL have one directory per managed host under `hosts/`. Each directory SHALL contain `host.nix` and `default.nix`. The flake SHALL evaluate each standalone `host.nix` against the shared host option definitions, with the directory name as `host.name`. The resulting read-only `fleet.hosts` registry SHALL key hosts by name. Supported systems and host configurations SHALL derive from that registry. Adding a host on an existing system SHALL require no new flake output branch.

#### Scenario: Add a second host on an existing system

- **WHEN** a maintainer adds a complete host directory for a second host on an existing system
- **THEN** the flake exposes a configuration under the new host name
- **AND** the supported systems remain unchanged
- **AND** every generic host gate exists for the new host

#### Scenario: A host directory is incomplete

- **WHEN** a host directory lacks `host.nix` or `default.nix`
- **THEN** `fleetSurface` fails and names that directory and its missing file

#### Scenario: A host declares an unknown kind

- **WHEN** a host's standalone declaration sets a kind other than `darwin` or `nixos`
- **THEN** evaluation fails with a type error that names `host.kind` and the permitted kinds

#### Scenario: A host declares a mismatched system

- **WHEN** a generated host configuration evaluates with a system different from its registry declaration
- **THEN** `fleetSurface` fails for that host

### Requirement: Host gates generated per host

Every check that reads one host configuration SHALL be generated from `fleet.hosts` for each host on the system. Its name SHALL start with the host name. Such a check SHALL read host and user values from that host's typed declaration, not from literals. A kind-specific check SHALL exist for every host of that kind. Every system gate SHALL read `config.system.build.toplevel`.

#### Scenario: Rename a host

- **WHEN** a maintainer renames a host directory
- **THEN** every gate for that host exists under its new name
- **AND** no gate under its old name remains
- **AND** no host-specific lookup outside that directory needs an edit

#### Scenario: Compare Darwin and NixOS system gates

- **WHEN** a maintainer compares the system gates for a Darwin host and a NixOS host
- **THEN** both read the generated host's `config.system.build.toplevel`

#### Scenario: Rename a user's account

- **WHEN** a host changes the interactive username in its standalone declaration
- **THEN** each gate that renders its chezmoi configuration or reads its system-declared user packages reads the new user
- **AND** the gate definition needs no edit

### Requirement: Peer facts come from the registry

A module SHALL read other managed hosts' name, system, user, builder capacity, and tailnet facts from its typed `config.fleet.hosts` registry. It SHALL NOT evaluate another host's Darwin or NixOS configuration to obtain those facts. Remote builders SHALL derive from other registry hosts with non-null `build.logicalCores`. The tailnet renderer SHALL derive its port-22 deny targets from registry hosts with `tailnet.reachable = false`.

#### Scenario: A builder host changes its system or name

- **WHEN** a remote builder's standalone declaration changes its system or directory name
- **THEN** a consuming host's builder settings use the new registry facts
- **AND** its root SSH builder key path derives from the new builder name
- **AND** no consuming module evaluates the builder's system configuration

#### Scenario: An unreachable host is added

- **WHEN** a new managed host declares `tailnet.reachable = false`
- **THEN** the rendered policy denies port 22 to its tailnet tag from every reachable source
- **AND** no renderer edit is required

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

- **WHEN** a maintainer changes a declared Homebrew application's cask, application path, or Dock position
- **THEN** the generated Homebrew cask set and Dock layout change together
- **AND** no second application list exists

#### Scenario: Change a container resource

- **WHEN** a maintainer changes one declared Colima capacity or mount value
- **THEN** the generated profile and its configuration check use the new value
- **AND** no second resource literal needs an edit

#### Scenario: Keep the temporary endpoint removable

- **WHEN** the Air role is selected
- **THEN** its current SSH aliases, batch command, SMB agent, link, and checks are available
- **AND** durable host declarations and platform baselines contain no Air endpoint value

### Requirement: Nix policy uses supported platform interfaces

The host configurations SHALL share one pinned registry, disabled legacy channel policy, and maintenance intent. NixOS SHALL schedule native weekly garbage collection and store optimisation. Darwin SHALL use Determinate Nix's automatic garbage collection without setting `auto-optimise-store` or adding an independent maintenance job; its pinned Determinate module has no scheduled store optimiser.

#### Scenario: Evaluate each native adapter

- **WHEN** the Darwin and NixOS hosts evaluate their Nix settings
- **THEN** both use the pinned registry and disable legacy channel lookup
- **AND** Korolev has weekly native GC and optimisation timers
- **AND** Darwin retains its trusted SSH builder user and uses Determinate's automatic GC
- **AND** Darwin does not enable automatic store optimisation

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

A fact that both platform scopes consume SHALL have one declaration. The Darwin scope, the NixOS scope, and every repository check that asserts the fact SHALL read that declaration. The binary cache substituter and its public key are such a fact. Shared chezmoi host data and portable user-package intent are such facts.

#### Scenario: Rotate the binary cache key

- **WHEN** a maintainer changes the binary cache public key in its declaration
- **THEN** both host configurations carry the new key
- **AND** the check that asserts the WSL host's Nix settings passes without a second edit

#### Scenario: Compare user-package and chezmoi wiring of both hosts

- **WHEN** a maintainer compares how each host selects the package set, installs user packages and renders user configuration
- **THEN** both hosts read those settings from one declaration
- **AND** platform modules add only platform package/program adapters and chezmoi templates add only necessary OS-specific behavior

#### Scenario: Check each host against the declaration

- **WHEN** the repository checks for a system run
- **THEN** a check asserts that the host on that system carries the declared substituter and the declared public key in its Nix settings
- **AND** the check reads the expected values from the declaration rather than from a literal

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
