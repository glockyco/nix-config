# Acceptance evidence

Measured on the desktop. This file records what was observed, not what was
intended. An item without evidence is listed as unproven rather than assumed.

## Environment

- `DESKTOP-DBHLRDD`, Windows 10 Pro N 22H2, build `19045.7663` after ESU
  enrollment and servicing. `desktop.tail8768af.ts.net`, `tag:desktop`.
- Support path: KB5120249 (2026-08 cumulative), KB5104021 and KB5120709
  installed 2026-09-06; no updates pending. Every `Client-ESU-Year*` SKU still
  reports `LicenseStatus=0`, which is expected for account-based consumer ESU,
  so delivery is the evidence and licensing state is not.
- Windows reports `LicenseStatus=5` (Notification). It did not block servicing.
  Unresolved and recorded as a limitation.

## Task 2.1 — authenticated native SSH

`sshd` and `ssh-agent` run automatically. Default shell is PowerShell 7.6.5.
Effective configuration, global scope:

    pubkeyauthentication yes
    passwordauthentication no
    kbdinteractiveauthentication no

`PasswordAuthentication no` alone was insufficient: the server still offered
`keyboard-interactive`, and a probe returned
`Permission denied (publickey,keyboard-interactive)`. After disabling it the
same probe returns `Permission denied (publickey).` Both directives sit before
the `Match Group administrators` block, verified by line number.

Authorization file is `C:\ProgramData\ssh\administrators_authorized_keys`,
because the selected account is a local administrator. ACLs, inheritance
removed: `NT AUTHORITY\SYSTEM:(F)`, `BUILTIN\Administrators:(F)`.

## Task 2.2 — tailnet-scoped listener

Only one enabled firewall rule reaches port 22:

    OpenSSH SSH Server (tailnet only)   enabled=Yes  action=Allow  protocol=TCP
      localIP=100.91.92.64, fd7a:115c:a1e0::5a39:5c41
    OpenSSH SSH Server (sshd)           enabled=No   [installer default, disabled]

No enabled inbound rule permits 3389, 445 or 139; the 14 platform rules naming
those ports are all disabled. Inbound reach for RDP and SMB comes from two
`Tailscale-In` rules allowing any protocol to the tailnet addresses, so those
services were already tailnet-only before this change.

Not proven from the desktop: denial of a non-tailnet path. Traffic to the
host's own addresses is not filtered locally, so task 5.1 still requires an
external source with demonstrated LAN reachability.

## Task 2.3 / 2.4 — enrollment and authentication

Host key, wire and disk identical:

    SHA256:ZYFVPT8M8AJI7Vmq63k018DCGIIJKA8atz3xQ6TI4Lw  (ED25519)

Enrolled, each with a revocation label on its own line:

| Label | Type | Fingerprint |
| --- | --- | --- |
| `air` | ED25519 | `SHA256:kgUu4MgKK+87Fax0fwsQoMVfcMNCI+kR5TqlMzSBEeM` |
| `pro-enclave` | ECDSA | `SHA256:yNSLyqA+u4s4Fa8TNIq9U2DpxWgHlwldVFxPZ99FGNE` |
| `pro-yubikey` | ED25519-SK | `SHA256:nBDQ2kAH2q7ylUIJGQz48/YLqr9sWpL3n2qRowd3Z54` |

`pro-enclave` is proven: 24 accepted `publickey` authentications from
`100.88.17.38` between 14:35 and 15:12 on 2026-09-06, no failures recorded, and
the Pro verified the host key fingerprint before accepting it.

Unproven:

- `pro-yubikey`. The server accepts the algorithm: `sshd -T` on 10.0p2 lists
  `sk-ssh-ed25519@openssh.com` and `sk-ecdsa-sha2-nistp256@openssh.com` among
  `pubkeyacceptedalgorithms`. No `ED25519-SK` authentication has occurred, so the
  credential itself is still untested. This is the credential intended to survive
  losing the Pro, so an untested recovery path is the risk, not a formality. Close
  it with a deliberate `IdentitiesOnly=yes -i ~/.ssh/id_ed25519_sk` connection.
- `air`. Enrolled, never exercised.
- Korolev. No key enrolled; the host was offline throughout.
- Exit status 23 passthrough, paths containing spaces, rejection of an
  unapproved key, and a deliberately mismatched client host-key record.
- Saved client endpoints. The Pro authenticates through its global Secretive
  identity with an explicit user and address, not through a declared `desktop`
  entry.

