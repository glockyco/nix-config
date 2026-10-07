# Korolev native remote access

Windows owns the single reachable `korolev` / `tag:korolev` node. WSL remains `x86_64-linux`, NAT-networked, with no tailscaled, SSH listener, open service port or Windows port proxy. The tailnet policy grants **all ports** on reachable machines to every node; it is not an SSH-only ACL. This procedure enables only native SSH, not RDP, SMB or WinRM. Account keys and the effective Windows listener/firewall are separate boundaries.

Every step labeled **OWNER-TYPED** requires the owner to enter the credential, approve the operation or operate the authenticated console; never collect passwords/tokens. Commands below are manual reviewed operations, not a third Administrator script, WinGet resource or elevated chezmoi apply. Keep a local Administrator recovery terminal, the previous accepted WSL generation and the Mac available throughout. Stop if Intune/employer policy prohibits capability installation or defeats the effective firewall boundary; do not weaken employer policy.

## 1. One-node migration

1. Record the old WSL node ID, name and tag in local evidence (no auth key/device-state export), Windows service/capability inventory, and permission-preserving backups of existing change-owned SSH config, registry value, authorized_keys and firewall rule. Record whether each existed, service startup/state, delayed-start setting, failure actions/reset period and failure-action flag (`sc.exe qc sshd`, `sc.exe qfailure sshd`, `sc.exe qfailureflag sshd` if present), and ACLs for rollback. Retain prior Nix generation. Publication/policy deployment requires separate **OWNER-TYPED authorization** to push/merge; these commands do not deploy policy.

1. **OWNER-TYPED Linux sudo**, in the old WSL generation: `sudo tailscale logout`, then `sudo systemctl stop tailscaled`. **OWNER-TYPED Tailscale admin-console login:** revoke/remove the recorded Linux node. Confirm it is not connected before proceeding.

1. **OWNER-TYPED Linux sudo:** activate the reviewed daemon-free NixOS generation with `sudo nixos-rebuild switch --flake .#korolev`. Check `systemctl list-units --all '*tailscale*'`, `ss -lntup`, `resolvectl status`; no tailscaled/SSH service or externally reachable service is allowed. Retain DNS upstream `10.255.255.254` and WSL DNS tunneling, never mirrored networking.

1. **OWNER-TYPED Administrator/UAC:** install the reviewed machine-scope Windows Tailscale package if absent. It must remain unenrolled until steps 2–3 finish. Close the separate Administrator terminal for enrollment. In **non-elevated PowerShell as `scch\jglock`**, verify the actual native path/version and enroll shields-up:

   ```powershell
   $tailscale = 'C:\Program Files\Tailscale\tailscale.exe'
   if (-not (Test-Path -LiteralPath $tailscale)) { throw 'Windows Tailscale CLI missing' }
   & $tailscale version
   if ($LASTEXITCODE -ne 0) { throw 'Tailscale version query failed' }
   & $tailscale up --hostname=korolev --advertise-tags=tag:korolev --accept-dns=true --unattended=true --shields-up=true
   if ($LASTEXITCODE -ne 0) { throw 'Windows enrollment failed' }
   ```

1. **OWNER-TYPED provider/browser login and tag approval:** verify exactly one active node named `korolev`, OS Windows, tag `tag:korolev`, no numeric duplicate and disabled key expiry in the admin console. Confirm unattended Tailscale service startup. Never import Linux Tailscale state or keep both daemons running. Record Windows node ID and actual IPv4/IPv6 addresses, not credentials.

   Windows Tailscale LocalAPI operations belong to the profile owner `scch\jglock` (or SYSTEM), not the separate Administrator account. Run `up`, `ip`, `set`, `logout` and diagnostic `ping` in that standard-user context. WSL interop invokes `tailscale.exe` through the same Windows profile even when the Linux builder check runs as root. Keep shields-up until the inbound inventory and native SSH audit below pass.

   Still in **non-elevated `scch\jglock` PowerShell**, record the node's addresses for the local Administrator to cross-check:

   ```powershell
   $v4 = & $tailscale ip -4
   if ($LASTEXITCODE -ne 0) { throw 'No tailnet IPv4' }
   $v6 = & $tailscale ip -6
   if ($LASTEXITCODE -ne 0) { throw 'Tailnet IPv6 query failed' }
   $recordedAddresses = @($v4, $v6) | ForEach-Object { $_.Trim() } | Where-Object { $_ }
   $recordedAddresses | Set-Content -LiteralPath 'C:\Users\jglock\AppData\Local\Temp\korolev-tailnet-addresses.txt' -Encoding ASCII
   $recordedAddresses
   ```

