#Requires -Version 7.4
[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$ToolsRoot,
    [string[]]$Paths,
    [switch]$Check
)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
try {
    . (Join-Path $PSScriptRoot 'formatting.ps1')
    $RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
    if (-not $PSBoundParameters.ContainsKey('Paths')) { $Paths = @(Get-GitFormattingPaths $RepositoryRoot) }
        . (Join-Path $PSScriptRoot 'tools.ps1') -RepositoryRoot $RepositoryRoot
        if (-not $ToolsRoot) { $ToolsRoot = Get-NativeToolsRoot $RepositoryRoot }
        Invoke-NativeFormatting -RepositoryRoot $RepositoryRoot -ToolsRoot $ToolsRoot -Paths $Paths -Check:$Check
} catch { Write-Error $_; exit 1 }
