## MODIFIED Requirements

### Requirement: Rendered Windows configuration artifacts

The repository SHALL maintain declarative JSON application/settings data, its schema, one PowerShell 7 convergence module and narrow standalone Zen-policy and Neo-driver Administrator scripts under `windows/`. The engine SHALL own installations and supported user settings. Chezmoi SHALL exclusively own user/app files. Nix activation SHALL neither write Windows paths nor apply Windows artifacts. No WinGet Configuration document or embedded DSC test/set scripts SHALL remain in the cutover PR.

#### Scenario: Inspect source offline

- **WHEN** the reviewed checkout is inspected without network or a Nix build
- **THEN** all Windows declarations and execution sources are available
- **AND** every destination has exactly one owner

#### Scenario: Render the artifacts

- **WHEN** the native checkout is reviewed
- **THEN** JSON data, its schema, the module and two narrow Administrator scripts are available without Nix rendering

#### Scenario: Evaluate without network

- **WHEN** source is inspected offline
- **THEN** declarations require no download or mutable Windows state

#### Scenario: Keep the operating-system boundary

- **WHEN** a Nix generation activates
- **THEN** it writes no Windows path and starts no Windows apply

### Requirement: User scope with explicit machine exceptions

The engine SHALL run as the standard interactive account and reject elevated execution. Only Zen, Tailscale and Docker Desktop SHALL declare machine scope and installer elevation. Other installations SHALL explicitly request user scope and SHALL NOT install competing runtime dependencies. The two Administrator scripts SHALL retain only Zen Program Files policies and Neo DLL/registration ownership. TeX Live, OpenSSH and tailnet enrollment SHALL remain separate owner operations.

#### Scenario: Install approved packages

- **WHEN** a missing package is installed
- **THEN** only an allowlisted machine installer may request Administrator credentials
- **AND** the engine and HKCU writes remain in the standard user's session

#### Scenario: Preserve Docker consent and least privilege

- **WHEN** Docker Desktop is installed
- **THEN** installer arguments are `install --quiet --backend=wsl-2 --no-windows-containers`
- **AND** configuration does not accept the license, enable always-run service or alter docker-users membership

#### Scenario: Reject an unsafe declaration

- **WHEN** data declares an unapproved machine package, HKLM write or centrally managed application
- **THEN** validation and execution fail before changes

#### Scenario: Apply user-scope resources

- **WHEN** the standard user applies the data
- **THEN** all resources except the three allowlisted installers complete without elevation

#### Scenario: Apply the browser exception

- **WHEN** Zen installation requests credentials and the owner separately applies policies
- **THEN** machine writes are limited to Zen installation and its Program Files policies

#### Scenario: Apply the keyboard driver exception

- **WHEN** the owner runs the Neo script as 64-bit Administrator
- **THEN** it writes only declared DLLs and b0000407 registration before an owner restart

#### Scenario: Reject another privileged declaration

- **WHEN** an undeclared privileged installer or machine-setting write is added
- **THEN** validation rejects it before execution

### Requirement: Pinned application set

Each application SHALL declare present or consumer-pinned policy. Bun SHALL be pinned to 1.3.13 for omp-agent-setup's .bun-version and OpenSpec to 1.14.0 for its reusable workflow. Any other version pin SHALL name a concrete consumer. Present applications SHALL install the selected latest WinGet version when missing and SHALL NOT trigger automatic upgrades. Reviewed archive/npm/font integrity selections SHALL retain reproducible missing-install delivery without downgrading existing newer applications. No application SHALL be downgraded automatically.

#### Scenario: Accept an existing present application

- **WHEN** a present application is installed
- **THEN** it is desired without querying the catalog or reinstalling it

#### Scenario: Protect a newer consumer-pinned install

- **WHEN** an installed pinned application is newer than its declared version
- **THEN** dry run reports the incompatibility
- **AND** apply refuses to downgrade it

#### Scenario: Exclude managed applications

- **WHEN** an application id appears in windows/managed-applications.json
- **THEN** repository validation and execution reject the competing declaration

#### Scenario: Install the declared set

- **WHEN** applications are missing
- **THEN** present applications install selected release payloads and consumer-pinned applications install their required versions

#### Scenario: Accept a newer vendor update

- **WHEN** a present application has updated itself
- **THEN** it is desired and no downgrade or reinstall occurs

#### Scenario: Detect an unpinned application

- **WHEN** a declaration lacks a policy or a pinned policy lacks a version and named consumer
- **THEN** schema or invariant validation fails

#### Scenario: Detect a managed-application conflict

- **WHEN** a declared application appears in the managed exclusion audit
- **THEN** validation fails and names its id

