## ADDED Requirements

### Requirement: Rendered Windows configuration artifacts

The repository SHALL render one Windows configuration document and one Administrator Zen policy script from the same Nix expressions. Together they SHALL be the single source for the Windows application set, the declared Windows settings, and the declared application configuration files. Nix activation on any host SHALL NOT write to a Windows path and SHALL NOT apply either artifact.

#### Scenario: Render the artifacts

- **WHEN** the Windows configuration output is built from the locked repository
- **THEN** the result contains one WinGet Configuration document, one Zen policy script, and the review files that describe their settings
- **AND** the build reads no mutable Windows state

#### Scenario: Keep the operating-system boundary

- **WHEN** either host activates a Nix generation
- **THEN** activation writes no file under the Windows user profile
- **AND** activation does not start the Windows apply operation

### Requirement: User scope with one browser exception

Every document resource SHALL apply in the interactive user's own scope except the Zen package. The official Zen installer SHALL be the only document resource that requests elevation. The Administrator script SHALL own only the Zen policy file under Program Files, refuse a non-administrator token, and read no Administrator-profile path.

#### Scenario: Apply user-scope resources

- **WHEN** the interactive user applies the document with standard user rights
- **THEN** every resource except the Zen package completes without elevation
- **AND** every other installed application and written file belongs to that user's profile

#### Scenario: Apply the browser exception

- **WHEN** the Zen installer requests the administrator credential and the operator later applies the policy script from an Administrator PowerShell session
- **THEN** those are the only two privileged operations
- **AND** both write only to the machine-wide Zen installation under Program Files

#### Scenario: Reject another privileged declaration

- **WHEN** the document declares another machine-scope package, elevated resource, machine-scope registry value, or Windows feature
- **OR** the Administrator script refers to an interactive-user profile path
- **THEN** the repository validation fails

### Requirement: Pinned application set

The document SHALL declare an explicit version for every application it manages. The set SHALL cover the operator's confirmed roles: code editor, web browser, Git client, application launcher with window switching, mouse-driven window move and resize, Neo2 keyboard layout, terminal host, and the terminal font. The document SHALL NOT declare an application that the device management policy already manages.

#### Scenario: Install the declared set

- **WHEN** the operator applies the document on a machine without those applications
- **THEN** each application installs at its declared version
- **AND** each role above has exactly one declared application

#### Scenario: Detect an unpinned application

- **WHEN** a declared application has no explicit version
- **THEN** the repository validation fails

#### Scenario: Detect a managed-application conflict

- **WHEN** a declared application appears in the recorded set of centrally managed applications
- **THEN** the repository validation fails

### Requirement: Declared Windows settings

The document SHALL declare Windows settings by explicit named keys. For a bundled utility that provides several modules, the document SHALL declare the enabled modules and SHALL also declare every other module as disabled.

#### Scenario: Apply the declared settings

- **WHEN** the operator applies the document
- **THEN** the declared keyboard, file-manager, regional, window-snapping, and screenshot-location settings match the declaration

#### Scenario: Resist an upstream default change

- **WHEN** a bundled utility update would enable a module that the document declares as disabled
- **THEN** the next apply returns that module to the declared state

### Requirement: Application configuration files

The document and policy script SHALL declare application configuration in two classes. For an application that does not rewrite its own configuration, the owning artifact SHALL enforce the complete file content. For an application that rewrites its own configuration, the owning artifact SHALL converge only the declared values and SHALL preserve the application's own writes. The Zed and Windows Terminal configurations SHALL select Catppuccin Mocha from pinned upstream theme data.

#### Scenario: Enforce a stable configuration file

- **WHEN** a file in the enforced class differs from the declaration
- **THEN** the apply operation restores the declared content

#### Scenario: Apply the application themes

- **WHEN** the operator applies the document
- **THEN** Zed and Windows Terminal select Catppuccin Mocha
- **AND** the rendered theme data matches its pinned upstream source

#### Scenario: Preserve application-owned state

- **WHEN** an application in the converged class has written its own state, such as a generated profile identifier or interface state
- **THEN** the apply operation sets the declared values
- **AND** the apply operation preserves the application's own values

### Requirement: Excluded Windows surface

The Windows layer SHALL declare nothing about the taskbar pinned-application list, per-extension default application associations, or any application that the device management policy manages. The repository SHALL record the reason for each exclusion.

#### Scenario: Inspect the excluded surface

- **WHEN** a reader reviews the Windows layer
- **THEN** each exclusion names its reason
- **AND** no part of the layer attempts to set a taskbar pinned-application list or a per-extension association

### Requirement: Validation before and after apply

The repository SHALL validate the rendered document and privilege boundary without a Windows machine. The operator SHALL test the document and policy script before their first apply and SHALL confirm each applied state after the apply.

#### Scenario: Validate without Windows

- **WHEN** the repository checks run on a supported build platform
- **THEN** they validate the document structure, the narrow script boundary, the version pin of every application, and the absence of a centrally managed application
- **AND** they require no Windows machine and no network service

#### Scenario: Preview and confirm on the machine

- **WHEN** the operator tests the document and policy script on `korolev`
- **THEN** each test reports drift without applying it
- **AND** later test operations report that the applied state matches both artifacts
