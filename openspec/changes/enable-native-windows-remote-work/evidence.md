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

Graphical access was exercised from this same off-network position. The
desktop's `TerminalServices-LocalSessionManager` log records reconnect (25) and
disconnect (24) events from the Pro's tailnet address `100.88.17.38` at 18:11
and 18:20, while the Pro held `172.20.10.4` behind a different gateway. That
also corroborates the disconnect and reconnect cycle in task 4.3 independently
of the owner's report. No router port forwarding was introduced.

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

The Pro's client declaration is now activated system-wide. `darwin-rebuild switch` completed, `~/.ssh/config` is a symlink into the Home Manager
generation and contains both desktop endpoints, and `ssh desktop-batch` without
`-F` returned `desktop-dbhlrdd\user` with exit status `23`.
`verify-personal-omp` reports OMP 18.1.12, a plugin path under `/nix/store`, and
`omp: current`.

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

## Task 3.3 — terminal investigation, then removal

While installed, psmux 3.3.8 created, listed and killed a named session over
SSH, with the working directory set to a repository. Its two listening endpoints are both on
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

psmux was then removed: server stopped, `C:\Users\User\AppData\Local\Programs\psmux`
deleted, its user `PATH` entry removed, and its `~/.psmux` state directory
deleted. `psmux` no longer resolves, and `omp` still resolves to the standalone
install at 18.1.12. The desktop carries no dependency, and no manual update
burden, for a capability nobody uses. The version and digest above are retained
only so a later attempt starts from a known artifact.

## Task 4.2 — graphical access

Measured from the desktop before any client connected. RDP is enabled
(`fDenyTSConnections=0`), the service runs, Network Level Authentication is
required (`UserAuthentication=1`) and the security layer is TLS
(`SecurityLayer=2`). `Remote Desktop Users` is empty; access comes from the
account's administrator membership. No RDP setting was changed.

The listener binds TCP and UDP 3389 on all interfaces, and both
`Remote Desktop - User Mode` rules are disabled. Reachability therefore comes
only from the two `Tailscale-In` rules that allow any protocol to the tailnet
addresses, which matches the measured refusal on `10.0.1.2` and acceptance on
`100.91.92.64`. The scope is effective, but it rests on an allow-any rule for
those addresses rather than an RDP-specific rule; record that rather than
claiming a dedicated RDP restriction.

The server certificate is the auto-generated self-signed one:
`CN=DESKTOP-DBHLRDD`, SHA-1 `6F7E0751FF7B3513320941130F996B8161BA086F`,
SHA-256 `b7:ca:a3:3f:8b:d6:c9:8f:a6:aa:44:c6:2a:a3:e2:73:b1:9e:c5:d3:99:53:03:30:d2:3f:d4:c7:c2:47:50:7b`,
valid to 2026-12-12. No certificate is selected in the registry, so Windows
regenerates it around expiry and the thumbprint changes then; a change at any
other time warrants investigation. The operator compares this fingerprint in
the client on first connect.

The Pro now has a declared RDP client: the `windows-app` cask, activated with
`darwin-rebuild switch`, installing Windows App 11.4.0. No connection was saved
and no credential was stored by this change. Connecting, verifying the
fingerprint in the client, and the disconnect and reconnect check in task 4.3
remain operator steps, because they need the account password and a visible
screen.

## Task 4.3 — graphical session lifetime

The owner connected from the Pro with Windows App and reports the server
certificate was correct and the machine kept running across the connection.
Credentials are set to "ask when required", so the client stores no password,
and "connect to an admin session" stays off. The certificate comparison is the
owner's observation; whether the client displayed a full fingerprint or only
the host name is not recorded here.

The Pro then measured the session state. Session 1, the one signed in at 17:45,
is retained in `Disc` state after the client disconnected, and the effective
WinStation limits are `MaxDisconnectionTime=0`, `MaxIdleTime=0` and
`MaxConnectionTime=0`, so a disconnected session is never timed out or reset.
UAC remains enabled (`EnableLUA=1`, consent prompt `5`) and no screen-lock or
elevation policy was weakened.

`fSingleSessionPerUser=1`, so RDP does not create a separate workspace: it takes
over the account's existing console session. Because the desktop boots into a
signed-in session, an RDP client reattaches to that session rather than starting
a private one. Record that as the machine's behaviour; it is not a defect, but
console and remote graphical access are not independent.

The owner confirms work in the session survived the disconnect and reconnect
cycle. That part is the owner's observation; the Pro measured the retained
session and the zero timeouts that explain it.

Graphical access from the Air and Korolev is out of scope by owner decision, so
neither has an RDP client and none is declared. Both keep SSH and file
transfer, which are verified above.

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