### Requirement: Declared Windows settings

The engine SHALL converge the existing supported registry, keyboard, Explorer, region, snapping, screenshot, dark appearance and animation settings. It SHALL preserve German and Austrian input methods, place en-GB first with no English input method, use en-GB UI override, and place German QWERTZ first/default with native Neo second. Native Neo driver installation and restart SHALL remain an owner prerequisite. Dark appearance SHALL accept generated Custom.theme when flags, transparency and wallpaper match.

#### Scenario: Preserve input and application state

- **WHEN** settings are converged
- **THEN** declared values match without deleting undeclared German/Austrian input methods or application-owned state
- **AND** Neo is not made the default or first keyboard layout

#### Scenario: Accept generated dark appearance

- **WHEN** dark flags, transparency and wallpaper match but Windows selects Custom.theme
- **THEN** the engine reports desired state without rewriting the theme path

#### Scenario: Apply the declared settings

- **WHEN** supported settings are applied
- **THEN** keyboard, Explorer, region, snapping, screenshot, dark appearance and disabled animation/transparency match

#### Scenario: Retain a generated custom theme

- **WHEN** dark appearance matches through Custom.theme
- **THEN** no active theme-file path is rewritten

#### Scenario: Prevent Firefox from starting at sign-in

- **WHEN** the engine converges startup settings
- **THEN** the declared Firefox startup value is absent and its managed installation is untouched

#### Scenario: Separate interface and input languages

- **WHEN** the owner signs in after language convergence
- **THEN** en-GB is the UI override without English input and Austrian/German inputs remain available

#### Scenario: Keep standard Office shortcuts

- **WHEN** Word uses German QWERTZ or native Neo after owner sign-in
- **THEN** QWERTZ remains first/default and standard Ctrl letter shortcuts retain their Windows meaning

#### Scenario: Reject a native Neo default

- **WHEN** data places native Neo first or makes it default
- **THEN** validation fails

#### Scenario: Resist an upstream default change

- **WHEN** an app update changes a chezmoi-owned disabled module setting
- **THEN** chezmoi restores its declared keys without assigning the file to the engine

### Requirement: Excluded Windows surface

The engine SHALL NOT write taskbar pinned-application lists, default application associations, CloudStore or centrally managed application installation state. Approved taskbar visibility SHALL remain declared as a typed setting with StuckRects3 byte 8 equal to 2. Explorer SHALL restart only when that value actually changes, never on a no-op apply.

#### Scenario: Keep unsupported surfaces user-owned

- **WHEN** the engine runs dry run or apply
- **THEN** no taskbar pinned-application list, default-association or CloudStore mutation is planned or executed

#### Scenario: Inspect the excluded surface

- **WHEN** the layer and runbook are reviewed
- **THEN** exclusions have reasons and no pinned-application list, association or CloudStore writes exist
- **AND** manual Night Light remains sunset to sunrise at 50 percent strength

#### Scenario: Preserve taskbar visibility idempotently

- **WHEN** taskbar auto-hide is enabled and apply runs
- **THEN** only the declared byte becomes 2 and Explorer restarts once
- **AND** an already-desired taskbar triggers neither a registry write nor an Explorer restart

### Requirement: Validation before and after apply

Data SHALL be validated against its schema and privilege/ownership invariants before execution. Dry run SHALL report every declared resource as desired or drift, make no persistent or temporary writes, return zero only for full convergence, return nonzero for drift and distinguish execution errors. Apply SHALL test before setting, mutate only drifted resources, confirm each change and propagate native failures by exit code rather than stderr. Installed WinGet discovery SHALL use one initial batch without scope filtering and, only after installs or updates, one fresh batch to verify all changed packages together. Portable executables SHALL resolve from their selected package root or approved PATH resolution, never an assumed WinGet Links directory.

#### Scenario: Preview a converged workstation

- **WHEN** the integrator runs dry run on a desired workstation
- **THEN** every resource is desired and exit status is zero
- **AND** no installer, download, filesystem, registry or PATH write occurs

#### Scenario: Detect drift without apply

- **WHEN** any resource differs
- **THEN** dry run names the resource and returns nonzero without changing it

#### Scenario: Batch WinGet and preserve per-user MSI detection

- **WHEN** a run checks all WinGet declarations including Pandoc
- **THEN** one initial installed snapshot serves all tests without --scope filtering
- **AND** only actual installations or updates trigger one fresh batch for all changed-package postconditions
- **AND** any needed user installation still explicitly supplies --scope user

#### Scenario: Treat native stderr correctly

