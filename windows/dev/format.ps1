[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$ToolsRoot,
    [string[]]$Paths,
    [switch]$Check,
    [switch]$Plan,
    [switch]$IncludeNix
)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
try {
    . (Join-Path $PSScriptRoot 'formatting.ps1')
    $RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
    if (-not $PSBoundParameters.ContainsKey('Paths')) { $Paths = @(Get-GitFormattingPaths $RepositoryRoot) }
    if ($Plan) {
        $entries = @(Get-FormattingPlan -Policy (Get-FormattingPolicy $RepositoryRoot) -Paths $Paths -IncludeNix:$IncludeNix)
        ConvertTo-Json -InputObject $entries -Depth 8
    } else {
        . (Join-Path $PSScriptRoot 'tools.ps1') -RepositoryRoot $RepositoryRoot
        if (-not $ToolsRoot) { $ToolsRoot = Get-NativeToolsRoot $RepositoryRoot }
        Invoke-NativeFormatting -RepositoryRoot $RepositoryRoot -ToolsRoot $ToolsRoot -Paths $Paths -Check:$Check
    }
} catch { Write-Error $_; exit 1 }