SMB is not an accepted capability of this change. The owner keeps SFTP as the
transfer mechanism, and its round-trip hashes are verified from the Pro, the Air
and Korolev above, so SMB browsing, authenticated SMB access and
write-restriction checks were dropped rather than performed. File sharing was
left as measured: the administrative shares remain, no share was added, and no
guest access was enabled. The service stays reachable only through the tailnet
addresses, as the port comparison above shows.

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
interactive logon for `User` appears at 17:45:47, sixteen seconds after boot,
before the first successful probe, with no lock screen present. The owner
confirms the desktop always starts into a signed-in session, so a signed-out
state is not a condition it reaches and testing it would prove nothing about
real operation. The mechanism is unexplained: `AutoAdminLogon` is unset and the
account has a password, so this is recorded as observed behaviour rather than a
diagnosed one.

## Task 5.5 — fleet isolation and the Mac builder

Korolev's agent ran these checks and reported them; they are peer-supplied,
because Korolev accepts no inbound connection. Raw commands, statuses and output
are in its handoff file.

**`tailnet-builder-check` exited 1.** Its unique Darwin derivation
`39z1p2xd5zryidksnbf33lgnaz495h7f-tailnet-builder-probe-1788714376-506731-224279-29686.drv`
built on `ssh-ng://glockyco@macbook-pro`, the log shows the remote build and the
copy back, and the probe reported architecture `arm64` and builder
`macbook-pro`. The aggregate check then failed on its final step: `tailscale ping 100.88.17.38` timed out with no reply. The live remote build therefore
passes and the aggregate check fails; the failure is recorded as a failure and
the check is not marked green.

The Pro corroborated the build half independently: the probe's output path
exists in this machine's store with a local build log, so the derivation really
built here rather than on Korolev.

Supporting results from Korolev: `nix store info --store ssh-ng://macbook-pro`
exited 0 reporting `Version 2.34.8, Trusted 1`; `ssh macbook-pro 'exit 23'`
returned `23`; generation 18 is `f576832` with generations 1 to 17 retained. Its
no-inbound boundary holds, and its journal shows the matching drop for the Pro's
probe, `100.88.17.38:54855 > 100.117.31.61:22 no rules matched`, which pairs
with the timeout the Pro measured. No `connect-fleet-over-tailnet` gate was
touched and nothing was restarted or reconfigured.

**First failure, unstable network.** The ping produced no reply at all. Korolev's
journal reported coordination-server long-poll timeouts and intermittent
Frankfurt relay failures. The Pro was on a phone hotspot at `172.20.10.4` with
no direct path, yet reached Korolev through DERP `fra` afterwards with
`BackendState: Running`, no health warnings, and a nearest DERP of Nuremberg.
That measurement stands as recorded and predates the owner stabilising
Korolev's network.

**Second failure, stable network, different cause.** Korolev repeated the check
after its network was stable. It again built a unique Darwin derivation,
`29kcw4nh550zrfj4px090ha4hajkazhv-tailnet-builder-probe-1788714631-558417-225918-14236.drv`,
on `ssh-ng://glockyco@macbook-pro`, returning `arm64` and `macbook-pro`. This
time the ping received a pong through DERP `fra` in 62 ms, then printed
`direct connection not established` and exited 1. Separately,
`tailscale ping --c 1 --until-direct=false macbook-pro` returned a relayed pong
and exit 0.

The Pro reproduced the same behaviour in the other direction: against Korolev, a
relayed pong exits 1 with default flags and exits 0 with `--until-direct=false`.
`tailscale ping --help` confirms `--until-direct` defaults true.

The second failure is therefore a checker-contract defect rather than
unreachability. `packages/tailnet-builder-check.nix` called
`tailscale ping --c 1`, which retries until a direct path exists and fails when
only a relayed one does. No requirement asks for a direct path, and a relayed
route is the expected one for a source behind a restrictive network; the Pro
itself is relay-only on a hotspot. The check now passes `--until-direct=false`,
requiring a reply rather than a direct path.

Verifying the fixed script needs Korolev: it is a Linux package and no Linux
builder is reachable from the Pro, so the Pro confirmed only that it evaluates
and that the built derivation carries the flag. Whether the first failure would
also disappear now is untested, and the underlying relay instability is not
attributed to this change. The `connect-fleet-over-tailnet` gates stay
unchanged.

## Task 6.2 — cleanup and exclusions

Spike-owned state was removed after verification: the preview staging directory
`C:\ProgramData\omp-openssh-preview-3f038d797eba` is gone, and the accepted
signed package remains in the recovery directory with its release digest
`23f50f3458c4c5d0b12217c6a5ddfde0137210a30fa870e98b29827f7b43aba5`. No psmux,
smoke-repository, transfer or revocation-test artefacts remain in the Windows
temporary directory. The service binary and running service are intact and
access still returns exit status `23`. The recovery directory and the plugin
source checkout are retained deliberately.