## 2. Explicit OpenSSH setup

**OWNER-TYPED Administrator credential/UAC** for capability, SSH files/ACLs, registry, service and firewall writes, in 64-bit Administrator PowerShell. Tailscale LocalAPI commands remain in the explicitly labeled non-elevated standard-user terminal, including final inbound enablement. The approved principal is the observed AD standard account `scch\jglock`, profile `C:\Users\jglock`; it is not an Administrator or Entra-only principal. Microsoft does not support Entra-only OpenSSH authentication. Never derive the profile or shell from the separate Administrator's `$env:USERPROFILE` / `$env:LOCALAPPDATA`.

```powershell
$ErrorActionPreference = 'Stop'
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Stop-Service sshd -ErrorAction SilentlyContinue
Set-Service sshd -StartupType Disabled
# The capability installer can create a broad inbound allow: disable before any start.
Get-NetFirewallRule -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue | Disable-NetFirewallRule
$sshd = 'C:\Windows\System32\OpenSSH\sshd.exe'
$sshKeygen = 'C:\Windows\System32\OpenSSH\ssh-keygen.exe'
$profile = 'C:\Users\jglock'
$principal = 'scch\jglock'
$pwsh = Join-Path $profile 'AppData\Local\Programs\PowerShell\7\pwsh.exe'
if (-not (Test-Path -LiteralPath $pwsh)) { throw 'Approved per-user PowerShell missing' }
$pwsh = (Resolve-Path -LiteralPath $pwsh).Path
New-Item -Path HKLM:\SOFTWARE\OpenSSH -Force | Out-Null
New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -PropertyType String -Value $pwsh -Force | Out-Null
& $sshKeygen -A
if ($LASTEXITCODE -ne 0) { throw 'Host key generation failed' }
```

Inspect local group membership with `Get-LocalGroupMember -SID S-1-5-32-544` and resolve the account SID; confirm effective domain membership with the employer's approved account tools. If this is not the approved standard account, stop. Do not elevate it or use `administrators_authorized_keys`. Keep service identity `LocalSystem` as installed; the authenticated shell runs as the standard account, not as the service identity.

### Source-specific public keys and NTFS ACLs

On the Mac and desktop separately, generate or retain a user-owned Ed25519 key. **OWNER-TYPED source approval** of each key and trusted local transfer of its **public** key only. Create `C:\Users\jglock\.ssh\authorized_keys` with two distinct lines labeled `macbook-pro-to-korolev` and `desktop-to-korolev`. Do not copy private keys, passwords, WSL keys or the root builder key. Never overwrite unrelated authorized keys without reviewing the backup and approved account policy.

For the reviewed two-key file, remove inherited and unrelated explicit ACL entries using a fresh ACL, not merely `/grant` beside stale broad grants:

```powershell
$accountSid = ([System.Security.Principal.NTAccount]$principal).Translate([System.Security.Principal.SecurityIdentifier])
$systemSid = [System.Security.Principal.SecurityIdentifier]'S-1-5-18'
$adminsSid = [System.Security.Principal.SecurityIdentifier]'S-1-5-32-544'
$sshDir = Join-Path $profile '.ssh'
$authorizedKeys = Join-Path $sshDir 'authorized_keys'
New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
if (-not (Test-Path -LiteralPath $authorizedKeys)) { throw 'Install the approved labeled public keys first' }
foreach ($path in @($sshDir, $authorizedKeys)) {
    $isDir = (Get-Item -LiteralPath $path).PSIsContainer
    if ($isDir) { $acl = New-Object System.Security.AccessControl.DirectorySecurity }
    else { $acl = New-Object System.Security.AccessControl.FileSecurity }
    $acl.SetOwner($accountSid)
    $acl.SetAccessRuleProtection($true, $false)
    foreach ($sid in @($accountSid, $systemSid, $adminsSid)) {
        $inherit = [System.Security.AccessControl.InheritanceFlags]::None
        if ($isDir) { $inherit = [System.Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit' }
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($sid, 'FullControl', $inherit, 'None', 'Allow')
        $acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $path -AclObject $acl
    Get-Acl -LiteralPath $path | Format-List Owner, AccessToString
}
```

