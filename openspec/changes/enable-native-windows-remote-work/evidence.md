# Acceptance evidence

Measurements from the desktop and Pro are identified below. An item without
evidence remains unproven. The Pro imported desktop commits `c565650`,
`1fba420`, `8e48c00`, and `3ae6d5c` directly over SSH, without a GitHub push.

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

```
pubkeyauthentication yes
passwordauthentication no
kbdinteractiveauthentication no
```

`PasswordAuthentication no` alone was insufficient: the server still offered
`keyboard-interactive`, and a probe returned
`Permission denied (publickey,keyboard-interactive)`. After disabling it the
same probe returns `Permission denied (publickey).` Both directives sit before
the `Match Group administrators` block, verified by line number.

Authorization file is `C:\ProgramData\ssh\administrators_authorized_keys`,
because the selected account is a local administrator. ACLs, inheritance
removed: `NT AUTHORITY\SYSTEM:(F)`, `BUILTIN\Administrators:(F)`.

## Task 2.2 — tailnet-scoped listener

One enabled rule explicitly names TCP port 22. The Tailscale address rules
below also permit SSH:

```
OpenSSH SSH Server (tailnet only)   enabled=Yes  action=Allow  protocol=TCP
  localIP=100.91.92.64, fd7a:115c:a1e0::5a39:5c41
OpenSSH SSH Server (sshd)           enabled=No   [installer default, disabled]
```

The 14 platform rules explicitly naming ports 3389, 445 or 139 are disabled.
Inbound reach for RDP and SMB comes from two
`Tailscale-In` rules allowing any protocol to the tailnet addresses, so those
services were already tailnet-only before this change.

The Pro later compared both paths from the desktop's WSL distribution, whose
network stack is separate from the Windows host and is not a tailnet node.
Each check opened a TCP connection and recorded the exit status, so a refusal
is a filtering result rather than an unmeasured route failure:

| Port | `10.0.1.2` (Ethernet) | `192.168.96.1` (host from WSL) | `100.91.92.64` (tailnet) |
| ---- | --------------------- | ------------------------------ | ------------------------ |
| 22   | timed out             | timed out                      | connected                |
| 3389 | timed out             | timed out                      | connected                |
| 445  | timed out             | timed out                      | connected                |

The tailnet address answers on all three ports from the same source that both
non-tailnet addresses refuse, which demonstrates reachability and therefore
enforcement rather than an absent route.

Still open for task 5.1: this source shares the physical machine, and the
desktop's Ethernet interface carries no global IPv6 address, only a
link-local one, so IPv6 coverage on a non-tailnet path is untested. A source on
the desktop's own Ethernet segment remains the stronger check; the Pro, the
Air, and Korolev are all on `192.168.0.0/24` and route `10.0.1.2` through a
gateway.

## Task 5.2 — different physical network

The owner moved the Pro to a separate network: it holds `172.20.10.4` behind
gateway `172.20.10.1`, and Tailscale reports no direct path to the desktop, so
traffic relays through DERP `fra`. From there the saved `desktop-batch` name
returned `desktop-dbhlrdd\user` with exit status `23`, the interactive
`desktop` name authenticated, and a 65,536-byte SFTP round trip through a
filename with spaces matched
`a75f7305e4514fa623f4fc21c4344a8b8ee4d9877528dc58bbc36232efd18e87` at both
ends. The desktop logged the authentication from the Pro's tailnet address
`100.88.17.38`, not from any address on this network, and the desktop's
`10.0.1.2` LAN address stayed unreachable from it. No router port forwarding
was introduced.

Not covered here: graphical RDP access from this network, which task 4.3 owns.

## Task 2.3 / 2.4 — enrollment and authentication

Host key, wire and disk identical:

```
SHA256:ZYFVPT8M8AJI7Vmq63k018DCGIIJKA8atz3xQ6TI4Lw  (ED25519)
```

Enrolled, each with a revocation label on its own line:

