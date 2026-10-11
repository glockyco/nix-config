[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci-dependencies.ps1')
$root = Join-Path ([IO.Path]::GetTempPath()) ('Windows CI dependencies with spaces ' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $root
. (Join-Path $PSScriptRoot 'ci-provision.ps1') -RunnerToolsRoot $root
$originalActions = $env:GITHUB_ACTIONS
$originalRunnerEnvironment = $env:RUNNER_ENVIRONMENT
$originalRunnerTemp = $env:RUNNER_TEMP
$originalOS = $env:OS
$script:DownloadCount = 0
$script:DownloadFault = $false
function Invoke-WebRequest {
  param([switch]$UseBasicParsing, [string]$Uri, [string]$OutFile)
  $script:DownloadCount++
  $script:ObservedProgressPreference = $ProgressPreference
  if ($script:DownloadFault) { throw 'fixture download failure' }
  [IO.File]::WriteAllText($OutFile, 'fixture archive', (New-Object Text.UTF8Encoding $false))
}
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
  $cache = Join-Path $root 'archive cache'
  $null = New-Item -ItemType Directory -Path $cache
  $fixtureFile = Join-Path $root 'fixture archive'
  [IO.File]::WriteAllText($fixtureFile, 'fixture archive', (New-Object Text.UTF8Encoding $false))
  $artifact = $lock.artifacts[0] | ConvertTo-Json -Depth 10 | ConvertFrom-Json
  $artifact.sha256 = (Get-FileHash -LiteralPath $fixtureFile -Algorithm SHA256).Hash.ToLowerInvariant()
  $savedProgressPreference = $ProgressPreference
  $archive = Receive-CiArtifact $artifact $cache
  Assert-CiDependency ($script:DownloadCount -eq 1 -and $script:ObservedProgressPreference -eq 'SilentlyContinue' -and $ProgressPreference -eq $savedProgressPreference) 'fresh archive did not download with locally suppressed progress'
  $restored = Receive-CiArtifact $artifact $cache
  Assert-CiDependency ($script:DownloadCount -eq 1 -and $restored -ceq $archive) 'restored archive was redownloaded'
  [IO.File]::WriteAllText($archive, 'corrupt restored archive')
  Assert-CiFixtureFailure 'restored archive corruption' { Receive-CiArtifact $artifact $cache } 'download hash mismatch for dsc'
  Assert-CiDependency ($script:DownloadCount -eq 1 -and [IO.File]::ReadAllText($archive) -ceq 'corrupt restored archive') 'cache corruption was redownloaded or overwritten'
  Remove-Item -LiteralPath $archive
  $script:DownloadFault = $true
  Assert-CiFixtureFailure 'download progress restoration' { Receive-CiArtifact $artifact $cache } 'fixture download failure'
  Assert-CiDependency ($ProgressPreference -eq $savedProgressPreference) 'failed download changed caller progress preference'
  $script:DownloadFault = $false
  $artifact.sha256 = $lock.artifacts[0].sha256
  Assert-CiFixtureFailure 'fresh archive corruption' { Receive-CiArtifact $artifact $cache } 'download hash mismatch for dsc'
  $env:GITHUB_ACTIONS = 'true'
  $env:RUNNER_ENVIRONMENT = 'github-hosted'
  $env:RUNNER_TEMP = Split-Path $root -Parent
  $env:OS = 'Windows_NT'
  Assert-CiFixtureFailure 'existing tools directory refusal' { Invoke-CiProvision -RunnerToolsRoot $root -ArchiveCacheRoot $cache } 'runner tools directory already exists'
  $newTools = Join-Path $root 'fresh tools'
  Assert-CiFixtureFailure 'archive cache inside runner tools' { Invoke-CiProvision -RunnerToolsRoot $newTools -ArchiveCacheRoot (Join-Path $newTools 'archives') } 'separate, non-overlapping'
  Assert-CiFixtureFailure 'runner tools inside archive cache' { Invoke-CiProvision -RunnerToolsRoot $newTools -ArchiveCacheRoot $root } 'separate, non-overlapping'
  Write-Output 'fixture passed: runner archive cache cold/warm, fatal corruption, progress restoration and fresh separate tools'
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
  $env:GITHUB_ACTIONS = $originalActions
  $env:RUNNER_ENVIRONMENT = $originalRunnerEnvironment
  $env:RUNNER_TEMP = $originalRunnerTemp
  $env:OS = $originalOS
  Remove-Item -LiteralPath $root -Recurse -Force
}