### Tailnet listener and firewall

In **Administrator PowerShell**, query the Windows adapter with `Get-NetIPAddress`, not the profile-owned Tailscale CLI. Compare the current adapter addresses against the standard user's locally recorded node addresses; any mismatch blocks configuration:

```powershell
$recordedAddresses = @(Get-Content -LiteralPath 'C:\Users\jglock\AppData\Local\Temp\korolev-tailnet-addresses.txt')
$addresses = @(Get-NetIPAddress -InterfaceAlias Tailscale -AddressState Preferred |
    Where-Object { $_.IPAddress -match '^100\.' -or $_.IPAddress -match '^fd7a:115c:a1e0:' } |
    Select-Object -ExpandProperty IPAddress)
if ($addresses.Count -lt 1) { throw 'No tailnet address; keep sshd disabled' }
if (Compare-Object ($recordedAddresses | Sort-Object) ($addresses | Sort-Object)) { throw 'Node/adapter address mismatch' }
Get-NetIPInterface -InterfaceAlias Tailscale | Format-Table InterfaceAlias, AddressFamily, ConnectionState
Get-NetConnectionProfile -InterfaceAlias Tailscale | Format-List InterfaceAlias, NetworkCategory
```

Replace each `WINDOWS_TAILNET_*` token below with the verified address; omit the IPv6 line only if the node has no IPv6 address. Write UTF-8 without BOM to `C:\ProgramData\ssh\sshd_config`, preserving the backed-up host keys. This is the complete reviewed policy, with no default `Match Group administrators` block:

```sshd_config
Port 22
ListenAddress WINDOWS_TAILNET_IPV4
ListenAddress WINDOWS_TAILNET_IPV6
AllowUsers scch\jglock
AuthenticationMethods publickey
PubkeyAuthentication yes
PasswordAuthentication no
AuthorizedKeysFile .ssh/authorized_keys
DisableForwarding yes
AllowTcpForwarding no
AllowAgentForwarding no
Subsystem sftp sftp-server.exe
```

Only supported in-box directives are shipped. In particular do **not** copy `KbdInteractiveAuthentication`, `StrictModes`, `PermitTunnel`, `AllowStreamLocalForwarding` or `X11Forwarding` from Unix/desktop examples: Microsoft's unsupported list includes them. `AuthenticationMethods publickey` plus `PasswordAuthentication no` enforces the available Windows key-only method; verify effective settings and rejected authentication, not an unsupported keyword. SFTP remains enabled; no forced command, forwarding, WSL proxy or session-elevation service.

```powershell
& $sshd -t -f C:\ProgramData\ssh\sshd_config
if ($LASTEXITCODE -ne 0) { throw 'sshd configuration rejected' }
& $sshd -T -f C:\ProgramData\ssh\sshd_config -C 'user=scch\jglock,host=korolev,addr=100.88.17.38'
if ($LASTEXITCODE -ne 0) { throw 'Effective sshd configuration query failed' }
# Reconcile one owned rule; no duplicate rules, no wildcard local address.
$ruleName = 'Korolev-OpenSSH-Tailnet-In-TCP'
Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -Name $ruleName -DisplayName 'Korolev SSH on tailnet addresses only' -Direction Inbound -Action Allow -Enabled True -Profile Any -Protocol TCP -LocalPort 22 -LocalAddress $addresses -RemoteAddress '100.64.0.0/10','fd7a:115c:a1e0::/48' -Program $sshd -EdgeTraversalPolicy Block
Get-NetFirewallRule -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue | Disable-NetFirewallRule
Get-NetFirewallProfile -PolicyStore ActiveStore | Format-List Name, Enabled, DefaultInboundAction, AllowLocalFirewallRules
# Inspect EVERY effective inbound allow, including Tailscale and employer rules.
Get-NetFirewallRule -PolicyStore ActiveStore -Enabled True -Direction Inbound -Action Allow | ForEach-Object {
    $_ | Format-List Name, DisplayName, Profile, PolicyStoreSource, PolicyStoreSourceType
    $_ | Get-NetFirewallPortFilter | Format-List Protocol, LocalPort, RemotePort
    $_ | Get-NetFirewallAddressFilter | Format-List LocalAddress, RemoteAddress
    $_ | Get-NetFirewallApplicationFilter | Format-List Program
    $_ | Get-NetFirewallServiceFilter | Format-List Service
}
# Inventory all TCP listeners and UDP endpoints, including wildcard binds.
Get-NetTCPConnection -State Listen | Select-Object LocalAddress, LocalPort, OwningProcess
Get-NetUDPEndpoint | Select-Object LocalAddress, LocalPort, OwningProcess
Get-CimInstance Win32_Process | Select-Object ProcessId, Name, ExecutablePath
```

