# Proposal

## Why

The interactive Windows plugin update task opens a console every hour. PowerShell's hidden window flag cannot prevent console creation when Windows Terminal is the default terminal.

## What Changes

- Launch the existing runner through a headless console host instead of launching PowerShell directly.
- Repair installed tasks with the old action while preserving triggers and the unelevated interactive identity.
- Document windowless execution and test action convergence.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `personal-plugin-updates`: Windows updates run without opening a window.

## Impact

The Windows task action, its mocked tests and the Korolev operations guide change. Korolev activation and visual verification remain required before merging.
