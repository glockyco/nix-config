# Spec Delta

## MODIFIED Requirements

### Requirement: Dedicated batch endpoint

The workstation SHALL provide a named SSH endpoint for unattended commands to each remote destination that automation drives: the MacBook Air while declared, desktop, native Windows Korolev and macbook-pro. Each endpoint SHALL identify the same remote host/account as its interactive counterpart and SHALL be named after it. Windows user access SHALL use its independently approved key, never the retired Linux Nix-daemon builder key.

#### Scenario: Batch endpoint resolves the Air

- **WHEN** automation connects through the Air's batch endpoint
- **THEN** the command runs under the configured account on the MacBook Air

#### Scenario: Batch endpoint resolves the desktop

- **WHEN** automation connects through the desktop's batch endpoint
- **THEN** the command runs under the configured Windows account on the desktop
- **AND** it resolves the desktop by its tailnet name rather than a recorded address

#### Scenario: Batch endpoint resolves the MacBook Pro

- **WHEN** automation on native Windows Korolev connects through macbook-pro-batch
- **THEN** the command runs under the MacBook Pro's declared user with the native Windows user's independently approved key
- **AND** it resolves the Mac by its tailnet name and verifies the declared host key

#### Scenario: Batch endpoint resolves native Korolev

- **WHEN** approved Mac automation selects Korolev's native batch endpoint
- **THEN** it reaches the declared standard Windows account using its own source key and pinned host identity
- **AND** no WSL process or root Nix builder credential participates
