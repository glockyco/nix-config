# Batch SSH Specification

## Purpose

Provides a deterministic SSH endpoint for unattended commands to the MacBook Air while preserving the separate interactive connection policy.

## Requirements

### Requirement: Dedicated batch endpoint

The workstation SHALL provide a named SSH endpoint for unattended commands to the MacBook Air. The endpoint SHALL identify the same remote host and account as the interactive `air` endpoint.

#### Scenario: Batch endpoint resolves the Air

- **WHEN** automation connects through the batch endpoint
- **THEN** the command runs under the configured account on the MacBook Air

### Requirement: Non-interactive command lifecycle

The batch endpoint SHALL disable terminal allocation, interactive authentication prompts, connection multiplexing, and connection persistence. A completed remote command SHALL release its local SSH process without waiting for an interactive connection's persistence interval. The endpoint SHALL preserve the SSH standard streams required by protocol-driven clients.

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

The batch endpoint SHALL NOT change terminal, stdin, authentication, multiplexing, or persistence behavior for the existing interactive `air` endpoint.

#### Scenario: Operator selects interactive endpoint

- **WHEN** an operator connects through `air` instead of the batch endpoint
- **THEN** the workstation applies the existing interactive SSH policy

### Requirement: Explicit remote tool resolution

Automation that invokes a tool absent from the Air's non-interactive `PATH` SHALL provide the reviewed absolute executable path through its existing command or configuration interface. The batch endpoint SHALL NOT modify remote shell initialization to discover such tools.

#### Scenario: Remote Docker command

- **WHEN** automation invokes Docker through the batch endpoint
- **THEN** it uses the configured remote Docker executable and does not depend on shell startup files to resolve `docker`

### Requirement: Verifiable batch boundary

The workstation configuration SHALL provide static checks for the batch endpoint's transport settings and a documented live verification for command completion, failure propagation, and remote Docker access.

#### Scenario: Daemon-free configuration validation

- **WHEN** workstation flake checks run without access to the MacBook Air
- **THEN** they verify the declared host identity and non-interactive transport settings without opening an SSH connection

#### Scenario: Live acceptance

- **WHEN** an operator runs the documented acceptance procedure while the MacBook Air is reachable
- **THEN** a successful command, an expected remote failure, a protocol-driven transfer, and a remote Docker inspection each complete within their declared bounds