Before starting, confirm enabled firewall profiles with default inbound block, the owned allow has only current tailnet local addresses/TCP 22/sshd, and no effective wildcard/LAN rule admits sshd or TCP 22 (including Any-port/program/service rules). Audit **every non-SSH inbound allow and TCP/UDP listener**, including wildcard binds, against the Tailscale interface and its active firewall profile: no non-SSH inbound allow may admit application traffic there and no non-SSH listener may be reachable over the tailnet. Tailscale's encrypted transport rules on physical interfaces must not admit application traffic on the tunnel. Disable/restrict only owned conflicting settings with approval; block deployment if employer-owned settings defeat this boundary. Keep shields-up while investigating. `sshd -T` must show the exact addresses, approved account, publickey-only authentication, no password and forwarding disabled. Then **OWNER-TYPED service-start approval**, still with shields-up:

```powershell
# Delay initial start and retry a closed listener if Tailscale is not ready at boot.
& sc.exe config sshd start= delayed-auto
if ($LASTEXITCODE -ne 0) { throw 'Delayed sshd start configuration failed' }
& sc.exe failure sshd reset= 86400 actions= restart/30000/restart/60000/restart/120000
if ($LASTEXITCODE -ne 0) { throw 'sshd recovery configuration failed' }
& sc.exe failureflag sshd 1
if ($LASTEXITCODE -ne 0) { throw 'sshd failure-action flag configuration failed' }
Start-Service sshd
Get-CimInstance Win32_Service -Filter "Name='sshd'" | Select-Object Name, StartName, State, StartMode, PathName
Get-NetTCPConnection -State Listen -LocalPort 22 | Select-Object LocalAddress, LocalPort, OwningProcess
& $sshKeygen -lf C:\ProgramData\ssh\ssh_host_ed25519_key.pub
& sc.exe qc sshd
& sc.exe qfailure sshd
& sc.exe qfailureflag sshd
```

Only after the effective firewall/listener inventory passes and SSH is listening on the exact tailnet addresses, return to **non-elevated `scch\jglock` PowerShell** for **OWNER-TYPED inbound-enablement approval**:

```powershell
$tailscale = 'C:\Program Files\Tailscale\tailscale.exe'
& $tailscale set --shields-up=false
if ($LASTEXITCODE -ne 0) { throw 'Inbound Tailscale enablement failed' }
```

Repeat the effective inventory and allowed/denied path probes immediately after enablement. If any non-SSH application is reachable, run `& $tailscale set --shields-up=true` in the same standard-user terminal, stop sshd locally as Administrator, and block deployment until the boundary is restored.

Console-verify and pin this real host key independently on both sources. Never accept a scanned key without comparison. Add pinned native `korolev` / `korolev-batch` endpoints for `scch\jglock`; batch uses no PTY, no persistence/multiplexing, stdin retained, strict host checking, publickey-only and bounded timeout. Native Windows' outbound Mac/desktop user key is separately generated/approved; **OWNER-TYPED desktop privilege and Mac sudo** enroll its public key, never the root builder credential.

## 3. Acceptance after cutover

From both Mac and desktop prove native PowerShell command execution (including paths with spaces), status 23, intended interactive TTY, batch stdin/no PTY/no persistence and SFTP disposable-file hash round-trip. Reject an unapproved key and deliberately changed temporary host pin. Temporarily revoke one source authorization and prove the other still works, then restore only approved keys. Tailnet membership alone must not authenticate.

