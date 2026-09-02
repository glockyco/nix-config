## ADDED Requirements

### Requirement: Rendered Windows configuration document

The repository SHALL render one Windows configuration document from Nix expressions. The document SHALL be the single source for the Windows application set, the declared Windows settings, and the declared application configuration files. Nix activation on any host SHALL NOT write to a Windows path, and SHALL NOT apply the document.

#### Scenario: Render the document

- **WHEN** the Windows configuration output is built from the locked repository
- **THEN** the result is one document plus the configuration files it references
- **AND** the build reads no mutable Windows state

#### Scenario: Keep the operating-system boundary

- **WHEN** either host activates a Nix generation
- **THEN** activation writes no file under the Windows user profile
- **AND** activation does not start the Windows apply operation

### Requirement: Unelevated user-scope application

Every item that the document declares SHALL apply in the interactive user's own scope. Applying the document SHALL complete without administrator rights.

#### Scenario: Apply as a standard user

- **WHEN** the interactive user applies the document with standard user rights
- **THEN** the operation completes without an elevation prompt
- **AND** every installed application and written file belongs to that user's profile

#### Scenario: Reject a privileged declaration

- **WHEN** the document would declare a machine-scope package, a machine-scope registry value, or a Windows feature
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

The document SHALL declare Windows settings by explicit named keys. For a bundled utility that provides several modules, the document SHALL declare the enabled module and SHALL also declare every other module as disabled.

#### Scenario: Apply the declared settings

- **WHEN** the operator applies the document
- **THEN** the declared keyboard, file-manager, regional, window-snapping, and screenshot-location settings match the declaration

#### Scenario: Resist an upstream default change

- **WHEN** a bundled utility update would enable a module that the document declares as disabled
- **THEN** the next apply returns that module to the declared state

### Requirement: Application configuration files

The document SHALL declare application configuration in two classes. For an application that does not rewrite its own configuration, the document SHALL enforce the complete file content. For an application that rewrites its own configuration, the document SHALL converge only the declared values and SHALL preserve the application's own writes.

#### Scenario: Enforce a stable configuration file

- **WHEN** a file in the enforced class differs from the declaration
- **THEN** the apply operation restores the declared content

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

The repository SHALL validate the rendered document without a Windows machine. The operator SHALL preview the document before the first apply, and SHALL confirm the applied state after the apply.

#### Scenario: Validate without Windows

- **WHEN** the repository checks run on a supported build platform
- **THEN** they validate the document structure, the version pin of every application, and the absence of a centrally managed application
- **AND** they require no Windows machine and no network service

#### Scenario: Preview and confirm on the machine

- **WHEN** the operator previews the document on `korolev`
- **THEN** the preview reports the pending changes without applying them
- **AND** a later test operation reports that the applied state matches the document
