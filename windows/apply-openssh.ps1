#Requires -Version 7.0
[CmdletBinding()]
param([switch]$Test)

# Korolev's OpenSSH server for scch\jglock, listening only on the tailnet
# addresses. Both modes need an Administrator session. -Test changes nothing.
$ErrorActionPreference = 'Stop'
$principal = 'scch\jglock'
$userProfile = 'C:\Users\jglock'
# One labelled public key per source machine.
$authorizedKeys = @(
    'ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBCO3GsacmcRItY3hlqkFpKQyat9PRPBuVRPryHGbKPEjXDEhNeViH2AbPGTV1v94c7rAFhSlnnfYU50ystYOZ0c= macbook-pro-to-korolev'
)
$capability = 'OpenSSH.Server~~~~0.0.1.0'
$sshd = Join-Path $env:SystemRoot 'System32\OpenSSH\sshd.exe'
$sshKeygen = Join-Path $env:SystemRoot 'System32\OpenSSH\ssh-keygen.exe'
$sshData = Join-Path $env:ProgramData 'ssh'
$config = Join-Path $sshData 'sshd_config'
$ruleName = 'Korolev-OpenSSH-Tailnet-In-TCP'
$tailnetRanges = @('100.64.0.0/255.192.0.0', 'fd7a:115c:a1e0::/48')
$pwsh = Join-Path $userProfile 'AppData\Local\Programs\PowerShell\7\pwsh.exe'
$sshDirectory = Join-Path $userProfile '.ssh'
$authorizedKeysPath = Join-Path $sshDirectory 'authorized_keys'
$systemSid = [Security.Principal.SecurityIdentifier]'S-1-5-18'
$administratorsSid = [Security.Principal.SecurityIdentifier]'S-1-5-32-544'

function Get-TailnetAddress {
    @(Get-NetIPAddress -InterfaceAlias Tailscale -AddressState Preferred -ErrorAction SilentlyContinue |
        Where-Object { $_.IPAddress -match '^100\.' -or $_.IPAddress -match '^fd7a:115c:a1e0:' } |
        Select-Object -ExpandProperty IPAddress)
}

function Get-ConfigLine([string[]]$Addresses) {
    @('Port 22') + @($Addresses | ForEach-Object { "ListenAddress $_" }) + @(
        "AllowUsers $principal", 'AuthenticationMethods publickey', 'PubkeyAuthentication yes',
        'PasswordAuthentication no', 'AuthorizedKeysFile .ssh/authorized_keys', 'DisableForwarding yes',
        'AllowTcpForwarding no', 'AllowAgentForwarding no', 'Subsystem sftp sftp-server.exe')
}

function Test-SameSet([string[]]$Left, [string[]]$Right) {
    -not (Compare-Object @($Left | Sort-Object -Unique) @($Right | Sort-Object -Unique))
}

function Test-OwnedAcl([string]$Path, [Security.Principal.SecurityIdentifier[]]$Owners, [Security.Principal.SecurityIdentifier[]]$Allowed) {
    $acl = Get-Acl -LiteralPath $Path
    $owner = $acl.GetOwner([Security.Principal.SecurityIdentifier])
    $identities = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]) | ForEach-Object { $_.IdentityReference.Value })
    $acl.AreAccessRulesProtected -and ($Owners.Value -contains $owner.Value) -and
        @($identities | Where-Object { $Allowed.Value -notcontains $_ }).Count -eq 0
}

function Set-OwnedAcl([string]$Path, [Security.Principal.SecurityIdentifier]$Owner, [Security.Principal.SecurityIdentifier[]]$Allowed) {
    $directory = (Get-Item -LiteralPath $Path).PSIsContainer
    $acl = if ($directory) { New-Object Security.AccessControl.DirectorySecurity } else { New-Object Security.AccessControl.FileSecurity }
    $acl.SetOwner($Owner)
    $acl.SetAccessRuleProtection($true, $false)
    $inherit = if ($directory) { [Security.AccessControl.InheritanceFlags]'ContainerInherit, ObjectInherit' } else { [Security.AccessControl.InheritanceFlags]::None }
    foreach ($sid in $Allowed) {
        $acl.AddAccessRule((New-Object Security.AccessControl.FileSystemAccessRule($sid, 'FullControl', $inherit, 'None', 'Allow')))
    }
    Set-Acl -LiteralPath $Path -AclObject $acl
}

