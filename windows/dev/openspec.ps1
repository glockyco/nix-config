[CmdletBinding()]
param([string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }

# The gate uses the OpenSpec that the workstation declaration pins, never another
# CLI on PATH, so local results match the reusable CI workflow's pinned version.
function Get-NativeOpenSpec {
    param([string]$RepositoryRoot, [string]$LocalAppData = $env:LOCALAPPDATA)
    $declaration = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'windows/workstation.json') -Raw | ConvertFrom-Json
    $application = @($declaration.applications | Where-Object { @($_.roles) -contains 'openspec' })
    if ($application.Count -ne 1) { throw 'windows/workstation.json must declare exactly one application with the openspec role.' }
    [pscustomobject]@{
        command = Join-Path $LocalAppData (Join-Path $application[0].directory 'node_modules\.bin\openspec.cmd')
        prefixArguments = [string[]]@()
        version = [string]$application[0].version
    }
}

function Invoke-NativeOpenSpecGate {
    param([string]$RepositoryRoot, [pscustomobject]$Tool)
    if (-not $Tool) { $Tool = Get-NativeOpenSpec -RepositoryRoot $RepositoryRoot }
    $repair = 'Run chezmoi apply to install the declared version.'
    if (-not (Test-Path -LiteralPath $Tool.command -PathType Leaf)) { throw "OpenSpec $($Tool.version) is missing at $($Tool.command). $repair" }
    $previousTelemetry = $env:OPENSPEC_TELEMETRY
    $env:OPENSPEC_TELEMETRY = '0'
    Push-Location -LiteralPath $RepositoryRoot
    try {
        $version = (& $Tool.command @($Tool.prefixArguments + '--version') 2>&1 | Out-String).Trim()
        if ($LASTEXITCODE -ne 0 -or $version -cne $Tool.version) { throw "OpenSpec at $($Tool.command) reports '$version', but windows/workstation.json pins $($Tool.version). $repair" }
        $help = & $Tool.command @($Tool.prefixArguments + @('validate', '--help')) 2>&1 | Out-String
        if ($LASTEXITCODE -ne 0 -or $help -notmatch '--archived') { throw 'OpenSpec cannot validate archived changes with validate --archived.' }
        foreach ($scope in '--all', '--archived') {
            & $Tool.command @($Tool.prefixArguments + @('validate', $scope, '--strict', '--no-interactive'))
            if ($LASTEXITCODE -ne 0) { throw "openspec validate $scope --strict failed (exit $LASTEXITCODE)." }
        }
    } finally {
        Pop-Location
        $env:OPENSPEC_TELEMETRY = $previousTelemetry
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try { Invoke-NativeOpenSpecGate -RepositoryRoot ([IO.Path]::GetFullPath($RepositoryRoot)) }
    catch { Write-Error $_; exit 1 }
}
