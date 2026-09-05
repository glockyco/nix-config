## Context

See [proposal](proposal.md) for motivation and scope. This design is required because service authorization, process lifetime, and platform packaging cross security boundaries.

Read-only evidence from 2026-09-05:

- `desktop` is enrolled as `tag:desktop`, address `100.91.92.64`. Connections must use its MagicDNS name, not this recorded address.
- RDP negotiated TLS with CredSSP/NLA over Tailscale. TCP 445 accepted a connection; WinRM timed out. Earlier SSH probes timed out.
- LAN probes timed out from Korolev and reported no route from the Pro. These do not establish effective firewall enforcement.
- The console reported Windows 10 22H2. Edition, patch support, account permissions, installed tools, and session policies remain uninspected.
- Upstream OMP publishes Windows binaries. No native agent, authenticated file access, RDP login, or session-persistence trial ran on this desktop.

## Goals / Non-Goals

**Goals:** Use existing native services and a maintained terminal multiplexer. Preserve local recovery and distinguish live process persistence from saved conversation recovery.

**Non-goals:** A general fleet framework, custom agent service, or changes to the work-machine Windows document. GUI automation and exact-console viewing are not acceptance substitutes for RDP access.

## Decisions

### 1. Keep the desktop an explicitly operated Windows peer

Use supported Windows installers, service controls, and firewall tools. Extend an existing focused operations document with the desktop procedure and link it from README. Do not create another architecture manual or duplicate the employer-oriented `modules/windows/` document.

The procedure records exact accepted OMP, plugin, psmux, and dependency versions and upstream provenance. Repeated operations compare existing state before adding keys, shares, or rules. It does not become an update wrapper or scheduler. Nix owns only applicable source-client configuration, not desktop installation or mutable runtime state.

This retains the fleet's unmanaged-peer boundary. A declarative desktop configuration generator would require a separate reviewed ownership change, not an incidental extension of employer provisioning.

### 2. Bootstrap through an approved Windows session

First obtain authenticated local or RDP access. The owner enters account credentials and administrator approvals locally. Record the intended ordinary user and existing service configuration without exporting secrets. Keep a local administrator recovery path before modifying listeners or firewall rules.

Inspect Windows edition and supported security-update status. An unsupported OS without an approved update-support path blocks new service deployment; do not schedule an unrequested OS upgrade. Inspect existing RDP credentials/certificate through the trusted local session before saving remote connections. A successful unauthenticated handshake is not server-certificate verification.

### 3. OpenSSH, PowerShell, and separate source credentials

Use Windows OpenSSH Server and PowerShell 7 as the default interactive shell. Configure public-key-only SSH for the selected non-administrator account and preserve SFTP. Verify the Windows authorization-file ACLs and effective OpenSSH configuration, not just file content. Do not run agents with an elevated token.

Each source owns its private key. Reuse an appropriate existing user key where its policy permits; otherwise generate a new user-owned desktop-access key locally. Never reuse Korolev's root-owned Mac builder key. Enroll public keys through the trusted desktop session and pin the measured host key on clients. Record source labels so the Air key can be revoked independently.

Use existing platform SSH configuration ownership for managed clients, and a normal SSH entry on the temporary Air. Scope identities and username to `desktop`; do not change wildcard authentication behavior. Configure terminal-capable SSH separately from noninteractive command invocations. No forwarding or elevation is added merely for possible future editor features.

### 4. Native OMP and the personal plugin source

Install the official Windows executable, explicitly selecting the standalone distribution rather than accidentally choosing a Bun-global installation. Select and record a verified version during implementation. Establish provider authentication locally through supported login flows.

Load the plugin from a verified source revision through its supported extension and plugin-directory flags. Start from the repository's recorded personal-plugin input revision, but do not copy its Nix-store output or interpreter paths. The source checkout is updated explicitly, not by automatic pull at launch. Retain the previous accepted version for recovery.

Provide native Git, PowerShell, OpenSpec, Python for research helpers, and the language servers required by the personal plugin and chosen Windows workload. Verify command discovery from the actual SSH-launched agent, including paths containing spaces. Git Bash is acceptable native tooling if needed; a `bash.exe` that invokes WSL is not. The agent shell implementation need not itself be PowerShell, but native PowerShell invocation must work.

Smoke-test extension loading, a commit preview, OpenSpec discovery, a local Python helper invocation, and diagnostics in disposable representative language projects. Do not fabricate missing dependencies or silently remove personal capabilities. Plugin compatibility defects belong to a separate change in `omp-agent-setup`; this change remains blocked until its accepted revision works.

### 5. psmux owns live terminal persistence

The proposed terminal path is `SSH -> psmux -> OMP`, with one named session per repository/task. Use upstream session creation, listing, detach, and attach commands rather than a custom launcher. Keep multiplexer control endpoints local to Windows; remote access goes through authenticated SSH.

Released psmux v3.3.8 explicitly requests Windows job breakaway when starting its server, but can fall back without it. Therefore startup alone is insufficient evidence. Verify graceful detachment and abrupt SSH-client termination during a bounded, harmless agent task. Record the unchanged agent process identity, continuing output, cross-source reattachment, and a subsequent prompt.

