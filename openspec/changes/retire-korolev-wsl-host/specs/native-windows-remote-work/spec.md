# Spec Delta

## MODIFIED Requirements

### Requirement: Explicit desktop provisioning boundary

Desktop setup SHALL use supported native Windows tools and explicit operator actions. Nix activation on the Pro SHALL NOT apply desktop settings. The employer Windows configuration SHALL remain unchanged. Credentials, SSH private keys and agent state SHALL remain outside the repository and Nix store.

The selected desktop account is the owner's existing local administrator account. Its SSH sessions have enabled administrator privileges without an additional elevation prompt. Agents SHALL use the approved SSH session without adding a separate elevation mechanism, scheduled task, or agent service. Privileged service changes SHALL still require explicit local approval. This approval requirement is an operator policy, not a technical restriction of the account's token.

#### Scenario: Provision the personal desktop

- **WHEN** the operator applies the reviewed desktop setup
- **THEN** only the personal desktop and its explicitly selected client connections change
- **AND** privileged service operations require local approval, without supplying passwords through an agent conversation

#### Scenario: Activate an existing managed host

- **WHEN** the Pro activates a Nix generation
- **THEN** it does not install desktop applications, modify desktop services or copy authentication state

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
- **THEN** approved Mac and desktop keys reach native Windows Korolev over Tailscale and non-tailnet SSH remains blocked
- **AND** native Korolev-to-Mac user command-status checks pass without a Linux builder/distribution
