## MODIFIED Requirements

### Requirement: Dedicated batch endpoint

The workstation SHALL provide a named SSH endpoint for unattended commands to each remote destination that automation drives, currently the MacBook Air and the Windows desktop. Each endpoint SHALL identify the same remote host and account as its interactive counterpart, and SHALL be named after that counterpart so the pair is discoverable from the declaration.

#### Scenario: Batch endpoint resolves the Air

- **WHEN** automation connects through the Air's batch endpoint
- **THEN** the command runs under the configured account on the MacBook Air

#### Scenario: Batch endpoint resolves the desktop

- **WHEN** automation connects through the desktop's batch endpoint
- **THEN** the command runs under the configured Windows account on the desktop
- **AND** it resolves the desktop by its tailnet name rather than a recorded address

### Requirement: Interactive SSH compatibility

A batch endpoint SHALL NOT change terminal, stdin, authentication, multiplexing, or persistence behavior for the interactive endpoint that shares its destination.

#### Scenario: Operator selects interactive endpoint

- **WHEN** an operator connects through an interactive endpoint instead of its batch counterpart
- **THEN** the workstation applies the existing interactive SSH policy

#### Scenario: Desktop endpoints stay independent

- **WHEN** the desktop's batch endpoint disables multiplexing and persistence
- **THEN** the interactive desktop endpoint retains the shared interactive policy
- **AND** the Air's endpoints are unaffected