Windows 10 ConPTY has documented mouse limitations. Start with ordinary SSH and keyboard interaction; verify rendering, resizing, paste, Unicode, and interrupt handling. Do not enable unsafe mouse overrides. A required workaround or failed persistence trial triggers design review, not a false completion or substitution of RDP for SSH acceptance.

Alternatives: ordinary `Start-Process` does not prove escape from an SSH process job; OMP resume restores history, not a live process. RPC/RPC-UI are stdio interfaces, not reconnectable session servers. WezTerm has a native Windows mux server, but its SSH lifetime still needs proof and requires compatible clients. No custom broker is justified before testing psmux.

### 6. RDP and file access remain independent services

Inspect and reuse existing RDP rather than assuming it is disabled. Keep NLA, verify server identity, and save a desktop connection on each permitted source. Use Windows App on the Macs and a supported Linux RDP client on Korolev if absent. Do not alter Korolev's Windows host. Confirm effective disconnected-session limits preserve work. Disconnect is not sign-out; retain screen locking and UAC.

Prove an ordinary terminal task survives RDP disconnect and returns in the same user session. Launch graphical applications in that session; SSH service context does not imply access to its screen. Reboot and sign-out end live agent sessions. Recovery uses explicit OMP resume, never automatic replay of mutations.

Use SFTP for common cross-platform transfers. Add or reuse an operator-selected SMB transfer folder with explicit share and NTFS permissions; do not share full disks. Default to a dedicated transfer folder, and add research/project folders only after owner selection. Test content hashes and denied access. Keep active repositories local and transfer results deliberately.

### 7. Restrict effective access, not just new allow rules

The existing tailnet grants already authorize the desktop and exclude Korolev. Keep policy unchanged. Scope Windows SSH, RDP, and SMB rules to the Tailscale interface and relevant IPv4/IPv6 addresses as supported by the host. Inspect all effective rules and existing broad service exceptions. Source-address ranges alone do not establish interface isolation.

Validate allowed Tailscale paths alongside denied LAN paths from a source with independently demonstrated LAN reachability. Include RDP UDP where enabled and both IP families where available. Review inherited SMB rules and administrative shares so new access is not accidentally broader than intended. Do not delete unrelated existing shares.

Enable Tailscale's supported unattended operation and verify service startup after an owner-coordinated reboot. Preserve disk encryption and any required local preboot unlock. Do not promise continuous remote availability during sleep or automatic wake. No public ports, exit nodes, relay service, or inbound Korolev rules are needed.

## Risks / Trade-offs

- No authenticated desktop access yet -> bootstrap and inventory precede installation; no speculative account or edition assumptions.
- Windows 10 support status is unknown -> require a supported security-update path before expanding exposure.
- psmux and OMP compatibility is source-backed only -> retain live disconnect/reattach as a blocking acceptance gate.
- Manual desktop setup can drift -> retain one concise procedure, accepted versions, and repeatable state checks; no competing generator.
- RDP locking differs from GUI automation -> test terminal retention, but keep unattended GUI automation outside scope.
- Host-level access changes can strand recovery -> retain local access and snapshots of only the settings this change owns.
- Hosted collab links confer session control -> exclude collab and its relay from this implementation. It remains an optional future decision.

## Migration Plan

1. Inspect the desktop through an authenticated session and record current owned settings and recovery access.
1. Establish tailnet-restricted OpenSSH and one Pro client, then prove authentication and native command status.
1. Install the native agent stack and complete the psmux trial from Pro to Korolev before wider client rollout.
1. Complete Air client enrollment, RDP, selected file access, and all-source checks. Extend Air offboarding with desktop key revocation.
1. Verify network isolation, a different-network connection, and a coordinated desktop reboot. Recheck the existing Mac builder path.
1. Record evidence and accepted versions with this change. Keep operator instructions concise and separate from transient execution evidence.

Rollback restores only captured SSH, firewall, RDP, and share settings that this change altered, through the retained local session. Revoke newly added public authorizations and remove only change-owned client entries when abandoning access. Restore previous tool versions without deleting repositories, credentials, or agent history. Nix generation rollback does not undo Windows setup.

## Sources

- [OMP Windows release](https://github.com/can1357/oh-my-pi/releases/tag/v18.1.10) and [installer](https://github.com/can1357/oh-my-pi/blob/main/scripts/install.ps1).
- [OMP collab](https://github.com/can1357/oh-my-pi/blob/v18.1.10/docs/collab.md) and [RPC](https://github.com/can1357/oh-my-pi/blob/v18.1.10/docs/rpc.md): guest interfaces do not preserve host lifetime.
- [psmux released process handling](https://github.com/psmux/psmux/blob/v3.3.8/src/platform.rs) and [mouse/SSH constraints](https://github.com/psmux/psmux/blob/master/docs/mouse-ssh.md). Main documentation can describe newer behavior than a release.
- [Microsoft disconnected sessions](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/tsdiscon), [Start-Process](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/start-process), and [service desktop isolation](https://learn.microsoft.com/en-us/windows/win32/services/interactive-services).
