[CmdletBinding()]
param([string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent }
. (Join-Path $RepositoryRoot 'windows/dev/formatting.ps1')
function Assert-Fixture { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw $Message } }
$fixtures = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'formatting-fixtures.json') -Raw | ConvertFrom-Json
$policy = Get-FormattingPolicy $RepositoryRoot
$plan = @(Get-FormattingPlan -Policy $policy -Paths $fixtures.paths)
foreach ($path in $fixtures.paths) {
    $property = $fixtures.selected.PSObject.Properties[$path]
    $expected = @()
    if ($property) { $expected = @($property.Value) }
    $actual = @($plan | Where-Object { $_.path -ceq $path } | ForEach-Object { $_.name })
    Assert-Fixture (($actual -join '|') -ceq ($expected -join '|')) "Selection/order parity failed for $path"
}
Assert-Fixture (@($plan | Where-Object name -eq 'prettier').Count -eq 1) 'Prettier escaped DNS-only scope'
# Synthetic NUL records exercise names Windows cannot create, including LF.
function Invoke-CapturedProcess { [pscustomobject]@{ code = 0; output = "space name.py`0line`nbreak.py`0"; error = '' } }
$paths = @(Get-GitFormattingPaths -RepositoryRoot $RepositoryRoot -Staged)
Assert-Fixture ($paths.Count -eq 2 -and $paths[0] -ceq 'space name.py' -and $paths[1] -ceq "line`nbreak.py") 'NUL filename enumeration lost whitespace'
$work = Join-Path ([IO.Path]::GetTempPath()) ('formatter-batch-' + [guid]::NewGuid().ToString('N'))
try {
    New-Item -ItemType Directory -Path $work | Out-Null
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'formatting.json') -Destination $work
    $files = @('one space.md', 'two.md', 'one.py', 'two.py')
    foreach ($file in $files) { [IO.File]::WriteAllText((Join-Path $work $file), 'unchanged') }
    $script:batchLog = Join-Path $work 'invocations.jsonl'
    $script:batchHost = (Get-Process -Id $PID).Path
    $script:batchFormatter = Join-Path $work 'formatter.ps1'
    [IO.File]::WriteAllText($script:batchFormatter, @'
param([string]$Log, [string]$Name)
@{ name = $Name; arguments = @($args) } | ConvertTo-Json -Compress | Add-Content -LiteralPath $Log
exit 0
'@)
    function Get-NativeTool {
        param($Name, $ToolsRoot)
        [pscustomobject]@{ command = $script:batchHost; prefixArguments = @('-NoProfile', '-File', $script:batchFormatter, '-Log', $script:batchLog, '-Name', $Name) }
    }
    Invoke-NativeFormatting -RepositoryRoot $work -ToolsRoot $work -Paths $files -Check
    $calls = @(Get-Content -LiteralPath $script:batchLog | ForEach-Object { $_ | ConvertFrom-Json })
    Assert-Fixture ($calls.Count -eq 3) 'Formatter dispatch did not batch paths by declaration'
    foreach ($call in $calls) {
        $paths = @($call.arguments | Where-Object { $_ -like "$($work.Replace('\', '/'))/*" })
        Assert-Fixture ($paths.Count -eq 2) "Formatter $($call.name) did not receive both selected files"
    }
    Assert-Fixture ($calls[1].name -eq 'ruff-check' -and $calls[2].name -eq 'ruff-format') 'Batching changed Ruff priority order'
    Write-Host 'PASS formatter batching preserves selected paths, spaced filenames and priority'
} finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
}
Write-Host 'PASS native selection/order/exclusions and NUL filename fixtures'
