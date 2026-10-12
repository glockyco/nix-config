[CmdletBinding()]
param([string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent }
. (Join-Path $RepositoryRoot 'windows/tests/powershell-contract.ps1')
. (Join-Path $RepositoryRoot 'windows/tests/admin-paths.ps1')

$source = "`$value = 'fixture'; Write-Output `$value"
$first = Get-ScriptRecord 'first.ps1' $source
$second = Get-ScriptRecord 'second.ps1' $source
Assert-Contract ([object]::ReferenceEquals($first.Ast, $second.Ast)) 'parser fixture: identical source was reparsed'
Assert-Contract (-not [object]::ReferenceEquals($first, $second) -and $first.Name -ceq 'first.ps1' -and $second.Name -ceq 'second.ps1') 'parser fixture: cached source retained another caller name'
foreach ($property in @('Strings', 'Variables', 'Commands', 'Members')) {
    Assert-Contract ([object]::ReferenceEquals($first.$property, $second.$property)) "parser fixture: $property nodes were rediscovered"
}
foreach ($changed in @($source.Replace('fixture', 'FIXTURE'), ($source + "`n"), ($source + "; New-NetFirewallRule -Name fixture"))) {
    $record = Get-ScriptRecord 'first.ps1' $changed
    Assert-Contract (-not [object]::ReferenceEquals($first.Ast, $record.Ast) -and $record.Ast.Extent.Text -ceq $changed) 'parser fixture: different exact source reused a stale parse'
}
$adminRecord = Get-ScriptRecord 'role.ps1' "if (-not `$principal.IsInRole('Administrator')) { throw 'fixture' }"
Test-ApprovedScriptRole $adminRecord $true
$failure = $null
try { Test-ApprovedScriptRole $adminRecord $false } catch { $failure = $_.Exception.Message }
Assert-Contract ($failure -match '^script role\.ps1: unapproved Administrator program$') 'parser fixture: changed approved-script flag reused Administrator success'
Test-ApprovedScriptRole $first
$beforeNames = $first.Checks.Count
Test-ApprovedScriptRole $second
Assert-Contract ($second.Checks.Count -eq $beforeNames + 1) 'parser fixture: different caller name reused a named role check'
foreach ($name in @('invalid-first.ps1', 'invalid-second.ps1')) {
    $failure = $null
    try { $null = Get-ScriptRecord $name 'if (' } catch { $failure = $_.Exception.Message }
    Assert-Contract ($failure -match ('^script ' + [regex]::Escape($name) + ': .+ at 1:')) "parser fixture: invalid source lost the current name or parser diagnostic for $name"
}
foreach ($name in @('apply-kbdneo.ps1', 'apply-zen-policies.ps1')) {
    $source = [IO.File]::ReadAllText((Join-Path $RepositoryRoot "windows/$name"))
    Test-AdministratorScript (Get-ScriptRecord $name $source) $name
    $refactored = $source.Replace('$principal', '$administratorIdentity').Replace('$path', '$ownedDestination').Replace('$registryPath', '$ownedRegistration').Replace('Join-Path ', 'Join-Path  ')
    Test-AdministratorScript (Get-ScriptRecord $name $refactored) $name
    $failure = $null
    try { Test-ApprovedScriptRole (Get-ScriptRecord 'other-admin.ps1' $source) } catch { $failure = $_.Exception.Message }
    Assert-Contract ($failure -match '^script other-admin\.ps1: unapproved Administrator program$') "$name copied Administrator program was accepted"
    foreach ($suffix in @('$env:USERPROFILE', '$env:LOCALAPPDATA', '$HOME', '$PROFILE')) {
        $failure = $null
        try { Test-AdministratorScript (Get-ScriptRecord $name ($source + "`n" + $suffix)) $name } catch { $failure = $_.Exception.Message }
        Assert-Contract ($failure -match 'forbidden profile variable') "$name accepted a profile variable"
    }
    foreach ($path in @('HKCU:\Software\Fixture', 'C:\Windows\outside-owned.txt', 'HKLM:\Software\Fixture')) {
        $failure = $null
        try { Test-AdministratorScript (Get-ScriptRecord $name ($source + "`n`$fixture = '$path'")) $name } catch { $failure = $_.Exception.Message }
        Assert-Contract ($failure -match 'forbidden profile/registry|machine path|machine registry') "$name accepted a path outside fixed ownership"
    }
    foreach ($case in @(
        @{ Source = $source + "`nNew-NetFirewallRule -Name fixture"; Finding = 'command outside fixed ownership' },
        @{ Source = $source.Replace('IsInRole', 'Equals'); Finding = 'member outside fixed ownership|missing unelevated-write rejection' },
        @{ Source = $source + "`n[IO.File]::WriteAllText('outside-owned.txt', 'fixture')"; Finding = 'resolved path outside fixed ownership' },
        @{ Source = $source + "`nNew-Item 'outside-owned.txt' -Force"; Finding = 'resolved path outside fixed ownership' },
        @{ Source = $source.Replace("`$ErrorActionPreference = 'Stop'", "`$ErrorActionPreference = 'Stop'`nNew-Item -Path 'fixture-write-before-guard'"); Finding = 'write precedes Administrator guard' }
    )) {
        $failure = $null
        try { Test-AdministratorScript (Get-ScriptRecord $name $case.Source) $name } catch { $failure = $_.Exception.Message }
        Assert-Contract ($failure -match $case.Finding) "$name failed to retain ownership rejection $($case.Finding)"
    }
    $bad = if ($name -eq 'apply-zen-policies.ps1') {
        $source.Replace('Zen Browser\distribution\policies.json', 'Other App\distribution\policies.json')
    } else {
        $source.Replace('"layoutId":"b0000407"', '"layoutId":"a0000407"')
    }
    $failure = $null
    try { Test-AdministratorScript (Get-ScriptRecord $name $bad) $name } catch { $failure = $_.Exception.Message }
    Assert-Contract ($failure -match 'joined path outside fixed ownership|ownership must remain b0000407/kbdneo2.dll') "$name accepted expanded fixed ownership"
}
$failure = $null
try { Test-ApprovedScriptRole (Get-ScriptRecord 'rendered user apply.ps1' "& '.\apply-kbdneo.ps1'") } catch { $failure = $_.Exception.Message }
Assert-Contract ($failure -match 'fixed Administrator scripts must not run automatically') 'Automatic fixed Administrator invocation was accepted'
Write-Host 'PASS exact-source parser/role reuse, name/policy invalidation and fixed Administrator ownership assertions'
