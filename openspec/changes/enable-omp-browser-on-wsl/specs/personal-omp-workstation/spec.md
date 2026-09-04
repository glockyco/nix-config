## ADDED Requirements

### Requirement: Managed browser compatibility on WSL

The NixOS/WSL host SHALL provide the shared-library ABI required by OMP's managed Linux Chromium through the system's declarative foreign-binary loader. OMP SHALL continue to own the Chromium executable, browser profiles, cache, and browser runtime state. Nix activation SHALL NOT download, replace, patch, or invoke the browser.

#### Scenario: Open a page with the managed browser

- **WHEN** the operator uses OMP's managed browser after activating the WSL host
- **THEN** Chromium starts without a missing-library error
- **AND** it loads and renders a public HTTPS page

#### Scenario: Inspect the system browser ABI

- **WHEN** the WSL host closure is inspected before activation
- **THEN** its foreign-binary library path contains every shared-library name required by the supported OMP browser runtime
- **AND** the closure contains no Nix-packaged Chromium executable

#### Scenario: Activate over browser runtime state

- **WHEN** the operator activates or rolls back a NixOS generation
- **THEN** OMP's downloaded Chromium, browser profiles, cache, and browser configuration remain unchanged

#### Scenario: Update OMP on WSL

- **WHEN** the official OMP installer replaces the user-local OMP release
- **THEN** the operator repeats the managed-browser smoke before accepting the update
- **AND** a new browser ABI requirement fails visibly instead of causing activation to mutate OMP state

### Requirement: On-demand authenticated browser relay

The workstation SHALL provide an on-demand path from OMP in WSL to a dedicated Chromium-based Windows browser profile. The relay browser SHALL remain separate from the declared interactive browser and SHALL NOT start automatically. OMP SHALL own the unpacked relay extension, and its installation SHALL remain an explicit user operation outside NixOS and Windows configuration activation.

#### Scenario: Use an authenticated web interface

- **WHEN** the operator opens the dedicated relay profile with one intended tab and requests a relay-backed browser session
- **THEN** OMP adopts that tab
- **AND** the authenticated profile remains available for interactive login or multi-factor authentication
- **AND** ordinary browsing remains outside the relay profile

#### Scenario: Start the workstation without browser automation

- **WHEN** Windows starts and the operator signs in
- **THEN** the relay browser and relay daemon remain stopped until requested
- **AND** Zen remains the declared interactive browser

#### Scenario: Activate either configuration layer

- **WHEN** the operator applies the NixOS or Windows declaration
- **THEN** activation does not load an unpacked extension into a browser profile
- **AND** activation does not write OMP browser configuration or browser runtime state
