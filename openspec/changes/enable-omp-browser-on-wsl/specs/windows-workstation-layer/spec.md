## ADDED Requirements

### Requirement: Dedicated browser-relay application

The rendered Windows application set SHALL declare one pinned, user-scope Chromium-based browser for OMP browser relay use. The relay browser SHALL have a distinct application role, SHALL NOT replace Zen as the interactive browser, and SHALL NOT appear in the centrally managed application set. The Windows declaration SHALL configure no startup entry for the relay browser.

#### Scenario: Apply the Windows application declaration

- **WHEN** the interactive user applies the rendered Windows configuration
- **THEN** the pinned relay browser installs in that user's scope without elevation
- **AND** Zen remains the declared interactive browser

#### Scenario: Detect an invalid relay browser declaration

- **WHEN** the relay browser is absent, unpinned, machine-scoped, assigned the interactive browser role, or listed as centrally managed
- **THEN** repository validation fails

#### Scenario: Sign in after a restart

- **WHEN** Windows restarts after the relay browser is installed
- **THEN** the relay browser does not start automatically
- **AND** starting Zen requires no relay browser process

#### Scenario: Remove the relay browser capability

- **WHEN** the relay browser declaration is removed and the Windows configuration is applied
- **THEN** no NixOS generation or OMP wrapper change is required
- **AND** the operator can remove the browser-owned relay profile and extension independently
