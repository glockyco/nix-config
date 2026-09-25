## MODIFIED Requirements

### Requirement: Pinned application set

The document SHALL declare one explicit version policy for every application it manages. An exact-pinned application SHALL declare one reviewed version and SHALL install only that version. A self-updating application SHALL omit an exact version and SHALL require the latest version available from its WinGet source. Zed, Zen, Brave, and Ferdium SHALL use the self-updating policy because their vendor channels own updates. The document SHALL accept an installed self-updating application when its version is equal to or newer than the latest version in the WinGet source, and SHALL NOT downgrade it. All other applications SHALL remain exact-pinned. The set SHALL cover the operator's confirmed roles: code editor, web browser, Git client, communication client, application launcher with window switching, mouse-driven window move and resize, Neo2 keyboard layout, terminal host, and the terminal font. The document SHALL NOT declare an application that the device management policy already manages.

#### Scenario: Install the declared set

- **WHEN** the operator applies the document on a machine without the declared applications
- **THEN** each exact-pinned application installs at its declared version
- **AND** each self-updating application installs at the latest version available from WinGet
- **AND** each required role has exactly one declared application

#### Scenario: Accept a newer vendor update

- **WHEN** Zed, Zen, Brave, or Ferdium has a vendor-channel version newer than the latest version available from WinGet
- **THEN** the document reports that application in the desired state
- **AND** an apply operation does not downgrade or reinstall it

#### Scenario: Detect an unpinned application

- **WHEN** an application declares no version policy, more than one version policy, a version under the self-updating policy, or no version under the exact policy
- **THEN** repository validation fails

#### Scenario: Detect a managed-application conflict

- **WHEN** a declared application appears in the recorded set of centrally managed applications
- **THEN** repository validation fails
