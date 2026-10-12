[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$ToolsRoot
)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
. (Join-Path $PSScriptRoot 'formatting.ps1')
. (Join-Path $PSScriptRoot 'tools.ps1') -RepositoryRoot $RepositoryRoot

function Invoke-NativeCommitGate {
    param(
        [string]$RepositoryRoot,
        [string]$ToolsRoot,
        [scriptblock]$FormatGate = { param($root, $tools, $paths) $null = Get-NativeTool -Name lefthook -ToolsRoot $tools; Invoke-NativeFormatting -RepositoryRoot $root -ToolsRoot $tools -Paths $paths -Check },
        [scriptblock]$WindowsGate = {
            param($root)
            # The checker runs in a fresh PowerShell 7 host. No helper scope leaks.
            $hostCommand = (Get-Command pwsh -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
            & $hostCommand -NoProfile -NonInteractive -File (Join-Path $root 'windows/check-workstation.ps1') -StaticOnly
            if ($LASTEXITCODE -ne 0) { throw "Workstation static gate failed (exit $LASTEXITCODE)" }
        }
    )
    $paths = @(Get-GitFormattingPaths -RepositoryRoot $RepositoryRoot -Staged)
    $nixPaths = @($paths | Where-Object { $_.EndsWith('.nix', [StringComparison]::Ordinal) })
    # Windows has no Nix. CI's Nix formatting check is the gate for these files.
    if ($nixPaths.Count -gt 0) { Write-Host "Nix files are checked by CI, not this hook: $($nixPaths -join ', ')" }
    if (-not $ToolsRoot) { $ToolsRoot = Get-NativeToolsRoot $RepositoryRoot }
    & $FormatGate $RepositoryRoot $ToolsRoot $paths
    & $WindowsGate $RepositoryRoot
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        if ($PSVersionTable.PSVersion -lt [version]'7.4') { throw 'Native hooks require PowerShell 7.4 or later. Run windows/bootstrap.ps1.' }
        Invoke-NativeCommitGate -RepositoryRoot ([IO.Path]::GetFullPath($RepositoryRoot)) -ToolsRoot $ToolsRoot
    }
    catch { Write-Error $_; exit 1 }
}