# Another enabled rule that admits TCP 22 for any program outside the tailnet
# addresses would widen the boundary. Rules scoped to a Store package (PFN or
# AppPkgId, which the cmdlets do not expose) never match the unpackaged sshd.
function Get-InboundConflict([string[]]$Addresses) {
    $rawRules = Get-ItemProperty -LiteralPath 'HKLM:\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules'
    foreach ($rule in @(Get-NetFirewallRule -PolicyStore ActiveStore -Enabled True -Direction Inbound -Action Allow)) {
        if ($rule.Name -eq $ruleName) { continue }
        $port = $rule | Get-NetFirewallPortFilter
        $address = $rule | Get-NetFirewallAddressFilter
        $application = $rule | Get-NetFirewallApplicationFilter
        $service = $rule | Get-NetFirewallServiceFilter
        $tcp = @('TCP', 'Any') -contains [string]$port.Protocol
        $port22 = (@($port.LocalPort) -contains '22') -or (@($port.LocalPort) -contains 'Any')
        $sshdProgram = ($application.Program -eq 'Any') -or ($application.Program -ieq $sshd) -or ($application.Program -ieq '%SystemRoot%\System32\OpenSSH\sshd.exe')
        $anyService = ($service.Service -eq 'Any') -or ($service.Service -ieq 'sshd')
        $packageScoped = [string]$rawRules.($rule.Name) -match '\|(PFN|AppPkgId)=[^|]+\|'
        $local = @($address.LocalAddress)
        $tailnetOnly = $local -notcontains 'Any' -and @($local | Where-Object { $Addresses -notcontains $_ }).Count -eq 0
        if ($tcp -and $port22 -and $sshdProgram -and $anyService -and -not $packageScoped -and -not $tailnetOnly) {
            "$($rule.Name) ($($rule.DisplayName))"
        }
    }
    foreach ($firewallProfile in @(Get-NetFirewallProfile -PolicyStore ActiveStore)) {
        if ([string]$firewallProfile.Enabled -ne 'True' -or @('Block', 'NotConfigured') -notcontains [string]$firewallProfile.DefaultInboundAction) {
            "firewall profile $($firewallProfile.Name) does not block inbound connections by default"
        }
    }
}

function Test-FailureAction {
    $service = 'HKLM:\SYSTEM\CurrentControlSet\Services\sshd'
    $actions = (Get-ItemProperty -LiteralPath $service -Name FailureActions -ErrorAction SilentlyContinue).FailureActions
    $nonCrash = (Get-ItemProperty -LiteralPath $service -Name FailureActionsOnNonCrashFailures -ErrorAction SilentlyContinue).FailureActionsOnNonCrashFailures
    if (-not $actions -or $actions.Length -lt 44 -or $nonCrash -ne 1) { return $false }
    # SERVICE_FAILURE_ACTIONS: reset period, two pointers, action count, pointer, then type and delay per action.
    $reset = [BitConverter]::ToUInt32($actions, 0)
    $count = [BitConverter]::ToUInt32($actions, 12)
    $delays = foreach ($index in 0..2) {
        if ([BitConverter]::ToUInt32($actions, 20 + 8 * $index) -ne 1) { -1 } else { [BitConverter]::ToUInt32($actions, 24 + 8 * $index) }
    }
    $reset -eq 86400 -and $count -eq 3 -and ($delays -join ',') -eq '30000,60000,120000'
}

