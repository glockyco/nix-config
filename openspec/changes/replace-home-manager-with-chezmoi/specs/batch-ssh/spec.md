# Spec Delta

## MODIFIED Requirements

### Requirement: Dedicated batch endpoint

The workstation SHALL provide a named SSH endpoint for unattended commands to each remote destination that automation drives, currently the MacBook Air, the Windows desktop, and, from a declared source workstation, the MacBook Pro. Chezmoi SHALL render the user SSH endpoints from declared shared endpoint facts on each supported platform. Each endpoint SHALL identify the same remote host and account as its interactive counterpart, and SHALL be named after that counterpart so the pair is discoverable from the declaration.

#### Scenario: Batch endpoint resolves the Air

- **WHEN** automation connects through the Air's batch endpoint
- **THEN** the command runs under the configured account on the MacBook Air

#### Scenario: Batch endpoint resolves the desktop

- **WHEN** automation connects through the desktop's batch endpoint
- **THEN** the command runs under the configured Windows account on the desktop
- **AND** it resolves the desktop by its tailnet name rather than a recorded address

#### Scenario: Batch endpoint resolves the MacBook Pro

- **WHEN** automation on a declared source workstation connects through `macbook-pro-batch`
- **THEN** the command runs under the MacBook Pro's declared user with the source user's own key
- **AND** it resolves the Mac by its tailnet name and verifies the declared host key

### Requirement: Non-interactive command lifecycle

On every supported operating system, the batch endpoint SHALL disable terminal allocation, interactive authentication prompts, connection multiplexing, and connection persistence. A completed remote command SHALL release its local SSH process without waiting for an interactive connection's persistence interval. The endpoint SHALL preserve the SSH standard streams required by protocol-driven clients.

#### Scenario: Successful command exits promptly

- **WHEN** automation runs a non-interactive command that exits successfully
- **THEN** SSH returns success and terminates without leaving a persistent master process

#### Scenario: Failed command propagates failure

- **WHEN** the remote command exits with a nonzero status
- **THEN** SSH returns that status without prompting or selecting an interactive transport

#### Scenario: Command caller detaches stdin

- **WHEN** a command-only caller has no input for the remote process
- **THEN** the caller detaches stdin and the batch endpoint completes without consuming the caller's input stream

#### Scenario: Protocol client uses SSH streams

- **WHEN** a protocol-driven client such as `rsync` uses the batch endpoint
- **THEN** SSH carries the protocol over its standard streams without creating a persistent master process

#### Scenario: Connection cannot be established

- **WHEN** the MacBook Air cannot be reached during connection establishment
- **THEN** the batch endpoint fails within its declared connection timeout

### Requirement: Interactive SSH compatibility

Platform-supported interactive multiplexing SHALL remain separate from the universally non-multiplexed batch endpoint. A batch endpoint SHALL NOT change terminal, stdin, authentication, multiplexing, or persistence behavior for the interactive endpoint that shares its destination.

#### Scenario: Operator selects interactive endpoint

- **WHEN** an operator connects through an interactive endpoint instead of its batch counterpart
- **THEN** the workstation applies the existing interactive SSH policy

#### Scenario: Desktop endpoints stay independent

- **WHEN** the desktop's batch endpoint disables multiplexing and persistence
- **THEN** the interactive desktop endpoint retains the shared interactive policy
- **AND** the Air's endpoints are unaffected

### Requirement: Explicit remote tool resolution

Automation that invokes a tool absent from the Air's non-interactive `PATH` SHALL provide the reviewed absolute executable path through its existing command or configuration interface. The batch endpoint SHALL NOT modify remote shell initialization to discover such tools.

#### Scenario: Remote Docker command

- **WHEN** automation invokes Docker through the batch endpoint
- **THEN** it uses the configured remote Docker executable and does not depend on shell startup files to resolve `docker`

### Requirement: Verifiable batch boundary

The workstation configuration SHALL provide static checks of the actual chezmoi-rendered batch endpoint transport settings and a documented live verification for command completion, failure propagation, and remote Docker access.

#### Scenario: Daemon-free configuration validation

- **WHEN** workstation configuration checks run without access to the MacBook Air
- **THEN** they verify the declared host identity and non-interactive transport settings without opening an SSH connection

#### Scenario: Live acceptance

- **WHEN** an operator runs the documented acceptance procedure while the MacBook Air is reachable
- **THEN** a successful command, an expected remote failure, a protocol-driven transfer, and a remote Docker inspection each complete within their declared bounds
