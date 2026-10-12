## MODIFIED Requirements

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
