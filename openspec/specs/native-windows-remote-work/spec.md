# Native Windows Remote Work Specification

## Purpose

Provides authenticated remote work on the personal Windows desktop for commands, files, and graphical access, without a Linux compatibility layer and without claiming that an agent survives a lost connection.

## Requirements

### Requirement: Explicit desktop provisioning boundary

Desktop setup SHALL use supported native Windows tools and explicit operator actions. Nix activation on the Pro SHALL NOT apply desktop settings. The employer Windows configuration SHALL remain unchanged. Credentials, SSH private keys and agent state SHALL remain outside the repository and Nix store.

#### Scenario: Use the selected desktop account

- **WHEN** an agent uses the owner's existing local administrator account over SSH
- **THEN** its session has enabled administrator privileges without an additional elevation prompt
- **AND** agents SHALL use that approved session without adding a separate elevation mechanism, scheduled task or agent service
- **AND** privileged service changes SHALL still require explicit local approval as operator policy, not as a technical restriction of the account's token

#### Scenario: Provision the personal desktop

- **WHEN** the operator applies the reviewed desktop setup
- **THEN** only the personal desktop and its explicitly selected client connections change
- **AND** privileged service operations require local approval, without supplying passwords through an agent conversation

#### Scenario: Activate an existing managed host

- **WHEN** the Pro activates a Nix generation
- **THEN** it does not install desktop applications, modify desktop services or copy authentication state

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

OMP SHALL operate in a local desktop Windows checkout using native Windows tools and its recorded personal-plugin revision. Each installation SHALL retain its own writable authentication/session state. PowerShell or Git Bash SHALL satisfy native shell requirements, never a Linux launcher. Optional WSL installation on the personal desktop SHALL remain outside this capability; it SHALL not provide any Korolev dependency.

#### Scenario: Complete native repository work

- **WHEN** the operator starts the configured agent in a disposable Windows checkout
- **THEN** the agent completes a harmless task using Windows tools
- **AND** personal policy loads and completes a commit preview without creating a commit
- **AND** shell, Git, OpenSpec and research-helper functions pass applicable smoke checks
- **AND** desktop language-server diagnostics remain out of scope and no required executable resolves through a Linux launcher

#### Scenario: Inspect local runtime ownership

- **WHEN** the operator checks the agent's executable, plugin and state paths
- **THEN** no executable/interpreter used by the native Windows agent resolves through WSL or a Nix store
- **AND** provider authentication was established locally, not copied from another machine

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

The Pro SHALL have a usable RDP client path to desktop with verified server identity and Network Level Authentication. Graphical access from Air and native Korolev SHALL remain out of scope; they require SSH and file transfer only. RDP disconnect SHALL retain ordinary computation in the existing Windows user session. Setup SHALL NOT disable locking or bypass elevation prompts.

#### Scenario: Return to a graphical work session

- **WHEN** the operator starts a harmless terminal task through RDP, disconnects and reconnects as the same Windows user
- **THEN** the task and desktop session remain available
- **AND** configured timeouts do not silently log off that accepted session

#### Scenario: Distinguish disconnection from sign-out

- **WHEN** the operator follows the desktop procedure
- **THEN** it distinguishes RDP disconnect, lock, sign-out, sleep and reboot
- **AND** it does not promise GUI automation while locked or continuous computation during sleep

### Requirement: Authenticated bounded file access

Authorized sources SHALL transfer files through SFTP, which is the accepted transfer mechanism. Working repositories SHALL remain local to the desktop. SMB is not an accepted capability of this change: no new share SHALL be added, no guest access SHALL be enabled, and the platform's existing administrative shares SHALL be recorded rather than exercised.

#### Scenario: Inspect administrator file-sharing access

- **WHEN** the selected local administrator account can reach whole volumes through platform administrative shares
- **THEN** that reach SHALL NOT be reported as a bounded-folder guarantee
- **AND** the implementation SHALL record existing shares, add no redundant explicit whole-volume share and leave unrelated existing shares in place

#### Scenario: Transfer a file without corruption

- **WHEN** an authorized source uploads and downloads a file through SFTP
- **THEN** the returned bytes match the original

#### Scenario: Leave file sharing unchanged

- **WHEN** the implementation finishes
- **THEN** no share was added and no guest access was enabled
- **AND** the remaining administrative shares are recorded, with whole-volume reach attributed to administrator membership rather than to a share

### Requirement: Tailnet-only access and existing fleet isolation

Desktop SSH, RDP and SMB SHALL retain effective approved-tailnet restrictions. Native Korolev SSH SHALL retain its tailnet-only listening/firewall and independently approved keys. Native Windows-to-Mac user SSH SHALL remain usable; no Linux Nix-daemon builder SHALL remain required. Loss of Tailscale SHALL not create a permissive fallback. Independent authenticated desktop relay products SHALL remain outside this boundary and be enumerated with effective firewall scope.

#### Scenario: Compare allowed and denied paths

- **WHEN** an authorized source tests a configured service through Tailscale and a reachable non-tailnet interface
- **THEN** the tailnet connection succeeds and the non-tailnet connection fails
- **AND** missing routing is not accepted as proof of firewall enforcement

#### Scenario: Work away from home

- **WHEN** a source and desktop use different physical networks
- **THEN** the saved desktop name supports authenticated terminal, graphical and file access without router port forwarding

#### Scenario: Preserve the installed fleet

- **WHEN** desktop setup or Korolev retirement completes
- **THEN** the approved Mac key reaches native Windows Korolev over Tailscale and non-tailnet SSH remains blocked
- **AND** native Korolev-to-Mac user command-status checks pass without a Linux builder/distribution

### Requirement: Explicit operational recovery

The procedure SHALL identify installed versions, owned settings, local recovery access, key revocation and service rollback. Repeated setup SHALL NOT duplicate keys, shares or firewall rules. Service recovery SHALL preserve repositories and agent state. Remote access SHALL return after an approved reboot without automatic agent execution.

#### Scenario: Retain desktop tailnet enrollment

- **WHEN** the desktop's Tailscale node status is inspected
- **THEN** its node key expiry SHALL be disabled and verified
- **AND** the procedure SHALL identify this coordination-server setting as state outside repository host and policy declarations

#### Scenario: Repeat or reverse setup

- **WHEN** the operator repeats setup or restores the previous owned service configuration
- **THEN** access entries are not duplicated and unrelated settings remain intact
- **AND** repositories, credentials, and agent history are not deleted as a rollback side effect

#### Scenario: Reach the rebooted desktop

- **WHEN** the operator completes an approved desktop reboot
- **THEN** Tailscale and configured remote services start automatically and become reachable again
- **AND** the desktop's automatic sign-on session is recorded as its normal startup state, with its console-access consequence
- **AND** agent execution still requires an explicit operator action
