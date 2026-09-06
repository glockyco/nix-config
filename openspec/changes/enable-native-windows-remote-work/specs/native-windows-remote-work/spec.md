## Purpose

Provide authenticated remote work on the personal Windows desktop, including persistent native agents, files, and graphical sessions, without a Linux compatibility layer.

## ADDED Requirements

### Requirement: Explicit desktop provisioning boundary

Desktop setup SHALL use supported native Windows tools and explicit operator actions. Nix activation SHALL NOT apply desktop settings. The employer Windows configuration SHALL remain unchanged. Credentials, SSH private keys, and agent state SHALL remain outside the repository and Nix store.

The selected desktop account is the owner's existing local administrator account. Its SSH sessions have enabled administrator privileges without an additional elevation prompt. Agents SHALL use the approved SSH session without adding a separate elevation mechanism, scheduled task, or agent service. Privileged service changes SHALL still require explicit local approval. This approval requirement is an operator policy, not a technical restriction of the account's token.

#### Scenario: Provision the personal desktop

- **WHEN** the operator applies the reviewed desktop setup
- **THEN** only the personal desktop and its explicitly selected client connections change
- **AND** privileged service operations require local approval, without supplying passwords through an agent conversation

#### Scenario: Activate an existing managed host

- **WHEN** Korolev or the Pro activates a Nix generation
- **THEN** it does not install desktop applications, modify desktop services, or copy authentication state

### Requirement: Authenticated terminal access from each source

The Pro, Air, and Korolev SHALL connect to `desktop` through native OpenSSH using their own approved credentials and verified server identity. The shell SHALL support native PowerShell commands and preserve remote exit status. Network membership alone SHALL NOT grant account access. Revoking one source key SHALL NOT revoke the others.

#### Scenario: Use the desktop from each source

- **WHEN** an authorized source connects through its saved desktop SSH entry
- **THEN** it reaches the intended Windows account without address or username guessing
- **AND** a command exiting with status 23 returns status 23 to the client

#### Scenario: Reject an unknown client or server

- **WHEN** a client presents an unauthorized key or the server presents an unexpected host key
- **THEN** the connection fails without password fallback or automatic host-key acceptance

#### Scenario: Remove temporary source access

- **WHEN** the Air's desktop authorization is revoked before its return
- **THEN** the Air can no longer authenticate to the desktop
- **AND** the Pro and Korolev retain their own access

### Requirement: Native agent environment

OMP SHALL operate in a local Windows checkout using native Windows tools. The personal plugin SHALL load from a recorded, verified source revision, not a copied Nix-store wrapper. Required workflow dependencies SHALL resolve natively. Each installation SHALL keep its own writable authentication and session state.

WSL may be installed on the desktop and SHALL NOT be treated as a defect. A required native tool SHALL NOT be satisfied by a WSL launcher: in particular the desktop's `bash.exe` resolves to WSL, so a native shell requirement SHALL be met by PowerShell or Git Bash instead. A NixOS-WSL host on this machine is a separate configuration with its own agent installation and is outside this capability.

#### Scenario: Complete native repository work

- **WHEN** the operator starts the configured agent in a disposable Windows checkout
- **THEN** the agent completes a harmless repository task using Windows tools
- **AND** the personal policy extension loads and completes a commit preview without creating a commit
- **AND** required shell, Git, OpenSpec, and research-helper functions pass their applicable smoke checks
- **AND** language-server diagnostics are out of scope for the native Windows agent, which SHALL NOT resolve a server through a WSL launcher; a future WSL host may serve its own agent instead

#### Scenario: Inspect local runtime ownership

- **WHEN** the operator checks the agent's executable, plugin, and state paths
- **THEN** no executable or interpreter used by the native Windows agent resolves through WSL or a Nix store path
- **AND** provider authentication was established locally rather than copied from another machine

### Requirement: Persistent interactive agent sessions

An agent started through SSH SHALL continue in its native Windows session after the initiating SSH connection ends. An authorized client on another machine SHALL reattach to the same live session and retain interactive control. Starting a new process from conversation history SHALL NOT count as live reattachment.

#### Scenario: Reattach after deliberate detachment

- **WHEN** the operator detaches from a running agent session and reconnects from another authorized source
- **THEN** the same agent process remains available with its output and pending interaction intact

#### Scenario: Lose the initiating connection

- **WHEN** the initiating SSH client is terminated during a bounded harmless agent task
- **THEN** the task continues without that client
- **AND** another authorized source reattaches, observes the result, and submits another prompt