function Get-Drift([string[]]$Addresses) {
    if ((Get-WindowsCapability -Online -Name $capability).State -ne 'Installed') { 'OpenSSH Server capability is not installed'; return }
    if ($Addresses.Count -lt 1) { 'Korolev has no tailnet address' }
    $shell = (Get-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -ErrorAction SilentlyContinue).DefaultShell
    if ($shell -ine $pwsh) { 'DefaultShell is not the per-user PowerShell 7' }
    $hostKeys = @(Get-ChildItem -LiteralPath $sshData -Filter 'ssh_host_*_key' -File -ErrorAction SilentlyContinue)
    if ($hostKeys.Count -lt 1) { 'host keys are missing' }
    foreach ($key in $hostKeys) {
        if (-not (Test-OwnedAcl $key.FullName @($systemSid, $administratorsSid) @($systemSid, $administratorsSid))) { "$($key.Name) is accessible beyond SYSTEM and Administrators" }
    }
    $account = ([Security.Principal.NTAccount]$principal).Translate([Security.Principal.SecurityIdentifier])
    $keysText = if (Test-Path -LiteralPath $authorizedKeysPath) { [IO.File]::ReadAllText($authorizedKeysPath) } else { $null }
    if ($keysText -cne (($authorizedKeys -join "`n") + "`n")) { 'authorized_keys differs from the declared keys' }
    foreach ($path in @($sshDirectory, $authorizedKeysPath)) {
        if ((Test-Path -LiteralPath $path) -and -not (Test-OwnedAcl $path @($account) @($account, $systemSid, $administratorsSid))) { "$path is accessible beyond $principal, SYSTEM and Administrators" }
    }
    $current = if (Test-Path -LiteralPath $config) { @([IO.File]::ReadAllLines($config) | Where-Object { $_ }) } else { @() }
    if (-not (Test-SameSet $current (Get-ConfigLine $Addresses))) { 'sshd_config differs from the declared configuration' }
    $rule = Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue
    if (-not $rule) { "firewall rule $ruleName is missing" }
    else {
        $port = $rule | Get-NetFirewallPortFilter
        $address = $rule | Get-NetFirewallAddressFilter
        $application = $rule | Get-NetFirewallApplicationFilter
        if ([string]$rule.Enabled -ne 'True' -or [string]$rule.Action -ne 'Allow' -or [string]$port.Protocol -ne 'TCP' -or
            (@($port.LocalPort) -join ',') -ne '22' -or $application.Program -ine $sshd -or
            -not (Test-SameSet @($address.LocalAddress) $Addresses) -or -not (Test-SameSet @($address.RemoteAddress) $tailnetRanges)) {
            "firewall rule $ruleName differs from the tailnet-only SSH rule"
        }
    }
    $broad = Get-NetFirewallRule -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue
    if ($broad -and [string]$broad.Enabled -eq 'True') { 'the installer rule OpenSSH-Server-In-TCP is enabled' }
    foreach ($conflict in @(Get-InboundConflict $Addresses)) { "inbound conflict: $conflict" }
    $service = Get-CimInstance Win32_Service -Filter "Name='sshd'"
    if ($service.StartMode -ne 'Auto' -or -not $service.DelayedAutoStart) { 'sshd does not start automatically with delay' }
    if (-not (Test-FailureAction)) { 'sshd does not restart after failures' }
    if ($service.State -ne 'Running') { 'sshd is not running' }
    $listeners = @(Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue | ForEach-Object { $_.LocalAddress })
    if (-not (Test-SameSet $listeners $Addresses)) { 'sshd does not listen on exactly the tailnet addresses' }
}

$elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $elevated) { throw 'apply-openssh.ps1 requires an Administrator PowerShell session' }
if (-not [Environment]::Is64BitProcess) { throw 'Run apply-openssh.ps1 from 64-bit PowerShell' }

$addresses = Get-TailnetAddress
$drift = @(Get-Drift $addresses)
if (-not $drift) {
    Write-Output 'openssh: desired'
    exit 0
}
if ($Test) {
    Write-Output ('openssh: drift: ' + ($drift -join '; '))
    exit 1
}

