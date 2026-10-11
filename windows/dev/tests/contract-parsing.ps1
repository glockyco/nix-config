[CmdletBinding()]
param([string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent }
. (Join-Path $RepositoryRoot 'windows/tests/native-contract.ps1')

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
$boundarySource = "New-NetFirewallRule -Name fixture"
$null = Get-ScriptRecord 'old.ps1' $boundarySource
$record = Get-ScriptRecord 'new.ps1' $boundarySource
$failure = $null
try { Test-DocumentScriptBoundary $record ([PSCustomObject]@{ id = 'Fixture.App' }) } catch { $failure = $_.Exception.Message }
Assert-Contract ($failure -match '^script new\.ps1: feature/service ownership is forbidden$') 'parser fixture: reused AST bypassed ownership assertions or reported an old name'
# The source/name remain identical; only the relay policy changes. A previous
# ordinary-app success must not hide the stricter relay writer rejection.
$relayRecord = Get-ScriptRecord 'policy.ps1' 'Start-Process fixture'
Test-DocumentScriptBoundary $relayRecord ([PSCustomObject]@{ id = 'Fixture.App' })
$failure = $null
try { Test-DocumentScriptBoundary $relayRecord ([PSCustomObject]@{ id = 'Brave.Brave' }) } catch { $failure = $_.Exception.Message }
Assert-Contract ($failure -match '^script policy\.ps1: relay/communication startup or profile ownership is forbidden$') 'parser fixture: changed relay policy reused ordinary-app success'
$adminRecord = Get-ScriptRecord 'role.ps1' "if (-not `$principal.IsInRole('Administrator')) { throw 'fixture' }"
Test-ApprovedScriptRole $adminRecord $true
$failure = $null
try { Test-ApprovedScriptRole $adminRecord $false } catch { $failure = $_.Exception.Message }
Assert-Contract ($failure -match '^script role\.ps1: unapproved Administrator program$') 'parser fixture: changed approved-script flag reused Administrator success'
Test-ApprovedScriptRole $first
$beforeNames = $first.Checks.Count
Test-ApprovedScriptRole $second
Assert-Contract ($second.Checks.Count -eq $beforeNames + 1) 'parser fixture: different caller name reused a named role check'
$nativeSource = @'
$saved = $ErrorActionPreference
try {
    $ErrorActionPreference = 'Continue'
    & $tool
    $nativeCode = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $saved
}
if ($nativeCode -ne 0) { throw 'fixture' }
'@
$nativeFirst = Get-ScriptRecord 'native-first.ps1' $nativeSource
Test-NativeInvocationScopes $nativeFirst
$beforeNames = $nativeFirst.Checks.Count
Test-NativeInvocationScopes (Get-ScriptRecord 'native-second.ps1' $nativeSource)
Assert-Contract ($nativeFirst.Checks.Count -eq $beforeNames + 1) 'parser fixture: different caller name reused a named native invocation check'
$invalidNativeSource = $nativeSource.Replace("'Continue'", "'Stop'")
foreach ($name in @('native-first.ps1', 'native-first.ps1', 'native-renamed.ps1')) {
    $invalidNative = Get-ScriptRecord $name $invalidNativeSource
    $failure = $null
    try { Test-NativeInvocationScopes $invalidNative } catch { $failure = $_.Exception.Message }
    Assert-Contract ($failure -match ('^script ' + [regex]::Escape($name) + ': native invocation at \d+: native invocation must temporarily select Continue$')) "parser fixture: changed native source lost its current rejection for $name"
    Assert-Contract ($invalidNative.Checks.Count -eq 0) 'parser fixture: failed native invocation check was cached'
}
foreach ($name in @('invalid-first.ps1', 'invalid-second.ps1')) {
    $failure = $null
    try { $null = Get-ScriptRecord $name 'if (' } catch { $failure = $_.Exception.Message }
    Assert-Contract ($failure -match ('^script ' + [regex]::Escape($name) + ': .+ at 1:')) "parser fixture: invalid source lost the current name or parser diagnostic for $name"
}
Write-Host 'PASS exact-source parser/role/boundary reuse, policy/name invalidation and retained syntax/ownership assertions'
