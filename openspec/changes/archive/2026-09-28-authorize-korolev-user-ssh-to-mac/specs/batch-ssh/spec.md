## MODIFIED Requirements

### Requirement: Dedicated batch endpoint

The workstation SHALL provide a named SSH endpoint for unattended commands to each remote destination that automation drives, currently the MacBook Air, the Windows desktop, and, from the WSL host, the MacBook Pro. Each endpoint SHALL identify the same remote host and account as its interactive counterpart, and SHALL be named after that counterpart so the pair is discoverable from the declaration.

#### Scenario: Batch endpoint resolves the Air

- **WHEN** automation connects through the Air's batch endpoint
- **THEN** the command runs under the configured account on the MacBook Air

#### Scenario: Batch endpoint resolves the desktop

- **WHEN** automation connects through the desktop's batch endpoint
- **THEN** the command runs under the configured Windows account on the desktop
- **AND** it resolves the desktop by its tailnet name rather than a recorded address

#### Scenario: Batch endpoint resolves the MacBook Pro

- **WHEN** automation on the WSL host connects through `macbook-pro-batch`
- **THEN** the command runs under the MacBook Pro's declared user with the WSL user's own key
- **AND** it resolves the Mac by its tailnet name and verifies the declared host key
