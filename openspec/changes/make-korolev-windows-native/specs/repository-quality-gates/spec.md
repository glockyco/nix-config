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
- **AND** the Windows CI leg runs the same native checks

### Requirement: The commit hook is installed from the development shell

Entering the declared development environment SHALL install lefthook in that checkout. Darwin/Linux SHALL retain the pinned Nix shell; Windows SHALL use an explicit native bootstrap with pinned tools. Git clients outside the environment SHALL resolve those pinned tools or fail with a missing-environment diagnostic. Platform-specific dispatch SHALL never silently skip staged Nix validation.

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

Each Linux/Darwin CI gate SHALL use the Nix implementation declared by that host. Windows CI SHALL use native Windows tools for official DSC document-schema validation, read-only WinGet show parsing, PowerShell tests and applicable shared formatting, not Nix or a WSL-only substitute. Windows checks SHALL be required alongside Linux, Darwin and live policy checks before main deployment can be accepted.

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