Independently demonstrate a reachable non-tailnet IPv4/IPv6 path and verify SSH denial there; lack of route is not firewall proof. **OWNER-TYPED approved tunnel-stop/restart** with local recovery available: loss of Tailscale must create no wildcard/LAN fallback. Repeat listener/firewall and allowed/denied probes after restoration.

In WSL as ordinary user and root, check public/employer DNS and `getent ahosts macbook-pro.tail8768af.ts.net`, `resolvectl status`, and root `ssh macbook-pro 'exit 23'` with status 23. Inspect root key permissions and the pinned builder SSH configuration, then run `sudo tailnet-builder-check`. Its fresh nonce must build on arm64 `macbook-pro` and copy the result into the Linux store. It invokes the quoted `/mnt/c/Program Files/Tailscale/tailscale.exe ping --c 1 --until-direct=false macbook-pro`; DERP replies are accepted and native failure status propagates. **Before cutover**, the live host still uses Linux tailscaled: the new diagnostic fails if the Windows CLI is absent/unenrolled even if the Mac build succeeds. This is intentional, not a Linux fallback. No Linux tailscale package is in this check's runtime dependencies.

**OWNER-TYPED coordinated WSL termination/restart** and later a true Windows reboot repeat DNS, root-daemon build, one-node/unattended startup and source-specific SSH/firewall checks. Run Nix gates sequentially, with the Mac builder. DNS/root-daemon routing through Windows NAT/DNS tunneling is a live risk: failure blocks acceptance; never add a duplicate Linux daemon or guessed resolver fallback. Sleep/offline means unavailable access; an OMP history entry is not a surviving process or automatic execution.

## 4. Reconciliation and rollback

On every re-enrollment/address change, **OWNER-TYPED standard-user `scch\jglock`** first sets shields-up and records current CLI addresses again. **OWNER-TYPED Administrator** stops/disables sshd, queries `Get-NetIPAddress -InterfaceAlias Tailscale` and cross-checks the recorded addresses, replaces only `ListenAddress` entries and reconciles the one named firewall rule. Re-run `sshd -t`, `sshd -T` and the complete effective firewall/listener audit before restoring delayed start/recovery, restarting SSH and approving standard-user `tailscale set --shields-up=false`. A missing/stale address fails closed; never substitute `0.0.0.0`, `::`, LAN bindings or a broad rule. Delayed start and service recovery handle transient adapter readiness at reboot without broadening the listener; an address change still requires manual reconciliation. No extra scheduler is added.

**OWNER-TYPED local Administrator rollback:** stop/disable sshd and remove the owned `Korolev-OpenSSH-Tailnet-In-TCP` rule; restore captured owned config, ACLs, DefaultShell and service state, including prior delayed-start setting, failure actions/reset period and failure-action flag, only if their prior effective boundary is safe. Do not blindly re-enable the capability installer's broad rule. Remove the capability with `Remove-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0` only if this change installed it and owner approves; preserve host keys/backups. Revoke the appropriate source public key independently, preserving other authorizations and all private keys/app state.

For failed Windows transport, **OWNER-TYPED standard-user `scch\jglock`** sets shields-up and runs `& 'C:\Program Files\Tailscale\tailscale.exe' logout`; then **OWNER-TYPED Administrator** stops the Windows Tailscale service and **OWNER-TYPED provider login** revokes its node. Only then **OWNER-TYPED Linux sudo** restores the previous accepted WSL generation and explicitly re-enrolls one Linux node with the recorded hostname/tag under owner supervision. Never restore/copied device state or operate two nodes. Recheck DNS/root builder. Policy rollback is a separately reviewed, explicitly authorized deployment, not an automatic push/revert. Retain local Windows and Mac recovery, backups and previous generations until all live gates pass.

References: [Microsoft configuration and supported directives](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh-server-configuration), [capability installation](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse), [Windows/WSL Tailscale guidance](https://tailscale.com/docs/install/windows/wsl2.md). The repository review fixture checks the shipped config's supported directive set; only native `sshd -t` / `-T` and live probes prove deployment.