#### Scenario: Recover after reboot

- **WHEN** the desktop reboots during agent work
- **THEN** the system does not claim that the previous process survived
- **AND** the operator can explicitly resume saved conversation state without automatically replaying interrupted mutations

### Requirement: Graphical access with retained disconnected sessions

Authorized source machines SHALL have a usable RDP client path to the desktop with verified server identity and Network Level Authentication. Disconnecting the RDP client SHALL retain ordinary terminal computation in the existing Windows user session. Setup SHALL NOT disable screen locking or bypass elevation prompts to support agents.

#### Scenario: Return to a graphical work session

- **WHEN** the operator starts a harmless terminal task through RDP, disconnects, and reconnects as the same Windows user
- **THEN** the existing task and desktop session remain available
- **AND** configured session timeouts do not silently log off that accepted working session

#### Scenario: Distinguish disconnection from sign-out

- **WHEN** the operator follows the desktop procedure
- **THEN** it distinguishes RDP disconnect, workstation lock, sign-out, sleep, and reboot
- **AND** it does not promise GUI automation while locked or continuous execution during sleep

### Requirement: Authenticated bounded file access

Authorized sources SHALL transfer files through SFTP. Working repositories SHALL remain local to the desktop. New SMB shares SHALL NOT enable guest access, and share and filesystem permissions SHALL be explicit and inspected.

Because the selected account is a local administrator, whole-volume access over SMB follows from the platform's administrative shares and SHALL NOT be reported as a bounded-folder guarantee. The implementation SHALL record which shares exist, SHALL NOT add a redundant explicit whole-volume share alongside them, and SHALL leave unrelated existing shares in place.

#### Scenario: Transfer a file without corruption

- **WHEN** an authorized source uploads and downloads a file through SFTP or an approved SMB share
- **THEN** the returned bytes match the original

#### Scenario: Restrict a shared folder

- **WHEN** an unauthorized account accesses an approved share or a read-only account attempts a write
- **THEN** Windows denies the operation
- **AND** unrelated folders receive no new share authorization

### Requirement: Tailnet-only access and existing fleet isolation

Desktop SSH, RDP, and SMB access SHALL be restricted to approved tailnet paths through effective host service and firewall settings. Existing broader rules SHALL NOT defeat that boundary. The implementation SHALL preserve Korolev's no-inbound policy and the Pro's existing builder access. Loss of Tailscale SHALL NOT create a permissive listener or firewall fallback.

This restriction covers the services this change configures. Independent remote-access products already installed on the desktop reach it through their own authenticated relays rather than through an inbound tailnet path, so they are outside the boundary this requirement asserts. The implementation SHALL enumerate them with their effective firewall scope rather than claim the desktop is reachable only through the tailnet.

#### Scenario: Compare allowed and denied paths

- **WHEN** an authorized source tests a configured service through Tailscale and through a reachable non-tailnet interface
- **THEN** the tailnet connection succeeds and the non-tailnet connection fails
- **AND** a missing route is not accepted as proof of firewall enforcement

#### Scenario: Work away from home

- **WHEN** a source and the desktop use different physical networks
- **THEN** the saved desktop name supports authenticated terminal, graphical, and file access without router port forwarding

#### Scenario: Preserve the installed fleet

- **WHEN** desktop setup completes
- **THEN** attempts to initiate inbound connections to Korolev remain blocked
- **AND** the existing Korolev-to-Pro remote build and command-status checks still pass

### Requirement: Explicit operational recovery

The operating procedure SHALL identify installed versions, owned settings, local recovery access, key revocation, and service rollback. Repeating setup SHALL NOT duplicate keys, shares, or firewall rules. Service recovery SHALL preserve repositories and agent state. Desktop remote access SHALL return after an approved reboot without automatic agent execution. The desktop's Tailscale node key expiry SHALL be disabled and verified in node status. The operating procedure SHALL identify this coordination-server setting as state outside the repository's host and policy declarations.

#### Scenario: Repeat or reverse setup

- **WHEN** the operator repeats setup or restores the previous owned service configuration
- **THEN** access entries are not duplicated and unrelated settings remain intact
- **AND** repositories, credentials, and agent history are not deleted as a rollback side effect

#### Scenario: Reach the rebooted desktop

- **WHEN** the operator completes an approved desktop reboot and any required local disk unlock
- **THEN** Tailscale and configured remote services become reachable without an interactive Windows sign-in
- **AND** agent execution still requires an explicit operator action