# The account must stay a standard user: an administrator would need
# administrators_authorized_keys, and elevation over SSH is not intended.
$account = ([Security.Principal.NTAccount]$principal).Translate([Security.Principal.SecurityIdentifier])
$administratorMembers = @(([ADSI]'WinNT://./Administrators,group').psbase.Invoke('Members') | ForEach-Object {
        (New-Object Security.Principal.SecurityIdentifier([byte[]]$_.GetType().InvokeMember('objectSid', 'GetProperty', $null, $_, $null), 0)).Value
    })
if ($administratorMembers -contains $account.Value) { throw "$principal is a local administrator; SSH is set up only for the standard account" }
if ($addresses.Count -lt 1) { throw 'Korolev has no tailnet address. Enroll Tailscale first; sshd stays unchanged' }
if (-not (Test-Path -LiteralPath $pwsh -PathType Leaf)) { throw "PowerShell 7 is missing at $pwsh" }

Add-WindowsCapability -Online -Name $capability | Out-Null
if ((Get-WindowsCapability -Online -Name $capability).State -ne 'Installed') {
    throw 'The OpenSSH Server capability finishes installing at the next restart. Restart Windows, then run this script again'
}
Stop-Service sshd -ErrorAction SilentlyContinue
Get-NetFirewallRule -Name OpenSSH-Server-In-TCP -ErrorAction SilentlyContinue | Disable-NetFirewallRule

New-Item -Path HKLM:\SOFTWARE\OpenSSH -Force | Out-Null
New-ItemProperty -Path HKLM:\SOFTWARE\OpenSSH -Name DefaultShell -PropertyType String -Value $pwsh -Force | Out-Null

& $sshKeygen -A
if ($LASTEXITCODE -ne 0) { throw 'Host key generation failed' }
# ssh-keygen ran in this Administrator session, so this account owns new keys. The sshd
# service runs as SYSTEM and ignores keys owned by or accessible to another account.
foreach ($key in Get-ChildItem -LiteralPath $sshData -Filter 'ssh_host_*_key' -File) {
    Set-OwnedAcl $key.FullName $administratorsSid @($systemSid, $administratorsSid)
}

New-Item -ItemType Directory -Path $sshDirectory -Force | Out-Null
[IO.File]::WriteAllText($authorizedKeysPath, (($authorizedKeys -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))
foreach ($path in @($sshDirectory, $authorizedKeysPath)) {
    Set-OwnedAcl $path $account @($account, $systemSid, $administratorsSid)
}

[IO.File]::WriteAllText($config, ((Get-ConfigLine $addresses) -join "`n") + "`n", [Text.UTF8Encoding]::new($false))
& $sshd -t -f $config
if ($LASTEXITCODE -ne 0) { throw 'sshd rejected the configuration' }

Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue | Remove-NetFirewallRule
New-NetFirewallRule -Name $ruleName -DisplayName 'Korolev SSH on tailnet addresses only' -Direction Inbound -Action Allow -Enabled True -Profile Any `
    -Protocol TCP -LocalPort 22 -LocalAddress $addresses -RemoteAddress $tailnetRanges -Program $sshd -EdgeTraversalPolicy Block | Out-Null
$conflicts = @(Get-InboundConflict $addresses)
if ($conflicts) { throw ('sshd stays stopped: ' + ($conflicts -join '; ')) }

# Tailscale may not be ready at boot, so start late and retry a failed bind.
& sc.exe config sshd start= delayed-auto | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Delayed sshd start configuration failed' }
& sc.exe failure sshd reset= 86400 actions= restart/30000/restart/60000/restart/120000 | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'sshd recovery configuration failed' }
& sc.exe failureflag sshd 1 | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'sshd failure-action flag configuration failed' }
Start-Service sshd
Start-Sleep -Seconds 2
$listeners = @(Get-NetTCPConnection -State Listen -LocalPort 22 -ErrorAction SilentlyContinue | ForEach-Object { $_.LocalAddress })
if (-not (Test-SameSet $listeners $addresses)) {
    Stop-Service sshd
    throw 'sshd did not listen on exactly the tailnet addresses and was stopped'
}
$fingerprint = (& $sshKeygen -lf (Join-Path $sshData 'ssh_host_ed25519_key.pub')) -join ' '
Write-Output "openssh: changed; host key $fingerprint"
