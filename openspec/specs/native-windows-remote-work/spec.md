# Native Windows Remote Work Specification

## Purpose

Provides authenticated remote work on the personal Windows desktop for commands, files, and graphical access, without a Linux compatibility layer and without claiming that an agent survives a lost connection.

## Requirements

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

The Pro, Air and native Windows Korolev SHALL reach `desktop` with native OpenSSH, independently approved credentials and a pinned server identity. The Pro SHALL likewise reach Windows Korolev with its own source key. Commands run without a terminal SHALL preserve native Windows shell behavior and exit status. Network membership SHALL not grant account access; revoking one source key SHALL not revoke others.

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

#### Scenario: Reach the standard work account

- **WHEN** the Pro authenticates to Windows Korolev
- **THEN** it reaches the approved standard account without password or keyboard-interactive fallback
- **AND** a command exiting 23 returns status 23
- **AND** a privileged service operation still requires separate owner-assisted local Administrator approval

### Requirement: Native agent environment

OMP SHALL operate in a local Windows checkout using native Windows tools. OMP SHALL be the official standalone Windows binary installed through the official installer in binary mode and updated explicitly through `omp update`. The personal plugin SHALL be installed in user scope using the plugin-manager install command defined by `publish-plugin-through-omp-plugin-manager` (`omp plugin marketplace add glockyco/omp-agent-setup`, then `omp plugin install --scope user personal@glockyco`) and upgraded with `omp plugin marketplace update glockyco` followed by `omp plugin upgrade --scope user personal@glockyco` and a fresh session. It SHALL not load from a manual source checkout, explicit wrapper flags, or a copied Nix-store wrapper. Required workflow dependencies SHALL resolve natively. Each installation SHALL keep its own writable authentication and session state.

WSL may be installed on the desktop and SHALL NOT be treated as a defect. A required native tool SHALL NOT be satisfied by a WSL launcher: in particular the desktop's `bash.exe` resolves to WSL, so a native shell requirement SHALL be met by PowerShell or Git Bash instead. A NixOS-WSL host on this machine is a separate configuration with its own agent installation and is outside this capability.

#### Scenario: Complete native repository work

- **WHEN** the operator starts the official agent in a disposable Windows checkout
- **THEN** the agent completes a harmless repository task using Windows tools
- **AND** the plugin-manager personal policy extension loads and completes a commit preview without creating a commit
- **AND** required shell, Git, OpenSpec, and research-helper functions pass their applicable smoke checks, with OpenSpec workflows exposed as `/personal:opsx-*`
- **AND** language-server diagnostics remain out of scope for the native desktop agent, which SHALL NOT resolve a server through a WSL launcher; a separate WSL host may serve its own agent instead

#### Scenario: Inspect local runtime ownership

- **WHEN** the operator checks the agent's executable, plugin-manager installation, and state paths
- **THEN** no executable or interpreter used by the native Windows agent resolves through WSL or a Nix store path
- **AND** provider authentication was established locally rather than copied from another machine

#### Scenario: Update the native installation

- **WHEN** the operator explicitly updates the desktop's OMP and published personal plugin through their upstream commands
- **THEN** a fresh native session verifies observed executable/plugin versions and personal behavior
- **AND** native writable authentication and saved conversations remain in place

### Requirement: Honest agent session lifetime

Live agent persistence across a lost SSH connection is out of scope: the desktop is driven for agentic work through non-interactive SSH commands. An agent started through SSH MAY end with its connection. The procedure SHALL NOT claim that a process survived a lost connection, and SHALL NOT present resumed conversation history as a live process. A multiplexer MAY be installed for convenience without being an accepted capability.

#### Scenario: Lose the initiating connection

- **WHEN** the initiating SSH client is terminated during an agent task
- **THEN** the procedure makes no claim that the task continued
- **AND** the operator resumes saved conversation state explicitly rather than relying on a live process

#### Scenario: Recover after reboot

- **WHEN** the desktop reboots during agent work
- **THEN** the system does not claim that the previous process survived
- **AND** the operator can explicitly resume saved conversation state without automatically replaying interrupted mutations

### Requirement: Graphical access with retained disconnected sessions

