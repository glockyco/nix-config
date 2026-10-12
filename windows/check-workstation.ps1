#Requires -Version 7.4
[CmdletBinding()]
param(
    [string]$DataPath = (Join-Path $PSScriptRoot 'workstation.json'),
    [string]$SchemaPath = (Join-Path $PSScriptRoot 'workstation.schema.json'),
    [string]$ModuleRoot,
    [switch]$StaticOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repositoryRoot = Split-Path $PSScriptRoot -Parent

function Invoke-WorkstationGate {
    param([string]$Name, [scriptblock]$Action)
    $timer = [Diagnostics.Stopwatch]::StartNew()
    try { & $Action }
    finally { Write-Host ('timing: gate {0} {1:F3}s' -f $Name, $timer.Elapsed.TotalSeconds) }
}

try {
    . (Join-Path $PSScriptRoot 'dev/engine-dependencies.ps1') -RepositoryRoot $repositoryRoot -ModuleRoot $ModuleRoot
    $ModuleRoot = Get-EngineModuleRoot -RepositoryRoot $repositoryRoot -ModuleRoot $ModuleRoot
    Import-EngineDependencies -ModuleRoot $ModuleRoot

    $enginePaths = @(
        'Workstation.psm1', 'Workstation.Settings.ps1', 'Workstation.Delivery.ps1', 'Workstation.Validation.ps1',
        'workstation.ps1', 'bootstrap.ps1', 'check-workstation.ps1', 'PSScriptAnalyzerSettings.psd1'
    ) | ForEach-Object { Join-Path $PSScriptRoot $_ }
    $developmentPaths = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'dev') -File -Filter '*.ps1' | Select-Object -ExpandProperty FullName)
    $testPaths = @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'tests') -File -Filter '*.Tests.ps1' | Select-Object -ExpandProperty FullName)
    $administratorPaths = @('apply-kbdneo.ps1', 'apply-zen-policies.ps1') | ForEach-Object { Join-Path $PSScriptRoot $_ }

    Invoke-WorkstationGate 'PowerShell parser' {
        foreach ($path in $enginePaths + $developmentPaths + $testPaths + $administratorPaths) {
            if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing required PowerShell source '$path'." }
            $tokens = $null
            $parseErrors = $null
            $null = [Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$parseErrors)
            if ($parseErrors.Count -gt 0) {
                throw "${path}: $(@($parseErrors | ForEach-Object { 'line {0}: {1}' -f $_.Extent.StartLineNumber, $_.Message }) -join '`n')"
            }
        }
    }

    Invoke-WorkstationGate 'JSON schema and ownership invariants' {
        Import-Module (Join-Path $PSScriptRoot 'Workstation.psm1') -Force -ErrorAction Stop
        # This validates declarations only. Never invoke the engine against this host.
        $null = Read-WorkstationData -DataPath $DataPath -SchemaPath $SchemaPath
    }

    Invoke-WorkstationGate 'Administrator ownership invariants' {
        # Reuse the surviving fixed-script AST boundary checks without executing either script.
        . (Join-Path $PSScriptRoot 'tests/native-contract.ps1')
        . (Join-Path $PSScriptRoot 'tests/admin-paths.ps1')
        foreach ($path in $administratorPaths) {
            $name = Split-Path $path -Leaf
            $record = Get-ScriptRecord -Name $name -Source ([IO.File]::ReadAllText($path))
            Test-AdministratorScript -Record $record -Name $name
        }
    }

    Invoke-WorkstationGate 'PSScriptAnalyzer' {
        $findings = @($enginePaths + (Join-Path $PSScriptRoot 'dev/engine-dependencies.ps1') | ForEach-Object {
            Invoke-ScriptAnalyzer -Path $_ -Settings (Join-Path $PSScriptRoot 'PSScriptAnalyzerSettings.psd1') -Severity Error, Warning
        })
        if ($findings.Count -gt 0) {
            $findings | Format-Table ScriptName, Line, RuleName, Message -AutoSize | Out-Host
            throw "PSScriptAnalyzer reported $($findings.Count) findings."
        }
    }

    if (-not $StaticOnly) {
        Invoke-WorkstationGate 'Pester mocked engine behaviors' {
            if ($testPaths.Count -eq 0) { throw 'Missing required windows/tests/*.Tests.ps1 behavior tests.' }
            $configuration = New-PesterConfiguration
            $configuration.Run.Path = $testPaths
            $configuration.Run.PassThru = $true
            $configuration.Output.Verbosity = 'Detailed'
            $result = Invoke-Pester -Configuration $configuration
            if ($result.TotalCount -eq 0 -or $result.FailedCount -gt 0 -or $result.SkippedCount -gt 0 -or $result.NotRunCount -gt 0 -or $result.Result -ne 'Passed') {
                throw "Pester did not complete all required behaviors: result=$($result.Result), total=$($result.TotalCount), failed=$($result.FailedCount), skipped=$($result.SkippedCount), notRun=$($result.NotRunCount)."
            }
        }
    }
    Write-Output 'Workstation static/mock checks passed. This is not live workstation acceptance.'
} catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