| Label         | Type       | Fingerprint                                          |
| ------------- | ---------- | ---------------------------------------------------- |
| `air`         | ED25519    | `SHA256:kgUu4MgKK+87Fax0fwsQoMVfcMNCI+kR5TqlMzSBEeM` |
| `pro-enclave` | ECDSA      | `SHA256:yNSLyqA+u4s4Fa8TNIq9U2DpxWgHlwldVFxPZ99FGNE` |
| `pro-yubikey` | ED25519-SK | `SHA256:nBDQ2kAH2q7ylUIJGQz48/YLqr9sWpL3n2qRowd3Z54` |
| `korolev`     | ED25519    | `SHA256:3BjfAMmCOeoqV50VRCIBzFIGAuNG4LQ3MCcYUAyc248` |

`pro-enclave` is proven: 24 accepted `publickey` authentications from
`100.88.17.38` between 14:35 and 15:12 on 2026-09-06, no failures recorded, and
the Pro verified the host key fingerprint before accepting it.

`pro-yubikey` authenticated against the upgraded service with `IdentityAgent=none`,
`IdentitiesOnly=yes`, and the explicit `id_ed25519_sk` identity. Windows logged
`Accepted publickey ... ED25519-SK` with the enrolled fingerprint at
15:35:16 +02:00 on 2026-09-06. No algorithm override was needed.

The Air used its existing enrolled ED25519 key, without exporting private-key
material. Its new `~/.ssh/config` scopes `desktop` and `desktop-batch` to that
identity and the dedicated pin file `~/.ssh/known_hosts_desktop`. The saved batch
endpoint returned native exit status `23` and passed a 65,536-byte SFTP round
trip through a filename with spaces. SHA-256:
`dd8430af20d29b52a8b34d1eacef6639bf51487b308d27de37d6fd6e7652e573`.
All temporary transfer files were removed. No financial data was copied.

Korolev is reachable again after the owner repaired its Tailscale service; it
answers `tailscale ping` directly at `192.168.0.236` and reports
`Online: true`. Its own no-inbound boundary still holds, verified from the Pro:
`ssh korolev` returned status `255` with a connection timeout, and TCP port 22
refused a bare connection.

Korolev fetched revision `f576832` over SSH and activated it with
`nixos-rebuild switch`. Its report records formatting, strict OpenSpec
validation, 25 Linux flake checks, no failed units, retained previous
generation, and the existing Mac transport still returning status `23`. Its
installed endpoints use the declared pin and its preserved user key at
`/home/user/.ssh/id_ed25519`, which is separate from the root-owned builder
credential. Its first attempt reached the desktop and passed host verification
but was refused with `Permission denied (publickey)`, because the key was not
yet authorized.

The Pro then enrolled the `korolev` key from the desktop. The candidate parsed
and matched its reported fingerprint before it reached the authorization file;
the three existing lines were unchanged, the file grew from three entries to
four, and its ACLs still grant only SYSTEM and Administrators. `sshd -t`
accepts the configuration and existing Pro access still authenticates. No
private key left Korolev.

Korolev then ran its own checks and reported them to the Pro. These results are
peer-supplied, not measured on the Pro, because Korolev's no-inbound boundary
means neither the Pro nor the desktop can drive it. Its report records both
aliases authenticating as `desktop-dbhlrdd\user` with exit status `23`, the
`C:\Program Files\OpenSSH` path preserved with status `23`, an unapproved key
refused with `255` and `Permission denied (publickey)`, a mismatched host pin
refused with `255` after the client printed the desktop's real fingerprint, and
a 65,818-byte SFTP round trip through paths containing spaces whose Linux
source, `Get-FileHash` result on Windows, and downloaded copy all matched
`643877f72eaf860f07a998ce975ce6056c14421df13cc1d3111430fb5759eda4`. Production
commands had empty standard error, and it reports removing every temporary
file, key and pin.

The Pro corroborated the parts observable from the desktop rather than
restating the report: `OpenSSH/Operational` records seven
`Accepted publickey ... ED25519 SHA256:3BjfAMmCOeoqV50VRCIBzFIGAuNG4LQ3MCcYUAyc248`
entries from `100.117.31.61` between 17:07:40 and 17:08:41 +02:00 with no
failure entries, and no `korolev*` leftovers remain in the Windows temporary
directory. The Pro did not repeat Korolev's checks.