## Task 4.5 — shares

Before: `ADMIN$`, `C` (`C:\`), `C$`, `D` (`D:\`), `D$`, `E$`, `IPC$`. The
explicit `C` and `D` shares granted `DESKTOP-DBHLRDD\User` Full.

`C` and `D` were removed with owner approval. They were redundant: the selected
account is a local administrator, so `C$` and `D$` already grant it identical
reach. Rollback, if ever wanted:

    New-SmbShare -Name 'C' -Path 'C:\'
    New-SmbShare -Name 'D' -Path 'D:\'

After: `ADMIN$`, `C$`, `D$`, `E$`, `IPC$`. No capability changed.

Still required: SFTP round-trip hashes from each source, graphical browsing
from the Macs, authenticated access from Korolev, and denied
unauthorized/read-only writes.

## Task 5.3 — unattended operation

`ForceDaemon: true`, so Tailscale runs before interactive sign-in. Node key
expiry is disabled, matching Korolev and the Pro; it previously expired
2027-03-04, 179 days out. That setting is coordination-server state and cannot
be expressed in this repository.

No volume is encrypted (`FullyDecrypted`, protection off), so no preboot unlock
applies. Fast Startup is enabled, so the reboot gate needs a true restart. The
restart itself is not yet performed with remote access verified before sign-in.

## SSH server version

Upgraded from the Windows capability build to the standalone Win32-OpenSSH
release on 2026-09-06:

| | Before | After |
| --- | --- | --- |
| Version | `OpenSSH_for_Windows_9.5p1`, LibreSSL 3.8.2 | `OpenSSH_for_Windows_10.0p2`, LibreSSL 4.2.0 |
| Binary | `C:\Windows\System32\OpenSSH\sshd.exe` | `C:\Program Files\OpenSSH\sshd.exe` |
| Servicing | Windows Update / ESU | **manual** |

The accepted version is 10.0p2 (release files dated 2025-10-22). All 14
executables and `install-sshd.ps1` carried valid Microsoft Corporation
Authenticode signatures; no MSI product is registered, so this is the GitHub zip
extracted in place. The `OpenSSH.Server` capability was removed first, both
because `install-sshd.ps1` uses `New-Service` and cannot create services that
already exist, and so that Windows Update cannot later reinstate a second `sshd`
over the standalone one.

Verified after the upgrade: services Running/Automatic; `sshd_config` hash
unchanged; `pubkeyauthentication yes`, `passwordauthentication no`,
`kbdinteractiveauthentication no`; `administrators_authorized_keys` ACLs still
Administrators and SYSTEM only; port 22 still scoped to the tailnet addresses;
refusal without a key reports `Permission denied (publickey).` The ED25519 host
key is byte-identical, so no client re-pins.

Side effects recorded: the installer added `RedirectionGuard` image-file
execution options for `sshd.exe` and `ssh-agent.exe`, granted
`NT AUTHORITY\Authenticated Users` read access to `C:\Program Files\OpenSSH\moduli`,
and appended its directory to the machine `PATH`. Until a re-login, `ssh` and
`ssh-keygen` on this host still resolve to the 9.5p1 client in System32 while the
server runs 10.0p2; mixed client and server versions are supported.

## Limitations

- The SSH server is no longer serviced by Windows Update. Removing the
  `OpenSSH.Server` capability moved that burden to manual updates of the
  standalone release, on a machine already on extended support. The accepted
  version above must be revisited deliberately; the repository conventions
  forbid an update wrapper or scheduler, so this belongs in the operating
  procedure.
- The SSH account is a local administrator. Accepted deviation: keys live in
  the administrators file with restricted ACLs, agents are not launched
  elevated, and privileged changes still require console approval.
- One enabled account and no second administrator, so the local interactive
  session is the only recovery path.
- Taildrop cannot reach this host: a tagged node has no user owner. SFTP is the
  transfer mechanism, consistent with the design.
- ZeroTier, TeamViewer and Chrome Remote Desktop remain installed and reach the
  desktop through their own authenticated relays. TeamViewer's rules are
  Public-profile only and every active interface is Private, so those are
  currently inert. The tailnet restriction covers the services this change
  configures, not these products.
- A UAC prompt raised from an unattended context expires after roughly two
  minutes and auto-denies, so privileged steps require an already-elevated
  session.
- Nix gates could not run: Nix is not installed on Windows. `nix fmt`,
  `nix flake check`, `check-darwin-build-plans` and the Darwin system build
  must run on the Pro.
