# Design

## Context

See proposal.md for the scope. Both logons use the same domain SID, medium integrity, home and plugin ACLs. SSH has NETWORK and service-asserted identity groups. Tern has INTERACTIVE, CONSOLE LOGON and authentication-authority identity groups. Controlled Folder Access is disabled. Plugin content is local, unencrypted and not a OneDrive placeholder.

## Goals / Non-Goals

Use existing current-user credentials for Git HTTPS from either logon. Do not change SSH keys, helper identity, OMP installation identity, or process mitigations.

## Decisions

Select `credential.credentialStore = dpapi` in the Windows Git template. GCM documents that wincredman cannot work in network sessions. A nonsecret sentinel encrypted with current-user DPAPI in Tern decrypted in SSH on 2026-11-01. Transfer existing GCM credentials from wincredman to DPAPI in the desktop process without printing or writing plaintext. Let GCM own encrypted runtime files and retain their inherited user-only profile ACLs.

Do not replace the helper with GitHub CLI, which uses the same unavailable Windows credential API or a plaintext fallback. Do not use GCM's plaintext store or machine-scoped DPAPI.

## OMP boundary

Direct reads of the cache package succeed in SSH. Traversing its directory junction fails with Windows' untrusted mount point error. `GetProcessMitigationPolicy` reports RedirectionTrust flags 1 in SSH and 0 in Tern, and sshd's IFEO mitigation enables it. The plugin CLI exposes no copy mode, and OMP's installer documentation says both marketplace and local links create junctions on Windows.

Trusted junction recreation requires elevation and every upgrade recreates links. Disabling sshd's RedirectionGuard weakens a deliberate security boundary. Leave this unchanged for a separate decision and keep Tern for plugin-loading commands.

## Risks / Trade-offs

Current-user DPAPI ciphertext remains credential runtime state, not a declarative file. A fresh account must sign in locally before unattended SSH work. Domain connectivity remains an SSH prerequisite. Verify real pushes from both logon types before merging.
