## REMOVED Requirements

### Requirement: Dedicated browser-relay application

**Reason**: The relay runs in Microsoft Edge, which Windows provides, so the declared Brave package and its role contract go.

**Migration**: Set up the relay in Edge as the Korolev guide describes. An installed Brave stays until the operator removes it with WinGet.

## ADDED Requirements

### Requirement: Browser relay in Edge

The Windows OMP browser relay SHALL run in Microsoft Edge, which Windows provides and updates. The hand-maintained Windows application set SHALL declare no package and no role for the relay browser. Edge SHALL NOT replace Zen as the interactive browser. The Korolev guide SHALL describe how to install the relay extension and register its native messaging host for Edge.

#### Scenario: Apply the Windows application declaration

- **WHEN** the interactive user applies the Windows configuration
- **THEN** the engine installs no relay browser package
- **AND** Zen remains the declared interactive browser

#### Scenario: Set up the relay in Edge

- **WHEN** the operator follows the Korolev guide after installing or upgrading OMP
- **THEN** Edge finds the relay's native messaging host and its extension connects to OMP

#### Scenario: Sign in after a restart

- **WHEN** Windows restarts
- **THEN** the relay needs no browser started by the configuration
- **AND** starting Zen requires no relay browser process

## MODIFIED Requirements

### Requirement: Check expectations derive from the declaration

Checks SHALL derive mutable application/version/release/settings facts from JSON and the managed exclusion audit, not duplicate them in checker code. Only stable privilege, role identity and ownership invariants SHALL be literals. The engine data SHALL be the application/settings authority rather than a declaration rendered into a second document.

#### Scenario: Change one pin

- **WHEN** a reviewed version/hash changes in data
- **THEN** checks consume the new declaration without a matching checker edit

#### Scenario: Declare a self-updating application

- **WHEN** Zed or Ferdium declares present policy
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

- **WHEN** required Zen, Zed or Ferdium role identity changes outside the contract
- **THEN** invariants reject that role without copying its mutable version or profile state
