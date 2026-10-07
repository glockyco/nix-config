[CmdletBinding()]
param(
  [string]$DocumentPath,
  [string[]]$AdditionalScriptPath = @(),
  [switch]$SkipFixtures
)

$ErrorActionPreference = 'Stop'
if (-not $DocumentPath) { $DocumentPath = Join-Path $PSScriptRoot 'configuration.winget' }
try {
  . (Join-Path $PSScriptRoot 'tests/native-contract.ps1')
  . (Join-Path $PSScriptRoot 'tests/admin-paths.ps1')
  try { $document = Get-Content -LiteralPath $DocumentPath -Raw -Encoding UTF8 | ConvertFrom-Json }
  catch { throw "document ${DocumentPath}: $($_.Exception.Message)" }
  $managed = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'managed-applications.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  Test-WindowsDocument $document $managed
  . (Join-Path $PSScriptRoot 'tests/schema.ps1') -DocumentPath $DocumentPath -WindowsRoot $PSScriptRoot
  Invoke-DocumentSchemaCheck $DocumentPath $PSScriptRoot
  foreach ($file in @(Get-ChildItem -LiteralPath $PSScriptRoot -Recurse -File -Filter '*.ps1')) {
    $record = Get-ScriptRecord $file.FullName ([IO.File]::ReadAllText($file.FullName))
    $approved = $file.DirectoryName -eq $PSScriptRoot -and $file.Name -in @('apply-kbdneo.ps1', 'apply-zen-policies.ps1')
    Test-ApprovedScriptRole $record $approved
    if ($approved) { Test-AdministratorScript $record $file.Name }
  }
  foreach ($name in @('apply-kbdneo.ps1', 'apply-zen-policies.ps1')) {
    Assert-Contract (Test-Path -LiteralPath (Join-Path $PSScriptRoot $name) -PathType Leaf) "script ${name}: required fixed Administrator script is missing"
  }
  foreach ($path in $AdditionalScriptPath) {
    Assert-Contract (Test-Path -LiteralPath $path -PathType Leaf) "script ${path}: additional rendered script is missing"
    $record = Get-ScriptRecord $path ([IO.File]::ReadAllText($path))
    Test-ApprovedScriptRole $record
  }
  if (-not $SkipFixtures) {
    . (Join-Path $PSScriptRoot 'tests/fixtures.ps1')
    Invoke-NativeFixtures $document $managed $PSScriptRoot
  }
  Write-Output 'windows/check.ps1: native document invariants and script parsing passed'
} catch {
  [Console]::Error.WriteLine("windows/check.ps1: $($_.Exception.Message)`n$($_.ScriptStackTrace)")
  exit 1
}