The Pro SHALL have a usable RDP client path to the desktop with verified server identity and Network Level Authentication. Graphical access from the Air and the WSL host is out of scope; only SSH and file transfer are required from them. Disconnecting the RDP client SHALL retain ordinary terminal computation in the existing Windows user session. Setup SHALL NOT disable screen locking or bypass elevation prompts to support agents.

#### Scenario: Return to a graphical work session

- **WHEN** the operator starts a harmless terminal task through RDP, disconnects, and reconnects as the same Windows user
- **THEN** the existing task and desktop session remain available
- **AND** configured session timeouts do not silently log off that accepted working session

#### Scenario: Distinguish disconnection from sign-out

- **WHEN** the operator follows the desktop procedure
- **THEN** it distinguishes RDP disconnect, workstation lock, sign-out, sleep, and reboot
- **AND** it does not promise GUI automation while locked or continuous execution during sleep

### Requirement: Authenticated bounded file access

Authorized sources SHALL transfer files through SFTP, which is the accepted transfer mechanism. Working repositories SHALL remain local to the desktop. SMB is not an accepted capability of this change: no new share SHALL be added, no guest access SHALL be enabled, and the platform's existing administrative shares SHALL be recorded rather than exercised.

Because the selected account is a local administrator, whole-volume access over SMB follows from the platform's administrative shares and SHALL NOT be reported as a bounded-folder guarantee. The implementation SHALL record which shares exist, SHALL NOT add a redundant explicit whole-volume share alongside them, and SHALL leave unrelated existing shares in place.

#### Scenario: Transfer a file without corruption

- **WHEN** an authorized source uploads and downloads a file through SFTP
- **THEN** the returned bytes match the original

#### Scenario: Leave file sharing unchanged

- **WHEN** the implementation finishes
- **THEN** no share was added and no guest access was enabled
- **AND** the remaining administrative shares are recorded, with whole-volume reach attributed to administrator membership rather than to a share

### Requirement: Tailnet-only access and existing fleet isolation

Desktop SSH, RDP and SMB SHALL retain effective approved-tailnet restrictions. Native Korolev SSH SHALL be bound/restricted to its tailnet addresses with independently approved keys. WSL SHALL retain its no-listener boundary. Loss of Tailscale SHALL not create a permissive fallback. Independent authenticated desktop relay products remain outside this service boundary and SHALL be enumerated with effective firewall scope.

#### Scenario: Compare allowed and denied paths

- **WHEN** an authorized source tests a configured service through Tailscale and through a reachable non-tailnet interface
- **THEN** the tailnet connection succeeds and the non-tailnet connection fails
- **AND** a missing route is not accepted as proof of firewall enforcement

#### Scenario: Work away from home

- **WHEN** a source and the desktop use different physical networks
- **THEN** the saved desktop name supports authenticated terminal, graphical, and file access without router port forwarding

#### Scenario: Preserve the installed fleet

- **WHEN** desktop setup completes
- **THEN** the approved Mac key reaches Windows Korolev over Tailscale, while non-tailnet SSH and WSL inbound services remain blocked
- **AND** Korolev's native command-status check against the Pro still passes

### Requirement: Explicit operational recovery

The operating procedure SHALL identify installed versions, owned settings, local recovery access, key revocation, and service rollback. Repeating setup SHALL NOT duplicate keys, shares, or firewall rules. Service recovery SHALL preserve repositories and agent state. Desktop remote access SHALL return after an approved reboot without automatic agent execution. The desktop's Tailscale node key expiry SHALL be disabled and verified in node status. The operating procedure SHALL identify this coordination-server setting as state outside the repository's host and policy declarations.

#### Scenario: Repeat or reverse setup

- **WHEN** the operator repeats setup or restores the previous owned service configuration
- **THEN** access entries are not duplicated and unrelated settings remain intact
- **AND** repositories, credentials, and agent history are not deleted as a rollback side effect

#### Scenario: Reach the rebooted desktop

- **WHEN** the operator completes an approved desktop reboot
- **THEN** Tailscale and configured remote services start automatically and become reachable again
- **AND** the desktop's automatic sign-on session is recorded as its normal startup state, with its console-access consequence
- **AND** agent execution still requires an explicit operator action
