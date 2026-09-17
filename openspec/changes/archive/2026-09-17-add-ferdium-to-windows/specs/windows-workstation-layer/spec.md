## ADDED Requirements

### Requirement: Native Ferdium communication client

The rendered Windows application set SHALL declare `Ferdium.Ferdium` as the user-scoped `communication-client` package. The package SHALL run as a native Windows application and SHALL NOT be installed through NixOS, Home Manager, WSLg, or a machine-scoped installer.

#### Scenario: Install Ferdium

- **WHEN** the interactive user applies the rendered Windows configuration without Ferdium installed
- **THEN** WinGet installs the latest available Ferdium version in that user's scope without elevation
- **AND** the user can launch Ferdium as a native Windows application

#### Scenario: Validate the platform boundary

- **WHEN** the repository validates all host configurations
- **THEN** the Windows application set contains exactly one `communication-client` package with identifier `Ferdium.Ferdium`
- **AND** the NixOS and Darwin user package sets do not gain Ferdium from this declaration

### Requirement: Ferdium-owned state and preferences

Ferdium SHALL own its profile, configured services, credentials, sessions, cache, automatic-update preference, and startup preference. The Windows configuration SHALL NOT write those values, authenticate an account, launch Ferdium, add a repository-owned updater, or add a repository-owned startup entry. A fresh Ferdium profile SHALL use the application's default enabled automatic-update preference and disabled startup preference. A later configuration apply SHALL preserve user changes to either preference and all other profile state.

#### Scenario: Launch a fresh installation

- **WHEN** the user launches Ferdium for the first time after installation
- **THEN** Ferdium reports automatic updates as enabled
- **AND** Ferdium reports launch at sign-in as disabled
- **AND** the Windows configuration has not authenticated or configured a service

#### Scenario: Apply over an existing profile

- **WHEN** the user applies the Windows configuration after configuring Ferdium
- **THEN** the existing profile, services, credentials, sessions, cache, and preferences remain in place
- **AND** the apply operation does not launch Ferdium

#### Scenario: Remove the declaration

- **WHEN** a later reviewed configuration removes the Ferdium package declaration
- **THEN** the repository does not delete Ferdium's writable user profile
- **AND** application removal and profile deletion remain explicit user operations

## MODIFIED Requirements

### Requirement: Pinned application set

The document SHALL declare one explicit version policy for every application it manages. An exact-pinned application SHALL declare one reviewed version and SHALL install only that version. A self-updating application SHALL omit an exact version and SHALL require the latest version available from its WinGet source. Zed, Brave, and Ferdium SHALL use the self-updating policy because their vendor channels own updates. The document SHALL accept an installed self-updating application when its version is equal to or newer than the latest version in the WinGet source, and SHALL NOT downgrade it. All other applications SHALL remain exact-pinned. The set SHALL cover the operator's confirmed roles: code editor, web browser, Git client, communication client, application launcher with window switching, mouse-driven window move and resize, Neo2 keyboard layout, terminal host, and the terminal font. The document SHALL NOT declare an application that the device management policy already manages.

#### Scenario: Install the declared set

- **WHEN** the operator applies the document on a machine without the declared applications
- **THEN** each exact-pinned application installs at its declared version
- **AND** each self-updating application installs at the latest version available from WinGet
- **AND** each required role has exactly one declared application

#### Scenario: Accept a newer vendor update

- **WHEN** Zed, Brave, or Ferdium has a vendor-channel version newer than the latest version available from WinGet
- **THEN** the document reports that application in the desired state
- **AND** an apply operation does not downgrade or reinstall it

#### Scenario: Detect an unpinned application

- **WHEN** an application declares no version policy, more than one version policy, a version under the self-updating policy, or no version under the exact policy
- **THEN** repository validation fails

#### Scenario: Detect a managed-application conflict

- **WHEN** a declared application appears in the recorded set of centrally managed applications
- **THEN** repository validation fails
