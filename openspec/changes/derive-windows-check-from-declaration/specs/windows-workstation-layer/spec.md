## ADDED Requirements

### Requirement: Check expectations derive from the declaration

The Windows configuration output SHALL expose its declaration: the role set, the application list with every pin, the centrally managed application identifiers, and the review file names. The repository check SHALL read that declaration from the output and SHALL derive its expectations for pins, roles, elevation, and the file set from it. The check SHALL NOT carry a copy of a pin, a palette, a module list, a theme hash, or a file name. The check SHALL keep as literals only the rules that the declaration cannot express: the document schema, unique resource names, dependency existence, the elevation policy, and the Administrator-script boundary.

#### Scenario: Change one pin

- **WHEN** a maintainer changes the version or checksum of one application in the declaration and renders the output
- **THEN** the repository check passes with no edit to the check
- **AND** the rendered document carries the new pin

#### Scenario: Declared application absent from the document

- **WHEN** the declaration lists an application that the rendered document does not carry as exactly one resource with the same identifier, version, scope, and roles
- **THEN** the repository check fails and names the application

#### Scenario: Rendered pin differs from the declaration

- **WHEN** a package resource in the rendered document carries a version that differs from the declared version, or permits the latest version
- **THEN** the repository check fails and names the resource

#### Scenario: Review file set differs from the declaration

- **WHEN** the rendered output carries a file that the declaration does not name, or omits one that it names
- **THEN** the repository check fails and names the file

### Requirement: Every script parses

The repository check SHALL parse every script that the Windows layer ships: each test and set script inside the document, both Administrator scripts, and the ReNeo launcher. The check SHALL use the PowerShell parser for that purpose and SHALL NOT match script source against substrings. The check SHALL assert the Administrator-script boundary on the parsed variable references and string values.

#### Scenario: A script does not parse

- **WHEN** a rendered script contains a syntax error
- **THEN** the repository check fails and names the script and the parser message

#### Scenario: A script refactor keeps the check green

- **WHEN** a maintainer restructures a script without a change to the values it reads or writes
- **THEN** the repository check passes with no edit to the check

## MODIFIED Requirements

### Requirement: Rendered Windows configuration artifacts

The repository SHALL render one Windows configuration document, one Administrator Zen policy script, and one Administrator native Neo driver script from the same Nix expressions. Together they SHALL be the single source for the Windows application set, the declared Windows settings, and the declared application configuration files. Each application SHALL have one declaration that carries its identifier, version, scope, source, and release data, and every resource that installs or configures that application SHALL derive its metadata from that declaration. Evaluation of the output SHALL read no derivation output and SHALL need no network. Nix activation on any host SHALL NOT write to a Windows path and SHALL NOT apply any artifact.

#### Scenario: Render the artifacts

- **WHEN** the Windows configuration output is built from the locked repository
- **THEN** the result contains one WinGet Configuration document, one Zen policy script, one native Neo driver script, and the review files that describe their settings
- **AND** the build reads no mutable Windows state

#### Scenario: Evaluate without network

- **WHEN** the flake outputs are evaluated on a machine with no network
- **THEN** the Windows configuration output evaluates
- **AND** the pinned upstream theme files are fetched only when the output is built

#### Scenario: Keep the operating-system boundary

- **WHEN** either host activates a Nix generation
- **THEN** activation writes no file under the Windows user profile
- **AND** activation does not start the Windows apply operation

### Requirement: User scope with explicit machine exceptions

Every document resource SHALL apply in the interactive user's own scope except the Zen package. The official Zen installer SHALL be the only document resource that requests elevation. One Administrator script SHALL own only the Zen policy file under Program Files. The other SHALL own only the native Neo DLLs and keyboard-layout registration. Both scripts SHALL refuse a non-administrator token and SHALL read no Administrator-profile path. The repository check SHALL be the single owner of these rules. Evaluation of the output SHALL NOT enforce them.

#### Scenario: Apply user-scope resources

- **WHEN** the interactive user applies the document with standard user rights
- **THEN** every resource except the Zen package completes without elevation
- **AND** every other installed application and written file belongs to that user's profile

#### Scenario: Apply the browser exception

- **WHEN** the Zen installer requests the administrator credential and the operator later applies the policy script from an Administrator PowerShell session
- **THEN** both operations write only to the machine-wide Zen installation under Program Files

#### Scenario: Apply the keyboard driver exception

- **WHEN** the operator applies the native Neo script from a 64-bit Administrator PowerShell session
- **THEN** it writes only the checksum-pinned DLLs and `b0000407` machine registration
- **AND** the operator restarts Windows before the document selects input tip `0407:b0000407`

#### Scenario: Reject another privileged declaration

- **WHEN** the document declares another machine-scope package, elevated resource, machine-scope registry value, or Windows feature
- **OR** either Administrator script refers to an interactive-user profile path or a machine path outside its declared ownership
- **THEN** the repository check fails and names the resource or script
- **AND** the Windows configuration output still renders, so the operator can inspect it

### Requirement: Validation before and after apply

The repository SHALL validate the rendered document and privilege boundary without a Windows machine. The repository check SHALL validate the shipped document byte for byte against the WinGet Configuration v3 document contract, and SHALL NOT rewrite the document before validation. The document SHALL carry the schema URL and the bare-name dependency form that the WinGet parser recognizes. The operator SHALL test the document and both Administrator scripts before their first apply and SHALL confirm each applied state after the apply.

#### Scenario: Validate without Windows

- **WHEN** the repository checks run on a supported build platform
- **THEN** they validate the shipped document against the document contract, every script against the PowerShell parser, the narrow script boundary, the version pin of every application, and the absence of a centrally managed application
- **AND** they require no Windows machine and no network service

#### Scenario: Reject a dependency on an undeclared resource

- **WHEN** a resource in the rendered document depends on a name that no resource in the document declares
- **THEN** the repository check fails and names both resources

#### Scenario: Preview and confirm on the machine

- **WHEN** the operator tests the document and both Administrator scripts on `korolev`
- **THEN** each test reports drift without applying it
- **AND** later test operations report that the applied state matches all three artifacts
