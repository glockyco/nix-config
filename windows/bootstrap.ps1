#Requires -Version 5.1
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-PrerequisiteProcess {
    param([string]$Command, [string[]]$Arguments)
    $savedPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $Command @Arguments 2>&1)
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $savedPreference }
    if ($code -ne 0) { throw "$Command exited ${code}: $($output -join "`n")" }
}

function Resolve-PrerequisiteExecutable {
    param([string]$Id, [string[]]$RelativePaths, [string]$Executable)
    foreach ($relative in $RelativePaths) {
        $path = Join-Path $env:LOCALAPPDATA $relative
        if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
    }
    $root = Join-Path $env:LOCALAPPDATA ('Microsoft\WinGet\Packages\' + $Id + '_Microsoft.Winget.Source_8wekyb3d8bbwe')
    if (Test-Path -LiteralPath $root -PathType Container) {
        $executables = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter $Executable -ErrorAction Stop)
        if ($executables.Count -gt 1) { throw "Ambiguous user installation for ${Id}: $($executables.FullName -join ', ')" }
        if ($executables.Count -eq 1) { return $executables[0].FullName }
    }
    if ($Id -eq 'Microsoft.PowerShell') {
        $packages = @(Get-AppxPackage -Name Microsoft.PowerShell -ErrorAction Stop)
        if ($packages.Count -gt 1) { throw 'Ambiguous registered user PowerShell package' }
        if ($packages.Count -eq 1) {
            $path = Join-Path $packages[0].InstallLocation $Executable
            if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
        }
    }
    return $null
}

function Test-PrerequisiteElevated {
    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Invoke-PrerequisiteHandoff {
    param([string] $Command)
    & $Command -NoProfile
    if ($LASTEXITCODE -ne 0) { throw "PowerShell 7 exited $LASTEXITCODE." }
}

function Invoke-PrerequisiteBootstrap {
    if ($env:OS -ne 'Windows_NT' -or -not [Environment]::Is64BitProcess) { throw 'Bootstrap requires Windows x64 in a standard-user shell.' }
    if (Test-PrerequisiteElevated) { throw 'Run bootstrap as the standard user, not Administrator.' }
    $prerequisites = @(
        @{ id = 'Microsoft.PowerShell'; paths = @('Programs\PowerShell\7\pwsh.exe'); executable = 'pwsh.exe'; installerType = 'msix' },
        @{ id = 'Git.Git'; paths = @('Programs\Git\cmd\git.exe'); executable = 'git.exe'; installerType = $null },
        @{ id = 'twpayne.chezmoi'; paths = @(); executable = 'chezmoi.exe'; installerType = 'zip' }
    )
    $commands = @{}
    foreach ($prerequisite in $prerequisites) {
        $command = Resolve-PrerequisiteExecutable -Id $prerequisite.id -RelativePaths $prerequisite.paths -Executable $prerequisite.executable
        if (-not $command) {
            $arguments = @(
                'install', '--id', $prerequisite.id, '--exact', '--source', 'winget', '--scope', 'user', '--architecture', 'x64',
                '--accept-source-agreements', '--accept-package-agreements', '--disable-interactivity', '--skip-dependencies'
            )
            if ($prerequisite.installerType) { $arguments += @('--installer-type', $prerequisite.installerType) }
            Invoke-PrerequisiteProcess -Command 'winget.exe' -Arguments $arguments
            $command = Resolve-PrerequisiteExecutable -Id $prerequisite.id -RelativePaths $prerequisite.paths -Executable $prerequisite.executable
            if (-not $command) { throw "Cannot resolve the user installation of $($prerequisite.id). No machine-scope fallback is allowed." }
        }
        $commands[$prerequisite.id] = $command
    }
    $directories = @($commands.Values | ForEach-Object { Split-Path $_ -Parent } | Select-Object -Unique)
    $env:PATH = ($directories -join [IO.Path]::PathSeparator) + [IO.Path]::PathSeparator + $env:PATH
    Write-Output 'Prerequisites are ready. Opening PowerShell 7 with Git and chezmoi available. No workstation or chezmoi apply runs.'
    Invoke-PrerequisiteHandoff -Command $commands['Microsoft.PowerShell']
}

if ($MyInvocation.InvocationName -ne '.') {
    try { Invoke-PrerequisiteBootstrap }
    catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
}
