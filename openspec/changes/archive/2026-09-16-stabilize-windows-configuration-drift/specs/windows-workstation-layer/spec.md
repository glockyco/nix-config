## MODIFIED Requirements

### Requirement: Pinned application set

The document SHALL declare one explicit version policy for every application it manages. An exact-pinned application SHALL declare one reviewed version and SHALL install only that version. A self-updating application SHALL omit an exact version and SHALL require the latest version available from its WinGet source. Zed and Brave SHALL use the self-updating policy because their signed vendor channels own updates. The document SHALL accept an installed self-updating application when its version is equal to or newer than the latest version in the WinGet source, and SHALL NOT downgrade it. All other applications SHALL remain exact-pinned. The set SHALL cover the operator's confirmed roles: code editor, web browser, Git client, application launcher with window switching, mouse-driven window move and resize, Neo2 keyboard layout, terminal host, and terminal font. The document SHALL NOT declare an application that the device management policy already manages.

#### Scenario: Install the declared set

- **WHEN** the operator applies the document on a machine without the declared applications
- **THEN** each exact-pinned application installs at its declared version
- **AND** each self-updating application installs at the latest version available from WinGet
- **AND** each required role has exactly one declared application

#### Scenario: Accept a newer vendor update

- **WHEN** Zed or Brave has a vendor-channel version newer than the latest version available from WinGet
- **THEN** the document reports that application in the desired state
- **AND** an apply operation does not downgrade or reinstall it

#### Scenario: Detect an unpinned application

- **WHEN** an application declares no version policy, more than one version policy, a version under the self-updating policy, or no version under the exact policy
- **THEN** repository validation fails

#### Scenario: Detect a managed-application conflict

- **WHEN** a declared application appears in the recorded set of centrally managed applications
- **THEN** repository validation fails

### Requirement: Declared Windows settings

The document SHALL declare Windows settings by explicit named keys. It SHALL keep the centrally managed Firefox package's interactive-user startup value absent. It SHALL put `en-GB` first in the user's preferred language list and set it as the Windows UI override while the English entry has no input method. It SHALL preserve the existing `de-DE` and `de-AT` entries and their input methods. The document SHALL disable Windows transparency and animation effects. It SHALL validate dark appearance from application mode, system mode, transparency, and wallpaper. It SHALL NOT depend on the active theme-file path because Windows can store the same declared appearance in `Custom.theme`. For a bundled utility that provides several modules, the document SHALL declare the enabled modules and SHALL also declare every other module as disabled.

#### Scenario: Apply the declared settings

- **WHEN** the operator applies the document
- **THEN** the declared keyboard, file-manager, regional, window-snapping, screenshot-location, and dark-appearance settings match the declaration
- **AND** transparency and animation effects are disabled
- **AND** the short date uses ISO 8601 `yyyy-MM-dd`

#### Scenario: Retain a generated custom theme

- **WHEN** the dark-mode flags, transparency, and wallpaper match the declaration and Windows records them in `Custom.theme`
- **THEN** the dark-appearance resource reports the desired state
- **AND** an apply operation does not rewrite the active theme-file path

#### Scenario: Prevent Firefox from starting at sign-in

- **WHEN** the operator applies the document and signs in again
- **THEN** Firefox does not start through its interactive-user launch-on-login entry
- **AND** the centrally managed Firefox package remains installed

#### Scenario: Separate interface and input languages

- **WHEN** the operator applies the document and signs in again
- **THEN** Windows and PowerToys use English (United Kingdom)
- **AND** the Austrian region and German keyboard layouts remain available
- **AND** no English input method is added
- **AND** native Neo is selected after sign-in

#### Scenario: Resist an upstream default change

- **WHEN** a bundled utility update would enable a module that the document declares as disabled
- **THEN** the next apply returns that module to the declared state

### Requirement: Validation before and after apply

The repository SHALL validate the rendered document and privilege boundary without a Windows machine. The operator SHALL test the document and both Administrator scripts before their first apply and SHALL confirm each applied state after the apply.

#### Scenario: Validate without Windows

- **WHEN** the repository checks run on a supported build platform
- **THEN** they validate the document structure, the narrow script boundary, each application's version policy, and the absence of a centrally managed application
- **AND** they require no Windows machine and no network service

#### Scenario: Preview and confirm on the machine

- **WHEN** the operator tests the document and both Administrator scripts on `korolev`
- **THEN** each test reports drift without applying it
- **AND** later test operations report that the applied state matches all three artifacts

### Requirement: Dedicated browser-relay application

The rendered Windows application set SHALL declare Brave as a self-updating, user-scope Chromium-based browser for OMP browser relay use. The relay browser SHALL have a distinct application role, SHALL NOT replace Zen as the interactive browser, and SHALL NOT appear in the centrally managed application set. The Windows declaration SHALL configure no startup entry for the relay browser.

#### Scenario: Apply the Windows application declaration

- **WHEN** the interactive user applies the rendered Windows configuration without Brave installed
- **THEN** WinGet installs the latest available Brave version in that user's scope without elevation
- **AND** Zen remains the declared interactive browser

#### Scenario: Detect an invalid relay browser declaration

- **WHEN** Brave is absent, uses a policy other than self-updating, is machine-scoped, is assigned the interactive browser role, or is listed as centrally managed
- **THEN** repository validation fails

#### Scenario: Sign in after a restart

- **WHEN** Windows restarts after the relay browser is installed
- **THEN** the relay browser does not start automatically
- **AND** starting Zen requires no relay browser process

#### Scenario: Remove the relay browser capability

- **WHEN** the relay browser declaration is removed and the Windows configuration is applied
- **THEN** no NixOS generation or OMP wrapper change is required
- **AND** the operator can remove the browser-owned relay profile and extension independently