Exclusions hold. No hosted collab, session broker, agent service or scheduled
task was created; the only scheduled tasks and services matching a search are
pre-existing platform and vendor entries. No agent process runs. No NixOS-WSL
host is declared under this change, and no employer Windows configuration was
touched: `modules/windows/` is unchanged. ZeroTier, TeamViewer and Chrome Remote
Desktop remain installed and unmodified, as recorded in the limitations.

## Task 6.1 — operating guidance

The [dependency runbook](../../../docs/operations/dependency-updates.md#desktop-openssh-maintenance)
carries the desktop procedure in one place: manual server updates with digest
and signature checks, the supported remove and install sequence, recovery from
the retained package, the agent stack's version ownership, per-source key
revocation with its ACL constraint, the global-section rule for `sshd_config`
edits, session lifetime for both agent and graphical access, and the
coordination-server key-expiry check with its command. No second inventory or
architecture manual was created.

The README entry gained the graphical-access paragraph and a note that the
tailnet diagram shows topology only: its service cards predate this work and no
longer describe current state, so the change evidence is authoritative. The
diagram image itself was not regenerated.

## Task 5.4 — repeat checks and local recovery

Repeating the setup state checks found no duplication: one enabled inbound rule
for port 22, four authorization lines that are all unique, one `sshd` and one
`ssh-agent` service pointing at `C:\Program Files\OpenSSH`, and the share list
unchanged at `ADMIN$`, `C$`, `D$`, `E$`, `IPC$`.

Recovery was exercised on a change-owned setting. The backup copy of
`sshd_config` matched the live file exactly
(`149482896CFC790654B7F28DEC7DD6BCE75372FED8290AF31552D91B5295B0FD`). The Pro
appended `LogLevel VERBOSE`, validated with `sshd -t`, restarted the service and
kept working access; it then restored the file from the recovery copy,
validated, restarted, and confirmed the hash returned to that baseline. After
restoring, the effective configuration again reports `pubkeyauthentication yes`,
`passwordauthentication no`, `kbdinteractiveauthentication no`, the service is
`Running` and `Automatic`, and file ACLs are unchanged. The Pro's batch endpoint
and the Air both returned exit status `23` afterwards. The host key file is
byte-identical to its recorded hash, so no client needs re-pinning, and no
repository or agent state was touched.

The perturbation reproduced a hazard this change already documents: appending to
`sshd_config` placed the directive after the `Match Group administrators` block,
so `sshd -T` still reported `loglevel INFO`. `sshd -t` accepted the file anyway.
Any future edit must be placed in the global section deliberately, not appended.

Two leftovers are recorded rather than removed. `C:\ProgramData\ssh` still holds
the desktop worker's `sshd_config.pre-change` and `sshd_config.pre-10.0p2`
copies. `C:\WINDOWS\System32\OpenSSH` still holds the in-box client tools and
remains on the machine `PATH`, although its `sshd.exe` is gone with the removed
capability; `ssh` resolves to the standalone `C:\Program Files\OpenSSH\ssh.exe`
at 10.0p2, so client and server versions now match.

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

- The desktop starts into a signed-in session, which the owner confirms is its
  normal state. The mechanism is not established: `AutoAdminLogon` is not set,
  and the account has a password, last set 2019-10-13. `PasswordRequired` is
  `false`, which is a policy flag and not evidence of an empty password. An
  earlier claim in this record that the password was blank came from a
  desktop-side report and was wrong; it is corrected here rather than reused.

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

### Final gate run

Run sequentially on the Pro after every change above, with no evaluation-cache
contention and no `options.json` context warning:

- `nix fmt -- --fail-on-change`: clean.
- `openspec validate --all --strict`: 13 passed, 0 failed. One informational
  note remains about a requirement longer than 500 characters.
- `nix flake check --print-build-logs`: passed on Darwin; Linux checks are
  omitted by native-system selection and run on Korolev and in CI.
- `nix run .#check-darwin-build-plans`: 34 outputs, none reaching a forbidden
  source build.
- `nix build .#darwinConfigurations.macbook-pro.system`: succeeded.
- `darwin-rebuild switch` was run once for the RDP client, and
  `verify-personal-omp` reported OMP 18.1.12, a `/nix/store` plugin path and
  `omp: current`.

The temporary-path audit crash did not recur in these runs, which is expected of
an intermittent defect and is not evidence that it is fixed. It remains an
upstream defect, recorded above.

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
