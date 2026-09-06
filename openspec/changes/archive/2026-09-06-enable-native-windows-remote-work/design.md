## Context

See [proposal](proposal.md) for motivation and scope. This design is required because service authorization, process lifetime, and platform packaging cross security boundaries.

Read-only evidence from 2026-09-05, superseded in part by the measured inventory below:

- `desktop` is enrolled as `tag:desktop`, address `100.91.92.64`. Connections must use its MagicDNS name, not this recorded address.
- RDP negotiated TLS with CredSSP/NLA over Tailscale. TCP 445 accepted a connection; WinRM timed out. Earlier SSH probes timed out.
- Upstream OMP publishes Windows binaries.

Measured on the desktop on 2026-09-06, replacing the earlier unknowns:

- Windows 10 Pro N (`ProfessionalN`) 22H2. Build `19045.6466` at inventory, `19045.7663` after enrollment in consumer ESU and the pending servicing run.
- Consumer ESU is an account entitlement delivered through Windows Update. Every `Client-ESU-Year*` SKU reports `LicenseStatus=0`, so licensing state is not a usable gate; a post-2025-10-14 cumulative update is the evidence that the support path works. Windows itself reports `LicenseStatus=5`, which did not block servicing.
- The only enabled account is a local administrator, and the built-in `Administrator` is disabled. There is no separate standard user and no second administrator recovery account. The account has a password, last set 2019-10-13; an earlier note here recorded it as blank, which a later measurement contradicted. `PasswordRequired` is `false`, which is a policy flag rather than evidence of an empty password.
- `OpenSSH.Server` was `NotPresent`; the OpenSSH client, PowerShell 7.6.5, Git, Node, Bun, Python 3.13 and `gh` were present. `rg`, `openspec` and `psmux` were absent. OMP 18.1.11 was already installed as a Bun-global shim, the distribution this design rejects.
- `bash` resolves to `C:\Windows\system32\bash.exe`, the WSL launcher. WSL 2 already hosts Ubuntu plus Docker Desktop's distributions.
- 1,921 firewall rules, 1,513 of them enabled inbound allow rules, almost all application-scoped. No enabled inbound rule permits 3389, 445 or 139: `Remote Desktop - User Mode` and `File and Printer Sharing` are all disabled. Inbound reach comes from two `Tailscale-In` rules that allow any protocol to `100.91.92.64/32` and the tailnet IPv6 address, so RDP and SMB were already tailnet-only, and destination-scoped rather than interface-bound.
- Shares `C` and `D` map `C:\` and `D:\` with the account granted Full, alongside the default `C$`, `D$`, `E$`, `ADMIN$` and `IPC$`. `LimitBlankPasswordUse=1` remains at its default, which blocks network logon for any account whose password is empty.
- RDP is enabled with NLA and TLS, no session time limits and `fResetBroken=0`, so disconnected sessions persist. Its certificate is `CN=DESKTOP-DBHLRDD`, expiring 2026-12-12.
- No BitLocker: every volume is `FullyDecrypted` with protection off, so there is no preboot unlock to preserve.
- Sleep on AC is disabled, but Fast Startup is enabled, so a reboot verification must be a true restart.
- ZeroTier, TeamViewer and Chrome Remote Desktop are installed with application-scoped inbound allow rules. TeamViewer's are Public-profile only and every active interface is Private, so those are currently inert.

## Goals / Non-Goals

**Goals:** Use existing native services and a maintained terminal multiplexer. Preserve local recovery and distinguish live process persistence from saved conversation recovery.

**Non-goals:** A general fleet framework, custom agent service, or changes to the work-machine Windows document. GUI automation and exact-console viewing are not acceptance substitutes for RDP access.

## Decisions

### 1. Keep the desktop an explicitly operated Windows peer

Use supported Windows installers, service controls, and firewall tools. Extend an existing focused operations document with the desktop procedure and link it from README. Do not create another architecture manual or duplicate the employer-oriented `modules/windows/` document.

The procedure records exact accepted OMP, plugin, psmux, and dependency versions and upstream provenance. Repeated operations compare existing state before adding keys, shares, or rules. It does not become an update wrapper or scheduler. Nix owns only applicable source-client configuration, not desktop installation or mutable runtime state.

This retains the fleet's unmanaged-peer boundary. A declarative desktop configuration generator would require a separate reviewed ownership change, not an incidental extension of employer provisioning.

### 2. Bootstrap through an approved Windows session

First obtain authenticated local or RDP access. The owner enters account credentials and administrator approvals locally. Record the intended user and existing service configuration without exporting secrets. Keep a local administrator recovery path before modifying listeners or firewall rules.

The measured machine has one enabled account, which is a local administrator, and no second administrator account to recover through. The owner accepted that account for SSH rather than creating a standard user, so the recovery path is the local interactive session itself. Elevation is approved at the console; a UAC prompt raised from an unattended context expires after roughly two minutes and auto-denies, so privileged steps run in an already-elevated session instead.

Inspect Windows edition and supported security-update status. An unsupported OS without an approved update-support path blocks new service deployment; do not schedule an unrequested OS upgrade. Inspect existing RDP credentials/certificate through the trusted local session before saving remote connections. A successful unauthenticated handshake is not server-certificate verification.

### 3. OpenSSH, PowerShell, and separate source credentials

Use Windows OpenSSH Server and PowerShell 7 as the default interactive shell. Configure public-key-only SSH for the selected account and preserve SFTP. Verify the Windows authorization-file ACLs and effective OpenSSH configuration, not just file content.

The selected account is a local administrator, so `sshd` reads `__PROGRAMDATA__/ssh/administrators_authorized_keys` through its `Match Group administrators` block, not the profile's `.ssh`. That file's ACLs must grant only Administrators and SYSTEM or keys are silently refused. Per-source revocation is therefore a single labelled line in that one file. The Pro observed enabled administrator privileges in the SSH token. Agents inherit that token without an additional elevation prompt. This is the accepted account choice; console approval for privileged service changes remains operator policy, not token isolation.

Disabling `PasswordAuthentication` alone is insufficient: the Windows server still offers `keyboard-interactive`, which reaches the same credential. Both must be disabled, and both must sit in the global section, because a directive placed after a `Match` block applies only to that match.

Each source owns its private key. Reuse an appropriate existing user key where its policy permits; otherwise generate a new user-owned desktop-access key locally. Never reuse Korolev's root-owned Mac builder key. Enroll public keys through the trusted desktop session and pin the measured host key on clients. Record source labels so the Air key can be revoked independently.

Use existing platform SSH configuration ownership for managed clients, and a normal SSH entry on the temporary Air. Scope identities and username to `desktop`; do not change wildcard authentication behavior. Configure terminal-capable SSH separately from noninteractive command invocations. No forwarding or elevation is added merely for possible future editor features.

### 4. Native OMP and the personal plugin source

Install the official Windows executable, explicitly selecting the standalone distribution rather than the Bun-global installation already present on this machine. Select and record a verified version during implementation. Establish provider authentication locally through supported login flows.

Load the plugin from a verified source revision through its supported extension and plugin-directory flags. Start from the repository's recorded personal-plugin input revision, but do not copy its Nix-store output or interpreter paths. The source checkout is updated explicitly, not by automatic pull at launch. Retain the previous accepted version for recovery.

Provide native Git, PowerShell, OpenSpec, and Python for research helpers. Language servers are deliberately excluded from this native Windows layer: the owner does development work on the Macs, on Korolev, and in future in the planned NixOS-WSL host on this machine, so pinning Windows language-server artifacts would create dependency maintenance for a capability nobody uses natively. The plugin's server selections stay unsatisfied for the native agent.

That NixOS-WSL host will bring language servers to this machine through Nix, but inside WSL and for an agent running there. It does not satisfy this requirement and does not reinstate it: the native Windows agent still must not resolve any tool through a WSL launcher, and a WSL-hosted server is not a native Windows artifact. Providing servers to the native agent later is a dependency change with its own version and provenance work.

Verify command discovery from the actual SSH-launched agent, including paths containing spaces. Git Bash is acceptable native tooling if needed; a `bash.exe` that invokes WSL is not. The agent shell implementation need not itself be PowerShell, but native PowerShell invocation must work.

Smoke-test extension loading, a commit preview, OpenSpec discovery, and a local Python helper invocation in a disposable checkout. Do not fabricate missing dependencies or silently remove personal capabilities. Plugin compatibility defects belong to a separate change in `omp-agent-setup`; this change remains blocked until its accepted revision works.

### 5. Terminal convenience without a persistence guarantee

This desktop is driven for agentic work through non-interactive `ssh <command>` invocations, so live agent persistence across a lost SSH connection buys nothing and this change accepts no such capability. An agent started through SSH may end with its connection, and OMP's saved conversation state is resumed explicitly. The procedure must not describe resumed history as a surviving process, and no custom broker, service, or scheduled task is introduced to manufacture persistence.

No multiplexer is part of the accepted desktop. psmux 3.3.8 was installed during investigation and removed afterwards, so the desktop carries no dependency for a capability nobody uses and no manual update burden for one.

Anyone who later needs persistence starts from an open question, not from these results: released psmux v3.3.8 requests Windows job breakaway but can fall back, so whether an agent survives a dropped client is untested here. Proving it requires the detachment and abrupt-termination trials with recorded process identity, continuing output and cross-source reattachment, plus a terminal-attached interrupt. Rendering, resizing, Unicode, paste and loopback-only endpoints did pass while it was installed.

### 6. RDP and file access remain independent services

SMB is recorded, not adopted: SFTP is the accepted transfer mechanism, no share is added, and the platform's administrative shares are left in place. Inspect and reuse existing RDP rather than assuming it is disabled. Keep NLA, verify server identity, and save a desktop connection on each permitted source. Use Windows App on the Pro. Graphical access from the Air and Korolev is out of scope: they need SSH and file transfer only, so no client is installed there. Do not alter Korolev's Windows host. Confirm effective disconnected-session limits preserve work. Disconnect is not sign-out; retain screen locking and UAC.

Prove an ordinary terminal task survives RDP disconnect and returns in the same user session. Launch graphical applications in that session; SSH service context does not imply access to its screen. Reboot and sign-out end live agent sessions. Recovery uses explicit OMP resume, never automatic replay of mutations.

Use SFTP for common cross-platform transfers. Add or reuse an operator-selected SMB transfer folder with explicit share and NTFS permissions; do not share full disks. Default to a dedicated transfer folder, and add research/project folders only after owner selection. Test content hashes and denied access. Keep active repositories local and transfer results deliberately.

### 7. Restrict effective access, not just new allow rules

The existing tailnet grants already authorize the desktop and exclude Korolev. Keep policy unchanged. Scope Windows SSH, RDP, and SMB rules to the Tailscale addresses and relevant address families as supported by the host. Inspect all effective rules and existing broad service exceptions. Source-address ranges alone do not establish interface isolation.

The capability installer adds an all-profiles allow rule for port 22; disable it and add a rule whose local address is the tailnet address, rather than relying on the `Tailscale-In` any-protocol rule. That keeps the restriction inspectable and honours the requirement that losing Tailscale must not leave a permissive path.

ZeroTier, TeamViewer and Chrome Remote Desktop reach the desktop through their own authenticated relays, not through an inbound tailnet path, so scoping firewall rules cannot bound them. Record them and their effective scope; do not remove working owner tooling to make the tailnet claim look broader than the requirement states. Taildrop is unavailable to this host because a tagged node has no user owner, which is consistent with SFTP being the chosen transfer mechanism.

Validate allowed Tailscale paths alongside denied LAN paths from a source with independently demonstrated LAN reachability. Include RDP UDP where enabled and both IP families where available. Review inherited SMB rules and administrative shares so new access is not accidentally broader than intended. Do not delete unrelated existing shares.

Enable Tailscale's supported unattended operation and verify service startup after an owner-coordinated reboot. No volume on this machine is encrypted, so there is no preboot unlock to preserve; record that rather than implying one exists. Fast Startup is enabled, so a reboot verification must be a true restart. Do not promise continuous remote availability during sleep or automatic wake. No public ports, exit nodes, relay service, or inbound Korolev rules are needed.

Unattended operation is not sufficient by itself: the node's key expiry must also be disabled, as it already is on Korolev and the Pro. An expiring key removes the desktop from the tailnet and requires console re-authentication, which is precisely what remote access is meant to avoid. That setting lives on the coordination server, not in the rendered policy file and not in any host declaration, so this repository cannot express it. The operating procedure owns it, together with the verification that the node reports no expiry.

### 8. WSL is permitted; a NixOS-WSL desktop host is follow-on work

WSL already runs on this machine and the owner wants a NixOS-WSL host here, mirroring Korolev. Permit WSL and stop treating its presence as a defect. The native Windows access layer in this change does not depend on it, and the native agent's toolchain still must not resolve through a WSL launcher.

Declaring that host is deliberately out of scope here. `flake.nix` keys its host table by system, `hosts.x86_64-linux` is Korolev, and the flake records that Korolev is the only `x86_64-linux` host, so a second Linux host has no row to occupy. The deferred `key-fleet-by-host` change re-keys the table by host name and is the prerequisite; its own scheduling notice requires the owner to schedule it after a plan review. A desktop NixOS-WSL host is the concrete use requirement that notice asks for, but it is a separate change, and the agent surface for the desktop stays undecided until it exists.

### 9. Repair native gate defects without weakening acceptance

The owner approved repairs to dependency defects exposed by the Pro's release gates. Keep them in the existing package overlay and preserve the single package set shared by each host and its outputs. Do not disable temporary-path auditing, discard documentation, suppress warnings, or disable the evaluation cache.

Documentation normalization composes the existing `nixosOptionsDoc.transformOptions` interface. After the caller's transformation, convert only declarations under the pinned Nixpkgs source into `<nixpkgs/...>` references. Preserve caller-generated URL records and unrelated option fields. This removes build-machine store locations from documentation without importing a second Nixpkgs package set.

The temporary-path audit crash stays an upstream Nixpkgs defect. Its hook belongs to the standard environment, which offers no override for replacing a default setup hook, so a local fix means patching the Nixpkgs source. A dry run of that approach rebuilds the bootstrap toolchain from source, which the build-plan guard rejects and which is a worse outcome than the defect. Do not disable the audit, suppress its output, or vendor a patched standard environment. Record the diagnosis and both defects instead: an intermittent classifier crash on Darwin, and a background classifier whose failure the audit never collects.

Run the final Nix gates sequentially to avoid simultaneous writers to their shared SQLite evaluation cache.

The approved Windows preview remains a manual platform operation. Verify release digests and Microsoft signatures, test the existing host identity and authentication policy in isolation, and retain local recovery before service replacement. Use the supported ZIP installation procedure rather than the MSI's broad firewall exception. Preserve host keys, authorization, and the tailnet restriction; do not suppress the post-quantum warning on the old service.

## Risks / Trade-offs

- The SSH token has enabled administrator privileges -> accepted account choice; keys live in the restricted administrators file. Privileged service changes still need console approval, which is operator policy rather than token isolation.
- One enabled account and no second administrator -> the local interactive session is the only recovery path; do not modify listeners without it available.
- Consumer ESU reports no licensed SKU -> gate on a delivered post-end-of-support cumulative update instead, and re-check after each servicing run.
- psmux and OMP compatibility is source-backed only -> retain live disconnect/reattach as a blocking acceptance gate.
- Manual desktop setup can drift -> retain one concise procedure, accepted versions, and repeatable state checks; no competing generator.
- RDP locking differs from GUI automation -> test terminal retention, but keep unattended GUI automation outside scope.
- Host-level access changes can strand recovery -> retain local access and snapshots of only the settings this change owns.
- Hosted collab links confer session control -> exclude collab and its relay from this implementation. It remains an optional future decision.

## Migration Plan

1. Inspect the desktop through an authenticated session and record current owned settings and recovery access.
1. Establish tailnet-restricted OpenSSH/SFTP and one Pro client. Prove host identity, authentication, native command status, effective network isolation, and a disposable transfer with matching hashes.
1. Use the verified Pro transfer path for the separately operated YNAB migration. Preserve the Windows original. Repository publication, financial-data storage, synchronization, and backups remain outside this access change.
1. Review the intended Windows account's filesystem access before enrolling other sources. Separate keys support revocation but do not isolate files between clients using the same account. Do not infer permission to copy financial data to Korolev or the borrowed Air from desktop-access authorization.
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
