#Requires -Version 7.0
[CmdletBinding(DefaultParameterSetName = 'DryRun')]
param(
    [Parameter(Mandatory, ParameterSetName = 'DryRun')][switch] $DryRun,
    [Parameter(Mandatory, ParameterSetName = 'Apply')][switch] $Apply,
    [string] $DataPath = (Join-Path $PSScriptRoot 'workstation.json'),
    [string] $SchemaPath = (Join-Path $PSScriptRoot 'workstation.schema.json')
)

$ErrorActionPreference = 'Stop'
try {
    Import-Module (Join-Path $PSScriptRoot 'Workstation.psm1') -Force
    $arguments = @{ DataPath = $DataPath; SchemaPath = $SchemaPath }
    if ($DryRun) { $arguments.DryRun = $true } else { $arguments.Apply = $true }
    exit (Invoke-Workstation @arguments)
} catch {
    Write-Host "error: $($_.Exception.Message)"
    exit 2
}
