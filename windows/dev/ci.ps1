#Requires -Version 7.4
[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$ArchiveCacheRoot,
    [string]$ModuleRoot,
    [switch]$SkipBootstrap
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
$RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
$hostCommand = (Get-Process -Id $PID).Path

function Invoke-CiGate {
    param([string]$Name, [scriptblock]$Action)
    Write-Host "gate: $Name under PowerShell $($PSVersionTable.PSVersion)"
    $timer = [Diagnostics.Stopwatch]::StartNew()
    try { & $Action }
    finally { Write-Host ('timing: gate {0} PowerShell {1} {2:F3}s' -f $Name, $PSVersionTable.PSVersion, $timer.Elapsed.TotalSeconds) }
}

function Invoke-CiScript {
    param([string]$RelativePath, [string[]]$ScriptArguments = @())
    $path = Join-Path $RepositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing required gate '$RelativePath'." }
    Invoke-CiGate $RelativePath {
        $global:LASTEXITCODE = 0
        & $hostCommand -NoProfile -NonInteractive -File $path @ScriptArguments
        if ($LASTEXITCODE -ne 0) { throw "Gate '$RelativePath' exited $LASTEXITCODE." }
    }
}

try {
    if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitProcess -or $PSVersionTable.PSEdition -ne 'Core') {
        throw 'The complete Windows CI gate requires 64-bit PowerShell 7.4 or later on Windows.'
    }
    . (Join-Path $PSScriptRoot 'tools.ps1') -RepositoryRoot $RepositoryRoot
    . (Join-Path $PSScriptRoot 'engine-dependencies.ps1') -RepositoryRoot $RepositoryRoot -ModuleRoot $ModuleRoot
    $toolsRoot = Get-NativeToolsRoot -RepositoryRoot $RepositoryRoot
    $ModuleRoot = Get-EngineModuleRoot -RepositoryRoot $RepositoryRoot -ModuleRoot $ModuleRoot
    if (-not $ArchiveCacheRoot) { $ArchiveCacheRoot = Join-Path (Split-Path $toolsRoot -Parent) 'native-dev-archives' }
    $ArchiveCacheRoot = [IO.Path]::GetFullPath($ArchiveCacheRoot)

    if (-not $SkipBootstrap) {
        Invoke-CiScript 'windows/dev/bootstrap.ps1' @('-RepositoryRoot', $RepositoryRoot, '-ArchiveCacheRoot', $ArchiveCacheRoot, '-IncludeTestDependencies', '-SkipHook')
        Invoke-CiScript 'windows/dev/engine-dependencies.ps1' @('-RepositoryRoot', $RepositoryRoot, '-ModuleRoot', $ModuleRoot)
    }
    Invoke-CiGate 'Locked local dependency validation' {
        foreach ($definition in (Get-NativeDependencies).tools) { $null = Get-NativeTool -Name $definition.id -ToolsRoot $toolsRoot }
        Import-EngineDependencies -ModuleRoot $ModuleRoot
        $chezmoi = Get-NativeTool -Name chezmoi -ToolsRoot $toolsRoot
        $env:PATH = ((Split-Path $chezmoi.command -Parent), (Split-Path $hostCommand -Parent), $env:PATH) -join [IO.Path]::PathSeparator
        foreach ($command in @('git', 'ssh')) {
            $application = Get-Command $command -CommandType Application -ErrorAction Stop | Select-Object -First 1
            $arguments = if ($command -eq 'git') { @('--version') } else { @('-V') }
            $result = Invoke-NativeProcess -Command $application.Source -Arguments $arguments
            if ($result.ExitCode -ne 0) { throw "$command version probe exited $($result.ExitCode): $($result.Output)" }
            Write-Host $result.Output
        }
    }

    # The engine gate reads declarations and uses Pester mocks. It never applies.
    Invoke-CiScript 'windows/check-workstation.ps1' @('-ModuleRoot', $ModuleRoot)
    foreach ($relative in @(
        'windows/dev/tests/formatting.ps1',
        'windows/dev/tests/bootstrap.ps1',
        'windows/dev/tests/contract-parsing.ps1',
        'windows/dev/tests/hook.ps1',
        'windows/tests/chezmoi-core.ps1',
        'windows/tests/chezmoi-apps.ps1',
        'windows/tests/archive-regressions.ps1'
    )) {
        Invoke-CiScript $relative @('-RepositoryRoot', $RepositoryRoot)
    }
    # Chezmoi fixtures include checkout and app regressions, rendered-template
    # ASTs and a dedicated fake engine.
    Invoke-CiScript 'windows/dev/tests/native-smoke.ps1' @('-RepositoryRoot', $RepositoryRoot, '-ArchiveCacheRoot', $ArchiveCacheRoot)
    Write-Output 'Windows static, mocked engine and isolated native/chezmoi fixture checks passed. This is not live workstation acceptance.'
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
