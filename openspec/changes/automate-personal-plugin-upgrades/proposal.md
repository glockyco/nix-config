# Proposal

## Why

Personal plugin releases should reach new sessions without a manual update on each host. Windows plugin operations need an interactive session and occasional marketplace lock retries.

## What Changes

- Declare an hourly Mac user launch agent and a Windows interactive scheduled task for the personal plugin.
- Log update results and retry Windows marketplace lock failures.
- Replace manual personal-plugin update instructions with service operation guidance.

## Capabilities

### New Capabilities

- `personal-plugin-updates`: Host-managed scheduling of plugin-manager updates without replacing running sessions.

### Modified Capabilities

None.

## Impact

Changes affect the Darwin desktop role, Windows workstation settings, their tests and OMP update documentation. Mac activation remains an interactive `darwin-switch` operation.