The Air's rejection checks then ran from the Air itself. A first attempt was
invalid and is recorded rather than discarded: with the Air's own
`~/.ssh/config` in effect, `ssh -i <disposable key>` still offered the enrolled
identity and authenticated, so the check proved nothing. Repeated with
`-F /dev/null` and an explicit identity, the disposable key was refused with
status `255` and `Permission denied (publickey)`, a mismatched pin was refused
with `255` and `Host key verification failed`, and the enrolled Air key returned
status `23` in the same run.

### Selective revocation

Proven with a disposable authorization, so no real source lost access. A
throwaway ED25519 key was enrolled as a fifth labelled line,
`SHA256:bBk3/++KTijWrOekiBTDR/BOswunTtQrk0IE7EVlpbg revocation-test`, and
authenticated with status `23`. Removing only that labelled line returned the
file to four entries and to its exact pre-test SHA-256,
`F5BCB19B72841AB9C85C8311789971F63962354F77909DF9C7F496F184158659`, with ACLs
still granting only SYSTEM and Administrators. The revoked key was then refused
with status `255` and `Permission denied (publickey)`, while `pro-enclave`
returned `23` and the Air returned `23` through its own endpoint. The
disposable key was removed from the Pro. Revocation therefore removes exactly
one source, which is the mechanism the Air's offboarding depends on.

