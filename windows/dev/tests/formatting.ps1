[CmdletBinding()]
param([string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent }
. (Join-Path $RepositoryRoot 'windows/dev/formatting.ps1')
function Assert-Fixture { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw $Message } }
$fixtures = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'formatting-fixtures.json') -Raw | ConvertFrom-Json
$policy = Get-FormattingPolicy $RepositoryRoot
$plan = @(Get-FormattingPlan -Policy $policy -Paths $fixtures.paths -IncludeNix)
foreach ($path in $fixtures.paths) {
    $property = $fixtures.selected.PSObject.Properties[$path]
    $expected = @()
    if ($property) { $expected = @($property.Value) }
    $actual = @($plan | Where-Object { $_.path -ceq $path } | ForEach-Object { $_.name })
    Assert-Fixture (($actual -join '|') -ceq ($expected -join '|')) "Selection/order parity failed for $path"
}
foreach ($entry in $plan) {
    $expected = @($fixtures.options.PSObject.Properties[$entry.name].Value)
    Assert-Fixture (($entry.options -join '|') -ceq ($expected -join '|')) "Option parity failed: $($entry.name)"
    $plugins = $fixtures.plugins.PSObject.Properties[$entry.name]
    if ($plugins) { Assert-Fixture (($entry.plugins -join '|') -ceq ($plugins.Value -join '|')) "Plugin parity failed: $($entry.name)" }
    $configuration = $fixtures.configuration.PSObject.Properties[$entry.name]
    if ($configuration) { Assert-Fixture (($entry.configuration | ConvertTo-Json -Depth 10 -Compress) -ceq ($configuration.Value | ConvertTo-Json -Depth 10 -Compress)) "Configuration parity failed: $($entry.name)" }
}
$native = @(Get-FormattingPlan -Policy $policy -Paths $fixtures.paths)
Assert-Fixture (@($native | Where-Object name -eq 'nixfmt').Count -eq 0) 'Native adapter attempted nixfmt'
Assert-Fixture (@($native | Where-Object name -eq 'prettier').Count -eq 1) 'Prettier escaped DNS-only scope'
# Synthetic NUL records exercise names Windows cannot create, including LF.
function Invoke-CapturedProcess { [pscustomobject]@{ code = 0; output = "space name.py`0line`nbreak.py`0"; error = '' } }
$paths = @(Get-GitFormattingPaths -RepositoryRoot $RepositoryRoot -Staged)
Assert-Fixture ($paths.Count -eq 2 -and $paths[0] -ceq 'space name.py' -and $paths[1] -ceq "line`nbreak.py") 'NUL filename enumeration lost whitespace'
Write-Host 'PASS native selection/options/plugins/order/exclusions and NUL filename fixtures'
