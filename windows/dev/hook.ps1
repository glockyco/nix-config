[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$ToolsRoot
)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
. (Join-Path $PSScriptRoot 'formatting.ps1')
. (Join-Path $PSScriptRoot 'tools.ps1') -RepositoryRoot $RepositoryRoot

function Invoke-SameCheckoutNixGate {
    param([string]$RepositoryRoot)
    $wsl = Get-Command wsl.exe -CommandType Application -ErrorAction SilentlyContinue
    if (-not $wsl) { throw 'Staged .nix files require the declared Korolev NixOS-WSL environment on this exact checkout; install/enable WSL or commit from the Nix environment.' }
    $arguments = @()
    if ($env:NIX_CONFIG_WSL_DISTRIBUTION) { $arguments += @('--distribution', $env:NIX_CONFIG_WSL_DISTRIBUTION) }
    $conversion = Invoke-CapturedProcess -Command $wsl.Source -Arguments ($arguments + @('--exec', 'wslpath', '-a', '-u', $RepositoryRoot)) -WorkingDirectory $RepositoryRoot
    if ($conversion.code -ne 0) { throw "Cannot map native checkout into the declared WSL environment (exit $($conversion.code)): $($conversion.error)" }
    $linuxRoot = $conversion.output.TrimEnd([char]13, [char]10)
    if (-not $linuxRoot.StartsWith('/')) { throw 'Wrong checkout: WSL did not return an absolute native checkout path' }
    $proofName = '.native-nix-gate-' + [Guid]::NewGuid().ToString('N')
    $proofValue = [Guid]::NewGuid().ToString('N')
    $proofPath = Join-Path $RepositoryRoot $proofName
    try {
        [IO.File]::WriteAllText($proofPath, $proofValue, (New-Object Text.UTF8Encoding($false)))
        $result = Invoke-CapturedProcess -Command $wsl.Source -Arguments ($arguments + @('--cd', $linuxRoot, '--exec', 'bash', './windows/dev/nix-gate.sh', $linuxRoot, $proofName, $proofValue)) -WorkingDirectory $RepositoryRoot
        if ($result.output) { Write-Host $result.output }
        if ($result.code -ne 0) { throw "Same-checkout pinned Nix gate failed (exit $($result.code)): $($result.error)" }
    } finally { if (Test-Path -LiteralPath $proofPath) { Remove-Item -LiteralPath $proofPath -Force } }
}

function Invoke-NativeCommitGate {
    param(
        [string]$RepositoryRoot,
        [string]$ToolsRoot,
        [scriptblock]$NixGate = { param($root) Invoke-SameCheckoutNixGate $root },
        [scriptblock]$FormatGate = { param($root, $tools, $paths) $null = Get-NativeTool -Name lefthook -ToolsRoot $tools; Invoke-NativeFormatting -RepositoryRoot $root -ToolsRoot $tools -Paths $paths -Check },
        [scriptblock]$WindowsGate = { param($root) & (Join-Path $root 'windows/check.ps1'); if ($LASTEXITCODE -ne 0) { throw "Windows invariant gate failed (exit $LASTEXITCODE)" } }
    )
    $paths = @(Get-GitFormattingPaths -RepositoryRoot $RepositoryRoot -Staged)
    if (@($paths | Where-Object { $_.EndsWith('.nix', [StringComparison]::Ordinal) }).Count -gt 0) { & $NixGate $RepositoryRoot }
    if (-not $ToolsRoot) { $ToolsRoot = Get-NativeToolsRoot $RepositoryRoot }
    & $FormatGate $RepositoryRoot $ToolsRoot $paths
    & $WindowsGate $RepositoryRoot
}

if ($MyInvocation.InvocationName -ne '.') {
    try { Invoke-NativeCommitGate -RepositoryRoot ([IO.Path]::GetFullPath($RepositoryRoot)) -ToolsRoot $ToolsRoot }
    catch { Write-Error $_; exit 1 }
}
