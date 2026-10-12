#Requires -Version 7.4
[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent),
    [string]$ModuleRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:EngineDependencies = @(
    @{ Name = 'Pester'; Version = '5.7.1' },
    @{ Name = 'PSScriptAnalyzer'; Version = '1.24.0' }
)

function Get-EngineModuleRoot {
    param([string]$RepositoryRoot, [string]$ModuleRoot)
    if ($ModuleRoot) { return [IO.Path]::GetFullPath($ModuleRoot) }
    . (Join-Path $PSScriptRoot 'tools.ps1') -RepositoryRoot $RepositoryRoot
    Join-Path (Split-Path (Get-NativeToolsRoot -RepositoryRoot $RepositoryRoot) -Parent) 'engine-modules'
}

function Get-EngineDependencyManifest {
    param([hashtable]$Dependency, [string]$ModuleRoot)
    Join-Path $ModuleRoot "$($Dependency.Name)/$($Dependency.Version)/$($Dependency.Name).psd1"
}

function Import-EngineDependencies {
    param([string]$ModuleRoot)
    foreach ($dependency in $script:EngineDependencies) {
        $manifest = Get-EngineDependencyManifest -Dependency $dependency -ModuleRoot $ModuleRoot
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
            throw "Missing $($dependency.Name) $($dependency.Version). Run pwsh -NoProfile -NonInteractive -File windows/dev/engine-dependencies.ps1 -ModuleRoot '$ModuleRoot'."
        }
        $metadata = Test-ModuleManifest -Path $manifest -ErrorAction Stop
        if ($metadata.Version -ne [version]$dependency.Version) { throw "Incorrect module version at '$manifest'." }
        Import-Module -Name $manifest -Force -ErrorAction Stop
    }
}

function Install-EngineDependencies {
    param([string]$ModuleRoot)
    Import-Module Microsoft.PowerShell.PSResourceGet -ErrorAction Stop
    $null = New-Item -ItemType Directory -Path $ModuleRoot -Force
    foreach ($dependency in $script:EngineDependencies) {
        $manifest = Get-EngineDependencyManifest -Dependency $dependency -ModuleRoot $ModuleRoot
        if (-not (Test-Path -LiteralPath $manifest -PathType Leaf)) {
            Save-PSResource -Name $dependency.Name -Version $dependency.Version -Path $ModuleRoot -Repository PSGallery -TrustRepository -ErrorAction Stop
        }
    }
    Import-EngineDependencies -ModuleRoot $ModuleRoot
    Write-Output "Pinned engine test modules are ready at $ModuleRoot"
}

if ($MyInvocation.InvocationName -ne '.') {
    try {
        $ModuleRoot = Get-EngineModuleRoot -RepositoryRoot $RepositoryRoot -ModuleRoot $ModuleRoot
        Install-EngineDependencies -ModuleRoot $ModuleRoot
    } catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
}
