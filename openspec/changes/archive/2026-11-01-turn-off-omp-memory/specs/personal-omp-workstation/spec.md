## ADDED Requirements

### Requirement: Memory off

The documented OMP installation on each workstation SHALL set `memory.backend` to `off`, so that no session receives rules a model inferred from earlier chats.

#### Scenario: Start a session in a folder with a memory bank

- **WHEN** a fresh OMP session starts in a folder whose sharpshooter bank holds entries
- **THEN** its system prompt carries none of them

### Requirement: Preserved mutable runtime state

Configuration/activation SHALL preserve writable OMP and plugin-manager state and SHALL not replace it with store symlinks or reconcile its registry. Cross-platform transfer SHALL be limited to the nonsecret litellm model definition. Memory banks, authentication/session databases and browser profiles SHALL never be imported.

#### Scenario: Activate over an existing OMP profile

- **WHEN** workstation configuration activates on a host with existing OMP runtime state
- **THEN** authentication, configuration, sessions, history and caches remain at their mutable paths
- **AND** activation does not overwrite or delete those files

#### Scenario: Reproduce nonsecret provider configuration

- **WHEN** the owner prepares Windows models.yml for the migrated SCCH provider
- **THEN** it defines litellm with baseUrl https://vllm-api.scch.at/v1 while preserving other native definitions
- **AND** the owner establishes authentication natively, without copying secrets or authentication files

## REMOVED Requirements

### Requirement: Mutable runtime state boundary

**Reason**: It ported memory banks between hosts so that sessions would find the decisions they hold, which cannot happen with memory off.
**Migration**: "Preserved mutable runtime state" keeps the activation boundary and the litellm transfer, and adds memory banks to the state that is never imported.
