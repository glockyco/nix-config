[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci-dependencies.ps1')
$root = Join-Path ([IO.Path]::GetTempPath()) ('Windows CI dependencies with spaces ' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $root
function Assert-CiFixtureFailure {
  param([string]$Name, [scriptblock]$Action, [string]$Pattern)
  $failure = $null
  try { $null = & $Action } catch { $failure = $_.Exception.Message }
  if (-not $failure -or $failure -notmatch $Pattern) { throw "fixture ${Name}: expected $Pattern, got '$failure'" }
  Write-Output "fixture passed: $Name (rejected: $failure)"
}
try {
  $lock = Get-CiDependencyLock
  Assert-CiFixtureFailure 'missing dependency lock' { Get-CiDependencyLock (Join-Path $root 'absent.json') } 'missing lock'
  Assert-CiFixtureFailure 'missing runner manifest' { Get-CiRunnerCommands $root $lock } 'missing .+runner-tools.json'
  Assert-CiFixtureFailure 'missing DSC executable' { Invoke-CiNative (Join-Path $root 'absent-dsc') @('--version') } 'missing executable'
  foreach ($case in @(
    @{ Name = 'unsupported artifact type'; Pattern = 'unsupported artifact type'; Edit = { param($x) $x.artifacts[0].kind = 'workstation-installer' } },
    @{ Name = 'missing pinned WinGet'; Pattern = 'required artifact winget missing'; Edit = { param($x) $x.artifacts = @($x.artifacts | Where-Object id -ne 'winget') } },
    @{ Name = 'unlocked artifact digest'; Pattern = 'invalid SHA-256'; Edit = { param($x) $x.artifacts[0].sha256 = 'not-a-hash' } },
    @{ Name = 'untrusted artifact URL'; Pattern = 'untrusted artifact URL'; Edit = { param($x) $x.artifacts[0].url = 'https://invalid.example/dsc.zip' } }
  )) {
    $changed = $lock | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    & $case.Edit $changed
    $path = Join-Path $root 'changed-lock.json'
    [IO.File]::WriteAllText($path, ($changed | ConvertTo-Json -Depth 20))
    Assert-CiFixtureFailure $case.Name { Get-CiDependencyLock $path } $case.Pattern
  }
  $file = Join-Path $root 'download.zip'
  [IO.File]::WriteAllText($file, 'not an official artifact')
  Assert-CiFixtureFailure 'download hash failure' { Assert-CiArtifactHash $lock.artifacts[0] $file } 'download hash mismatch for dsc'
  $native = Join-Path $root 'native double.ps1'
  [IO.File]::WriteAllText($native, '$global:LASTEXITCODE = 17')
  Assert-CiFixtureFailure 'native dependency nonzero' { Invoke-CiNative $native } 'exited 17'
  [IO.File]::WriteAllText($native, "Write-Output 'dsc 0.0.0'")
  Assert-CiFixtureFailure 'DSC version mismatch' { Assert-CiNativeVersion $lock.artifacts[0] $native } 'dsc must be 3.2.3'
  $type = 'Microsoft.Windows/Registry'
  Assert-CiResourceDiscovery '{"type":"Microsoft.Windows/Registry","version":"1.0.0"}' $type '1.0.0'
  Assert-CiFixtureFailure 'missing discovered resource' { Assert-CiResourceDiscovery '' $type '1.0.0' } 'expected one discovered resource, got 0'
  Assert-CiFixtureFailure 'discovered resource type mismatch' { Assert-CiResourceDiscovery '{"type":"Fixture/Wrong","version":"1.0.0"}' $type '1.0.0' } 'expected one discovered resource, got 0'
  Assert-CiFixtureFailure 'discovered resource version mismatch' { Assert-CiResourceDiscovery '{"type":"Microsoft.Windows/Registry","version":"0.0.0"}' $type '1.0.0' } 'expected version 1.0.0, got 0.0.0'
  Assert-CiFixtureFailure 'ambiguous discovered resource' { Assert-CiResourceDiscovery ('{"type":"Microsoft.Windows/Registry","version":"1.0.0"}' + "`n" + '{"type":"Microsoft.Windows/Registry","version":"1.0.0"}') $type '1.0.0' } 'expected one discovered resource, got 2'
  Write-Output 'Windows CI dependency fixtures passed; no downloads, AppX registration or workstation resource execution.'
} finally {
  Remove-Item -LiteralPath $root -Recurse -Force
}