[Issue #17](https://github.com/glockyco/nix-config/issues/17) now carries that
action: remove the labelled `air` line from the desktop's authorization file and
confirm the refusal, and remove the Air's own desktop entries and pin. The Air
keeps its access until the owner retires the machine.

Still unproven elsewhere:

- System-wide activation of the Pro client declaration. The generated
  configuration has passed live checks with `ssh -F`.

## Task 3.1 / 3.2 — native agent

Accepted versions, installed from the Pro over SSH:

| Component       | Version                                    | Source and check                                                                                                                                                               |
| --------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| OMP             | 18.1.12                                    | Official `install.ps1` at that tag with `-Binary`; `omp-windows-x64.exe` SHA-256 `1195236da00e218c8d5eb56144a481f0622d4c7123f8a563c7128ae4e4a341f0` matched the release digest |
| Personal plugin | `4707024f3c20031a3650dc98db74940f0ae9a648` | Source checkout at `D:\Projects\omp-agent-setup`, the revision this repository pins; no Nix-store payload copied                                                               |
| psmux           | 3.3.8                                      | Release archive SHA-256 `1ad127ba937194a890b933a73d9b023e297bd73dc742abd841bf159984c2effe` matched the release digest                                                          |
| ripgrep         | 15.2.0                                     | `winget install BurntSushi.ripgrep.MSVC`                                                                                                                                       |
| OpenSpec        | 1.12.0                                     | Already present, matching the version `llm-agents` packages                                                                                                                    |

The rejected Bun-global distribution is gone: `bun remove -g` unregistered the
package, and the leftover `omp.exe` and `omp.bunx` shims were deleted, but only
after the owner stopped an OMP process that had been holding `omp.exe` open.
That process belonged to the owner's own session, so it was left alone until
then. `omp` in a fresh SSH session now resolves to
`C:\Users\User\AppData\Local\omp\omp.exe` alone and reports `omp/18.1.12`. The
installer selected Git Bash at `C:\Program Files\Git\bin\bash.exe` as the shell
path, not the WSL `bash.exe` on `PATH`, which the design forbids.

Smoke checks ran with `--plugin-dir` and `--extension` pointed at the source
checkout, in a disposable Windows repository:

- The agent reported the loaded plugin path `D:\Projects\omp-agent-setup\plugin`
  and quoted the commit-policy skill, so extension and skills load from source.
- `personal_commit` with `action=preview` printed the formatted subject and body
  and left the repository unchanged.
- `openspec list` in `D:\Projects\nix-config` reported all six changes with task
  counts; the repository stayed clean afterwards.
- The research helper `fetch_pdf.py` ran under Python 3.13.3 and printed its
  interface.
- A provider credential was already present, so a non-interactive run completed
  without transferring any credential from the Pro.

Recorded rather than hidden: during the commit-preview check the agent
misread a fragment as an instruction, created a commit in the disposable
repository and undid it with `git reset --soft`. The preview itself changed
nothing, but the disposable repository was not pristine at that moment.

No language server the plugin selects exists on Windows: `markdown-oxide`,
`Microsoft.CodeAnalysis.LanguageServer`, the Svelte server, `marksman`, `nixd`
and `pyright` are all absent, because Nix packages them for the Macs and
Korolev and cannot on Windows. The owner then scoped diagnostics out of the
native Windows agent. No Windows language-server artifact is selected or
pinned, and none was faked.

This is not a claim that the machine will never have language servers. The
planned NixOS-WSL host will provide them through Nix, inside WSL, for an agent
running there. That does not satisfy this check and does not reinstate it,
because the native agent must not resolve tooling through a WSL launcher.

## Task 3.3 — persistent terminal

psmux 3.3.8 created, listed and killed a named session over SSH, with the
working directory set to a repository. Its two listening endpoints are both on
`127.0.0.1`, so its control interface stays local to Windows as the design
requires. Through `capture-pane`, the session rendered
`Grüße — ✅ 日本語 ← →` correctly, `resize-window` reported `100x24`, and
`paste-buffer` delivered a buffer that the shell executed.

Interrupt handling is unverified and now out of scope. Injected `send-keys C-c`
and the literal control byte `send-keys -H 03` both failed to stop a running
loop in the pane; only `kill-session` stopped it. That is no verdict on psmux,
because an injected key is not a terminal interrupt, and no attached client
could be created here: macOS `script` refuses a PTY when its input is a socket,
and the harness's supervised-process launcher fails with `ENOENT`. The owner
then dropped this check.

Also recorded: two of my own errors while driving the pane. An unclosed quote
in a `send-keys` argument left the pane in a PowerShell continuation prompt
that silently swallowed later input, and a malformed loop kept running until I
noticed. Both were cleared by recreating the session. All test sessions, the
ticker script, its log and the disposable repository were removed, and no OMP
process remains.

Live persistence is out of scope: this desktop is driven for agentic work
through non-interactive `ssh <command>` invocations, which the transport checks
above already cover. Attached multiplexer sessions are a human workflow the
owner does not use here, so the detachment and abrupt-termination trials were
not run and psmux's job-breakaway behaviour on this machine stays unknown.
Nothing in the accepted contract depends on it. psmux remains installed only as
a convenience and can be removed without affecting any accepted capability.

## Task 4.5 — shares

Before: `ADMIN$`, `C` (`C:\`), `C$`, `D` (`D:\`), `D$`, `E$`, `IPC$`. The
explicit `C` and `D` shares granted `DESKTOP-DBHLRDD\User` Full.

`C` and `D` were removed with owner approval. They were redundant: the selected
account is a local administrator, so `C$` and `D$` already grant it identical
reach. Rollback, if ever wanted:

```
New-SmbShare -Name 'C' -Path 'C:\' -FullAccess 'DESKTOP-DBHLRDD\User'
New-SmbShare -Name 'D' -Path 'D:\' -FullAccess 'DESKTOP-DBHLRDD\User'
```

After: `ADMIN$`, `C$`, `D$`, `E$`, `IPC$`, confirmed from the Pro with
`Get-SmbShare`. The administrator retains volume access through administrative
shares; the removed share names no longer resolve.

Still required: SFTP round-trip hashes from each source, graphical browsing
from the Macs, authenticated access from Korolev, and denied
unauthorized/read-only writes.

## Task 5.3 — unattended operation

`ForceDaemon: true`, so Tailscale runs before interactive sign-in. Node key
expiry is disabled, matching Korolev and the Pro; it previously expired
2027-03-04, 179 days out. That setting is coordination-server state and cannot
be expressed in this repository. The Pro independently observed
`(tailscale status --json | ConvertFrom-Json).Self.KeyExpiry` as `null`, with
`Online: true` and `tag:desktop`.

No volume is encrypted (`FullyDecrypted`, protection off), so no preboot unlock
applies.

The owner restarted the desktop on 2026-09-06. It was a genuine full boot, not a
Fast Startup resume: `Microsoft-Windows-Kernel-Boot` event 27 reported
`boot type 0x0` at 17:45:31. Afterwards `sshd`, `ssh-agent` and `Tailscale` were
all `StartMode=Auto` and `Running`, the node reported `Online: true` with
`KeyExpiry: null`, and the Pro's `desktop-batch` endpoint returned exit status
`23` about one minute after boot, with the newly registered standalone service
binaries. Remote access therefore returns automatically after a restart, with no
operator action.

Access before interactive sign-in was not measured, and does not apply. An
interactive logon for `User` appears at 17:45:47, sixteen seconds after boot and
before the first successful probe: with a blank password and Automatic Restart
Sign-On enabled, the machine signs itself in. The owner confirms this is how the
desktop always starts, so a signed-out state is not a condition this desktop
reaches, and testing it would prove nothing about real operation.

## SSH server version

Upgraded from the Windows capability build to the standalone Win32-OpenSSH
release on 2026-09-06:

|           | Before                                      | After                                        |
| --------- | ------------------------------------------- | -------------------------------------------- |
| Version   | `OpenSSH_for_Windows_9.5p1`, LibreSSL 3.8.2 | `OpenSSH_for_Windows_10.0p2`, LibreSSL 4.2.0 |
| Binary    | `C:\Windows\System32\OpenSSH\sshd.exe`      | `C:\Program Files\OpenSSH\sshd.exe`          |
| Servicing | Windows Update / ESU                        | **manual**                                   |

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

- The standalone OpenSSH server requires manual updates. Windows Update no
  longer services it after removal of the `OpenSSH.Server` capability.
  Keep this operation in the existing procedure, not an update wrapper.

- The SSH account has enabled administrator privileges. Agents inherit this
  token without an additional elevation prompt. Keys remain in the restricted
  administrators file. Console approval for privileged service changes is
  operator policy, not token isolation.

- One enabled account and no second administrator, so the local interactive
  session is the only recovery path.

- The account password is blank and Automatic Restart Sign-On is enabled, so the
  desktop always boots into a signed-in session. Anyone with physical console
  access therefore reaches that session without a credential. This is the
  owner's accepted arrangement; remote access remains public-key only. Setting a
  password for RDP would end automatic sign-on unless the password were stored
  in the registry in clear text, which was rejected.

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

- Nix is not installed on Windows. The Pro ran the native gates recorded
  below; their dependency diagnostics remain separate from Windows acceptance.

## Pro acceptance evidence: 2026-09-06

The owner reports desktop inventory and version selection complete, with evidence retained on Windows. The reported server configuration uses PowerShell 7, public-key-only authentication, SFTP, and a tailnet-only firewall rule with the broad rule disabled. Three labelled public keys are enrolled. Unattended Tailscale is applied; reboot acceptance remains outstanding.

The owner confirmed the desktop's measured ED25519 fingerprint: `SHA256:ZYFVPT8M8AJI7Vmq63k018DCGIIJKA8atz3xQ6TI4Lw`. The Pro pinned the matching public key for `desktop` and `desktop.tail8768af.ts.net` in its mutable `~/.ssh/known_hosts`. The Pro subsequently integrated the desktop client declaration from `0449822` and added an immutable host-key pin through `UserKnownHostsFile`. Both aliases enforce strict host checking and reject password fallback. The generated configuration was exercised with `ssh -F`; it has not been activated system-wide.

Pro checks used `StrictHostKeyChecking=yes`, `BatchMode=yes`, disabled connection multiplexing, and an eight-second connection timeout:

- Authentication returned `desktop-dbhlrdd\user` and PowerShell `7.6.5`.
- Direct remote `exit 23` returned SSH status `23`. A nested PowerShell invocation without explicit exit forwarding returned `1`; use the direct command for this acceptance check.
- A temporary mismatched host pin failed with status `255` and host-key verification failure.
- A temporary unapproved client key, with the agent disabled and `IdentitiesOnly=yes`, failed with status `255` and `Permission denied (publickey)`.
- A 4,114-byte binary SFTP payload round-tripped through a temporary Windows filename containing spaces. SHA-256 matched: `e7da80720257726b2bf9cf4f4a78307f3a50312b899bfef23a9846ef142eba15`. Windows absolute SFTP paths require `/C:/...`; `C:/...` was treated as relative and failed before creating a file. Remote and local smoke files and temporary keys were removed.
- Read-only metadata confirmed `D:\Projects\ynab` exists, already contains `.git`, and includes `statements` and `.venv`. No project content was copied or executed.

**Accepted administrator access:** the live SSH token reports `WindowsPrincipal.IsInRole(Administrator) = true`. The owner confirmed this account choice and the desktop branch revises tasks 1.1 and 2.1 accordingly. SSH commands have enabled administrator privileges without an additional elevation prompt. Explicit approval for privileged service changes remains an operator policy, not a technical restriction of this SSH account.

The generated `desktop` and `desktop-batch` aliases both authenticated as the selected account. The batch alias returned direct exit status `23`, rejected a mismatched pin and an unapproved client key with status `255`, and passed a second 4,114-byte SFTP round trip through a path with spaces. Its SHA-256 was `79c2b3b3bdb2113c14ce49b43beaf962376b68d4e9c6bcd32ef95e67893f536f`. All temporary files and keys were removed. Server `sshd -T` includes `sk-ssh-ed25519@openssh.com`; the YubiKey was subsequently authenticated against the upgraded service, as recorded above.

**Post-quantum upgrade:** the previous Windows OpenSSH 9.5 server offered no hybrid key exchange. Its bundled `ssh -Q kex` listed none, and `sshd_config` had no explicit `KexAlgorithms` override. The [Win32-OpenSSH 10.0.0.0p2 preview](https://github.com/PowerShell/Win32-OpenSSH/releases/tag/10.0.0.0p2-Preview) adds ML-KEM and sntrup support but is labelled non-production ready. The warning concerns key exchange, not the verified ED25519 host identity. The owner approved a preview test and then approved service replacement while available at the Windows console. No warning suppression was applied.

The Pro tested the preview through its supported `sshd -i` single-connection mode over the existing authenticated SSH transport. This test created no listener, service, or firewall rule. The inner session negotiated `mlkem768x25519-sha256` by default and retained the pinned ED25519 identity. Explicit ML-KEM and sntrup sessions both returned status `23`. A mismatched host pin and an unapproved client key each failed with status `255`. Preview SFTP round-tripped a binary file through a filename with spaces; SHA-256 was `d4e6ea0c0433cd115ddd43caea1b6bab2846da14167f734f3d7ce3c45a8b20db`. Temporary transfer files and test keys were removed. The outer 9.5 transport still emitted the expected warning; this test did not prove a production service upgrade.

The `OpenSSH-Win64.zip` SHA-256 matched GitHub's release digest, `23f50f3458c4c5d0b12217c6a5ddfde0137210a30fa870e98b29827f7b43aba5`. All 15 binary files and five PowerShell scripts/modules had valid Microsoft Authenticode signatures. The signed MSI also matched its release digest, but its `WixFirewallException` table creates an unrestricted inbound TCP/22 rule. The supported ZIP installer was selected instead; its source has no firewall mutation.

The console worker completed installation at `C:\Program Files\OpenSSH` after removing the Windows Server capability. The earlier instruction to point `sshd` back to the in-box binary was withdrawn because capability removal can remove that binary. Protected recovery data at `C:\ProgramData\OpenSSH-recovery-3f038d797eba` contains SSH configuration and keys with ACLs, registry exports, service and firewall measurements, and the verified accepted ZIP as `OpenSSH-Win64-10.0.0.0p2.zip`. No private key left Windows. The [manual recovery procedure](../../../docs/operations/dependency-updates.md#desktop-openssh-maintenance) uses the retained package and supported service removal/installation, not an executable fallback.

The Pro verified the active service through its normal pinned endpoint: `mlkem768x25519-sha256`, unchanged ED25519 identity, native status `23`, and no weak-key-exchange warning. `Set-Location` to `C:\Program Files\OpenSSH` preserved the spaced path and status `23`. An unapproved key and mismatched host pin each failed with status `255`. Production SFTP round-tripped 65,566 bytes with the isolated test's SHA-256 and empty stderr. Temporary transfer files and test keys were removed.

Pro and Air transport checks do not complete the multi-source tasks. Korolev acceptance, installed Pro client activation, non-tailnet rejection coverage, graphical/share acceptance, and reboot verification remain outstanding. The Pro and Air route the desktop's `10.0.1.2` Ethernet address through their `192.168.0.1` default gateway; neither supplies demonstrated desktop-LAN reachability. No route failure was accepted as firewall proof. Windows service installation was performed at the console.

### Native integration gates

The Pro completed the following checks for the integrated desktop client declaration:

- `nix fmt -- --fail-on-change`: passed after applying nixfmt's layout to the host-pin expression.
- `openspec validate --all --strict`: 13 passed, 0 failed.
- `nix build --no-link --print-build-logs .#checks.aarch64-darwin.airBatchConfiguration`: passed. The check exercises OpenSSH's rendered policy for both endpoint pairs and the desktop's immutable pin.
- `nix flake check --print-build-logs`: completed successfully on Darwin; Linux checks were omitted by the native-system selection.
- `nix run .#check-darwin-build-plans`: passed; 34 outputs, none reaching a forbidden source build.
- `nix build .#darwinConfigurations.macbook-pro.system`: completed successfully. No activation or push occurred.

The successful build was not warning-free. Nix emitted ignored evaluation-cache contention and an `options.json` store-context warning. The Catppuccin FZF and Ghostty derivations logged segmentation faults in the Nixpkgs `audit-tmpdir.sh` pipeline but continued successfully. These dependency-build diagnostics were not fixed or suppressed by the client commit `a81924c`.

### Temporary-path audit defects (upstream)

Reproduced with the original derivations and no environment changes:
`nix build --no-link --rebuild --print-build-logs` against the pinned
`catppuccin-fzf` and `catppuccin-ghostty` derivations. The classifier subshell
in Nixpkgs `pkgs/build-support/setup-hooks/audit-tmpdir.sh` reported
`Segmentation fault: 11`, in one observed run for Ghostty only. Both builds
still exited successfully, because the audit waits for its two handler
subshells and never collects the classifier's status. Two distinct defects:
an intermittent Darwin crash, and a check that reports success while part of
the output went unclassified. No forbidden temporary-path reference was found
in any theme output.

The crash cause is unproven. Exhausted without a stack: no crash report or core
file exists for the sandboxed builders; cross-user attach is refused; and
address-sanitizer builds of the exact pinned Bash, with and without native
language support, completed the exact derivation without a sanitizer report.
Behavioural evidence favours locale handling in the forked classifier over the
`read` reallocation path: `isELF` and `isScript` set `LANG=C` per file, the
pinned Bash links CoreFoundation directly, and a variant holding `LC_ALL=C`
across the classifier passed four runs where the original crashed in one of
three. That is a correlation, not a proven cause.

No local fix was applied. The hook is a standard-environment default setup
hook with no override interface, so replacing it means patching the Nixpkgs
source; a dry run of that approach rebuilds the bootstrap toolchain from source
and loses every cached path, which the build-plan guard rejects. Disabling the
audit, suppressing its output, or vendoring a patched standard environment were
also rejected. This belongs upstream. Themes and their applications work; the
defect is confined to the build-time check.

### Evaluation cache

The earlier native gates ran concurrently and contended on the same `eval-cache-v6` SQLite file. The installed evaluator is Determinate Nix `3.21.9` / Nix `2.34.8`. Nix's [evaluation-cache implementation](https://github.com/NixOS/nix/blob/2.34.8/src/libexpr/eval-cache.cc) keeps a database transaction open and marks caching failed after a SQLite write error; successful evaluation does not make that diagnostic harmless evidence of a clean gate. The README now requires sequential gate execution. Verification must retain the existing cache and report whether the diagnostic recurs; it must not disable caching or remove the database.
