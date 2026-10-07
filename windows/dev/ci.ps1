[CmdletBinding()]
param(
  [string]$RepositoryRoot,
  [string]$RunnerToolsRoot = (Join-Path $env:RUNNER_TEMP 'native-check')
)

$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
. (Join-Path $PSScriptRoot 'ci-dependencies.ps1')
Assert-CiDependency ($env:OS -eq 'Windows_NT') 'the complete native CI gate requires Windows; use ci-fixtures.ps1 for Linux-safe dependency fixtures'
Assert-CiDependency (($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -eq 1) -or $PSVersionTable.PSVersion.ToString() -eq '7.6.6') 'run this gate with Windows PowerShell 5.1 or locked PowerShell 7.6.6'
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
$RunnerToolsRoot = [IO.Path]::GetFullPath($RunnerToolsRoot)
$lock = Get-CiDependencyLock
$commands = Get-CiRunnerCommands $RunnerToolsRoot $lock
# Both fixture hosts resolve the same locked Git/SSH, chezmoi and processor binaries.
$directories = @('git', 'ssh', 'chezmoi', 'powershell', 'dsc', 'winget') | ForEach-Object { Split-Path $commands[$_] -Parent }
$env:PATH = (($directories | Select-Object -Unique) -join [IO.Path]::PathSeparator) + [IO.Path]::PathSeparator + $env:PATH
# DSC's default AppX discovery extension finds WinGet's registered native manifest.
Remove-Item Env:DSC_RESOURCE_PATH -ErrorAction SilentlyContinue
$hostCommand = (Get-Process -Id $PID).Path
$required = @(
  'windows/dev/bootstrap.ps1',
  'windows/dev/format.ps1',
  'windows/dev/tests/formatting.ps1',
  'windows/dev/tests/bootstrap.ps1',
  'windows/dev/tests/hook.ps1',
  'windows/dev/ci-fixtures.ps1',
  'windows/check.ps1',
  'windows/tests/chezmoi-core.ps1',
  'windows/tests/chezmoi-apps.ps1'
)
foreach ($relative in $required) {
  Assert-CiDependency (Test-Path -LiteralPath (Join-Path $RepositoryRoot $relative) -PathType Leaf) "required gate $relative is absent; integrate the native fixture source before running CI"
}
function Invoke-CiScript {
  param([string]$RelativePath, [string[]]$ScriptArguments = @())
  Write-Output "gate: $RelativePath under PowerShell $($PSVersionTable.PSVersion)"
  $arguments = @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $RepositoryRoot $RelativePath)) + $ScriptArguments
  $global:LASTEXITCODE = 0
  & $hostCommand @arguments
  Assert-CiDependency ($LASTEXITCODE -eq 0) "gate $RelativePath exited $LASTEXITCODE"
}
Invoke-CiScript 'windows/dev/bootstrap.ps1' @('-RepositoryRoot', $RepositoryRoot, '-IncludeTestDependencies', '-SkipHook')
Invoke-CiScript 'windows/dev/format.ps1' @('-RepositoryRoot', $RepositoryRoot, '-Check')
foreach ($relative in @('windows/dev/tests/formatting.ps1', 'windows/dev/tests/bootstrap.ps1', 'windows/dev/tests/hook.ps1')) {
  Invoke-CiScript $relative @('-RepositoryRoot', $RepositoryRoot)
}
Invoke-CiScript 'windows/dev/ci-fixtures.ps1'
# check.ps1 owns official schema validation, all native negative fixtures, shipped
# ASTs and the mandatory chezmoi/SSH fixtures with their rendered PowerShell ASTs.
Invoke-CiScript 'windows/check.ps1'
$provenancePath = Join-Path $RepositoryRoot 'windows/schemas/provenance.json'
$provenance = Get-Content -LiteralPath $provenancePath -Raw -Encoding UTF8 | ConvertFrom-Json
$document = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'windows/configuration.winget') -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($type in @($document.resources.type | Sort-Object -Unique)) {
  $expected = $lock.resources.PSObject.Properties[$type]
  Assert-CiDependency ($null -ne $expected) "document type $type is not in the discovered resource lock"
}
foreach ($expected in $lock.resources.PSObject.Properties) {
  $type = $expected.Name
  $schemaRecord = $provenance.resources.PSObject.Properties[$type]
  Assert-CiDependency ($null -ne $schemaRecord -and $schemaRecord.Value -ceq $expected.Value) "resource lock/provenance mismatch for $type"
  $json = Invoke-CiNative $commands['dsc'] @('resource', 'list', $type)
  Assert-CiResourceDiscovery $json $type $expected.Value
}
# This is deliberately show, never validate (public-module warnings) or apply.
$output = Invoke-CiNative $commands['winget'] @('configure', 'show', '--file', (Join-Path $RepositoryRoot 'windows/configuration.winget'), '--disable-interactivity')
Write-Output $output
Write-Output "Native Windows CI passed under PowerShell $($PSVersionTable.PSVersion). Hosted execution proves only test/parse gates, not workstation apply, sessions, enrollment or network acceptance."
