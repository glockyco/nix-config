# Proposal

## Why

Korolev's Git Credential Manager uses Windows Credential Manager, which rejects network logons. SSH repository work needs the same encrypted credentials as desktop sessions without disabling Windows protections.

## What Changes

- Select GCM's current-user DPAPI file store on Windows.
- Preserve the existing HTTPS helper and desktop authentication flow.
- Explain Git authentication and the independent OMP RedirectionGuard limitation in the remote access runbook.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `native-windows-remote-work`: encrypted Git credentials work in standard-account SSH and desktop sessions.

## Impact

The Git template, native chezmoi fixture, and remote access runbook change. Existing credentials move through GCM on Korolev without entering the repository or logs. OMP plugin junctions and sshd mitigations stay unchanged.