- **WHEN** npm writes a notice to stderr and exits zero
- **THEN** the native operation succeeds
- **AND** a nonzero native exit stops apply without automatic retry

#### Scenario: Validate without Windows

- **WHEN** a non-Windows platform reviews source
- **THEN** declarations remain inspectable but native mocked/parser validation is not falsely reported as exercised
- **AND** required Windows CI runs without workstation writes or production credentials

#### Scenario: Preserve stable dark appearance acceptance

- **WHEN** Windows selects Custom.theme with matching declared appearance
- **THEN** dry run accepts it without requiring a fixed theme path

#### Scenario: Reject a dependency on an undeclared resource

- **WHEN** data adds an unsupported dependency field or names an undeclared prerequisite
- **THEN** schema/invariant validation rejects it
- **AND** ordered Node/npm prerequisites remain explicit and validated

#### Scenario: Preview and confirm on the machine

- **WHEN** the integrator tests the engine and both Administrator scripts before and after approved apply
- **THEN** preview writes nothing and post-apply tests report matching state or named failures

### Requirement: Every script parses

The repository SHALL parse all shipped Windows scripts, the module, both Administrator scripts and rendered chezmoi hooks with the PowerShell 7 parser. The narrow Administrator boundary SHALL remain enforced from parsed references and values. Only the minimal fresh-machine prerequisite bootstrap MAY use Windows PowerShell 5.1.

#### Scenario: Remove the second host

- **WHEN** migrated chezmoi hooks and development tools run
- **THEN** they run in PowerShell 7 without Desktop module-path repair or child Windows PowerShell processes

#### Scenario: A script does not parse

- **WHEN** a shipped or rendered script contains a syntax error
- **THEN** checks fail with its path and parser message

#### Scenario: A script refactor keeps the check green

- **WHEN** a script is restructured without changing its allowed reads/writes
- **THEN** parsed boundary checks remain green without source-substring exceptions

### Requirement: Check expectations derive from the declaration

Checks SHALL derive mutable application/version/release/settings facts from JSON and the managed exclusion audit, not duplicate them in checker code. Only stable privilege, role identity and ownership invariants SHALL be literals. The engine data SHALL be the application/settings authority rather than a declaration rendered into a second document.

#### Scenario: Change one pin

- **WHEN** a reviewed version/hash changes in data
- **THEN** checks consume the new declaration without a matching checker edit

#### Scenario: Declare a self-updating application

- **WHEN** Zed, Brave or Ferdium declares present policy
- **THEN** checks accept an existing installation without catalog queries or application-specific version exceptions

#### Scenario: Declared application absent from the document

- **WHEN** a required role has no unique application in JSON
- **THEN** invariants fail and name the role

#### Scenario: Rendered version policy differs from the declaration

- **WHEN** a pinned declaration lacks its version/consumer or a present declaration carries a consumer pin
- **THEN** schema validation fails

#### Scenario: Review file set differs from the declaration

- **WHEN** a declared installation payload or prerequisite source file is missing
- **THEN** validation names the missing source rather than silently skip it

#### Scenario: Reject a different named application

- **WHEN** required Zen, Zed, Brave or Ferdium role identity changes outside the contract
- **THEN** invariants reject that role without copying its mutable version or profile state

## ADDED Requirements

### Requirement: Owner-confirmed engine cutover

The PR SHALL contain the engine cutover, hash-protected chezmoi invocation, persisted pwsh interpreter and complete obsolete DSC source deletion. Git history SHALL retain the legacy source for rollback. Only the integrator SHALL dry run or apply against Korolev. Before merge, the integrator SHALL run the dry run and then chezmoi apply from the PR branch, record zero drift or accept every named difference, and confirm post-apply convergence. Source rollback SHALL NOT be represented as restoration of mutated user state. Agents SHALL report only mocked local verification.

#### Scenario: Review before live acceptance

- **WHEN** the complete cutover PR is ready but live parity is unconfirmed
- **THEN** the PR remains unmerged
- **AND** only mocked local verification is reported
- **AND** the legacy source remains recoverable from Git history rather than an active second implementation

#### Scenario: Complete the approved cutover

- **WHEN** the integrator runs the PR branch dry run and chezmoi apply and accepts parity or every named difference
- **THEN** post-apply convergence and application checks are recorded before merge
- **AND** no separate post-parity source deletion phase is required

## REMOVED Requirements

### Requirement: Checker errors and self-tests have separate paths

**Reason**: The obsolete bespoke document checker and its mutation/self-test interface are removed with the complete cutover PR.
**Migration**: Use the PowerShell 7 schema/invariant gate and Pester behavior tests. Engine entrypoint errors remain distinct from drift.
