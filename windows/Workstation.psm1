#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Workstation.Settings.ps1')
. (Join-Path $PSScriptRoot 'Workstation.Delivery.ps1')
. (Join-Path $PSScriptRoot 'Workstation.Validation.ps1')

function Invoke-WorkstationNative {
    param([Parameter(Mandatory)][string] $Command, [string[]] $Arguments = @())
    Get-Command -Name $Command -CommandType Application -ErrorAction Stop | Out-Null
    $PSNativeCommandUseErrorActionPreference = $false
    $ErrorActionPreference = 'Continue'
    $global:LASTEXITCODE = 0
    $output = @(& $Command @Arguments 2>&1)
    $code = $LASTEXITCODE
    $stdout = [Collections.Generic.List[string]]::new()
    foreach ($line in $output) {
        if ($line -is [Management.Automation.ErrorRecord]) { Write-Verbose $line.ToString() }
        else { $stdout.Add([string]$line) }
    }
    if ($code -ne 0) { throw "$Command exited $code`: $($output -join [Environment]::NewLine)" }
    return $stdout -join [Environment]::NewLine
}

function Compare-WorkstationVersion {
    param([Parameter(Mandatory)][string] $Actual, [Parameter(Mandatory)][string] $Desired)
    # ImageMagick uses 7.1.2-6. Compare that release component rather than dropping it.
    $versions = foreach ($value in @($Actual, $Desired)) {
        $match = [regex]::Match($value, '^v?(\d+(?:[.-]\d+){1,3})(?:[^\d.-].*)?$')
        if (-not $match.Success) { throw "Cannot compare version '$value'" }
        $parts = @($match.Groups[1].Value -split '[.-]' | ForEach-Object { [int]$_ })
        while ($parts.Count -lt 4) { $parts += 0 }
        [version]::new($parts[0], $parts[1], $parts[2], $parts[3])
    }
    return $versions[0].CompareTo($versions[1])
}

function Get-WorkstationWingetSnapshot {
    param([hashtable] $Data)
    $text = Invoke-WorkstationNative -Command 'winget' -Arguments @('list', '--source', 'winget', '--accept-source-agreements', '--disable-interactivity')
    $text = $text -replace '\x1b\[[0-?]*[ -/]*[@-~]', ''
    if ($text -notmatch '(?m)^-{5,}\s*$') { throw 'WinGet installed snapshot has no recognized table separator' }
    $installed = @{}
    foreach ($resource in $Data.applications) {
        if ($resource.kind -ne 'winget') { continue }
        $pattern = '(?m)(?<!\S)' + [regex]::Escape($resource.id) + '\s+(\S+)'
        $records = [regex]::Matches($text, $pattern, [Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($records.Count -gt 1) { throw "Ambiguous installed records for $($resource.id)" }
        if ($records.Count -eq 1) {
            $installed[$resource.id] = $records[0].Groups[1].Value
            continue
        }
        foreach ($token in [regex]::Matches($text, '(?<!\S)(\S+?)(?:\u2026|\.{3})(?=\s|$)')) {
            if ($resource.id.StartsWith($token.Groups[1].Value, [StringComparison]::OrdinalIgnoreCase)) {
                throw "Truncated installed id for $($resource.id). Widen the WinGet output before accepting parity."
            }
        }
    }
    return $installed
}

function Get-WorkstationApplicationDirectory {
    param([hashtable] $Resource)
    $rootName = if ($Resource.root) { $Resource.root } else { 'LOCALAPPDATA' }
    $root = [Environment]::GetEnvironmentVariable($rootName)
    if (-not $root) { throw "Environment variable $rootName is missing" }
    return Join-Path $root $Resource.directory
}

function Resolve-WorkstationExecutable {
    param([hashtable] $Resource)
    if ($Resource.directory) {
        $path = Join-Path (Get-WorkstationApplicationDirectory -Resource $Resource) $Resource.executable
        if (Test-Path -LiteralPath $path -PathType Leaf) { return $path }
        return $null
    }
    $packageRoot = Join-Path $env:LOCALAPPDATA ('Microsoft\WinGet\Packages\' + $Resource.id + '_Microsoft.Winget.Source_8wekyb3d8bbwe')
    if (Test-Path -LiteralPath $packageRoot -PathType Container) {
        $executables = @(Get-ChildItem -LiteralPath $packageRoot -Recurse -File -Filter $Resource.executable -ErrorAction Stop)
        if ($executables.Count -gt 1) { throw "Ambiguous executable $($Resource.executable) in $packageRoot" }
        if ($executables.Count -eq 1) { return $executables[0].FullName }
    }
    # Nonportable installers may register their executable on PATH. Never assume Links exists.
    if (-not $Resource.installerType -or $Resource.installerType -notin @('zip', 'portable')) {
        $commands = @(Get-Command -Name $Resource.executable -CommandType Application -ErrorAction SilentlyContinue)
        if ($commands.Count -gt 0) { return $commands[0].Source }
    }
    return $null
}

function Get-WorkstationUserPath {
    $state = Get-WorkstationRegistryValue -Path 'HKCU:\Environment' -ValueName 'Path'
    if ($state.Exists) { return [string]$state.Value }
    return ''
}

function Set-WorkstationPersistedUserPath {
    param([string] $Value)
    $state = Get-WorkstationRegistryValue -Path 'HKCU:\Environment' -ValueName 'Path'
    $type = if ($state.Exists) { $state.Type } else { 'ExpandString' }
    if ($type -notin @('String', 'ExpandString')) { throw "User PATH has an unsupported registry type: $type" }
    if (-not $state.KeyExists) { New-Item -Path 'HKCU:\Environment' -Force -ErrorAction Stop | Out-Null }
    New-ItemProperty -LiteralPath 'HKCU:\Environment' -Name 'Path' -Value $Value -PropertyType $type -Force -ErrorAction Stop | Out-Null
    Send-WorkstationEnvironmentNotification
}

function Send-WorkstationEnvironmentNotification {
    # Match the chezmoi Tern PATH owner's process notification convention.
    $native = Get-WorkstationSettingsNativeApi
    $result = [UIntPtr]::Zero
    $null = $native::SendMessageTimeout([IntPtr]0xffff, 0x001a, [UIntPtr]::Zero, 'Environment', 0x0002, 5000, [ref]$result)
}

function ConvertTo-WorkstationPathKey {
    param([string] $Path)
    # WinGet writes entries such as <package>\.\bin, so compare normalized absolute paths.
    $expanded = [Environment]::ExpandEnvironmentVariables($Path)
    try { return [IO.Path]::GetFullPath($expanded).TrimEnd('\') } catch { return $expanded.TrimEnd('\') }
}

function Test-WorkstationUserPath {
    param([string] $Directory)
    $wanted = ConvertTo-WorkstationPathKey $Directory
    $paths = @((Get-WorkstationUserPath) -split ';' | Where-Object { $_ })
    return @($paths | Where-Object { (ConvertTo-WorkstationPathKey $_) -ieq $wanted }).Count -gt 0
}

function Set-WorkstationUserPath {
    param([string] $Directory)
    if (-not (Test-WorkstationUserPath -Directory $Directory)) {
        $current = Get-WorkstationUserPath
        $value = if ($current) { $current.TrimEnd(';') + ';' + $Directory } else { $Directory }
        Set-WorkstationPersistedUserPath -Value $value
    }
    Update-WorkstationProcessPath
}

function Update-WorkstationProcessPath {
    $env:PATH = [Environment]::ExpandEnvironmentVariables(
        [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User'))
}

function Get-WorkstationExecutableVersion {
    param([string] $Executable, [string[]] $Arguments = @('--version'))
    $output = Invoke-WorkstationNative -Command $Executable -Arguments $Arguments
    $match = [regex]::Match($output, '\d+\.\d+(?:\.\d+){0,2}(?:-\d+)?')
    if (-not $match.Success) { throw "Unrecognized executable version: $Executable" }
    return $match.Value
}

function Test-WorkstationWinget {
    param([hashtable] $Resource, [hashtable] $Context)
    if (-not $Context.Installed.ContainsKey($Resource.id)) { return $false }
    if ($Resource.executable) {
        $executable = Resolve-WorkstationExecutable -Resource $Resource
        if (-not $executable) { return $false }
        if ($Resource.versionPolicy -eq 'pinned' -and (Compare-WorkstationVersion -Actual (Get-WorkstationExecutableVersion -Executable $executable) -Desired $Resource.version) -ne 0) { return $false }
        return Test-WorkstationUserPath -Directory (Split-Path $executable -Parent)
    }
    if ($Resource.versionPolicy -eq 'pinned') { return (Compare-WorkstationVersion -Actual $Context.Installed[$Resource.id] -Desired $Resource.version) -eq 0 }
    return $true
}

function Assert-WorkstationVCRuntime {
    $runtime = Get-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64' -ErrorAction SilentlyContinue
    if ($null -eq $runtime -or $runtime.Installed -ne 1) { throw 'The employer-owned Visual C++ x64 runtime is missing. Ask IT rather than installing a competing runtime.' }
}

function Set-WorkstationWinget {
    param([hashtable] $Resource, [hashtable] $Context)
    $installed = $Context.Installed.ContainsKey($Resource.id)
    $needsInstall = -not $installed
    if ($installed -and $Resource.versionPolicy -eq 'pinned') {
        $actual = $Context.Installed[$Resource.id]
        if ($Resource.executable) {
            $executable = Resolve-WorkstationExecutable -Resource $Resource
            if ($executable) { $actual = Get-WorkstationExecutableVersion -Executable $executable }
        }
        $comparison = Compare-WorkstationVersion -Actual $actual -Desired $Resource.version
        if ($comparison -gt 0) { throw "$($Resource.id): newer $actual is installed. Refusing downgrade to $($Resource.version)." }
        $needsInstall = $comparison -lt 0
    }
    if ($needsInstall) {
        if ($Resource.requiresVCRuntime) { Assert-WorkstationVCRuntime }
        $arguments = @('install', '--id', $Resource.id, '--exact', '--source', 'winget', '--scope', $Resource.scope,
            '--architecture', 'x64', '--silent', '--skip-dependencies', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
        if ($Resource.versionPolicy -eq 'pinned') { $arguments += @('--version', $Resource.version) }
        if ($Resource.installerType) { $arguments += @('--installer-type', $Resource.installerType) }
        if ($Resource.installArguments) { $arguments += @('--override', $Resource.installArguments) }
        Invoke-WorkstationNative -Command 'winget' -Arguments $arguments | Out-Null
        $Context.WingetChanged = $true
        Update-WorkstationProcessPath
    }
    if ($Resource.executable) {
        $executable = Resolve-WorkstationExecutable -Resource $Resource
        if (-not $executable) { throw "$($Resource.id): expected executable is missing. Repair the user installation before applying." }
        Set-WorkstationUserPath -Directory (Split-Path $executable -Parent)
    }
}

function Test-WorkstationElevated {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Read-WorkstationData {
    param([string] $DataPath = (Join-Path $PSScriptRoot 'workstation.json'), [string] $SchemaPath = (Join-Path $PSScriptRoot 'workstation.schema.json'))
    $json = Get-Content -LiteralPath $DataPath -Raw -Encoding utf8
    if (-not (Test-Json -Json $json -SchemaFile $SchemaPath -ErrorAction Stop)) { throw "Schema validation failed: $DataPath" }
    $data = ConvertFrom-Json -InputObject $json -AsHashtable
    Assert-WorkstationData -Data $data -ManagedPath (Join-Path $PSScriptRoot 'managed-applications.json')
    return $data
}

function Test-WorkstationApplication {
    param([hashtable] $Resource, [hashtable] $Context)
    switch ($Resource.kind) {
        'winget' { return Test-WorkstationWinget -Resource $Resource -Context $Context }
        'archive' { return Test-WorkstationArchive -Resource $Resource -Context $Context }
        'npm' { return Test-WorkstationNpm -Resource $Resource -Context $Context }
        'font' { return Test-WorkstationFont -Resource $Resource -Context $Context }
        default { throw "Unsupported application kind $($Resource.kind)" }
    }
}

function Set-WorkstationApplication {
    param([hashtable] $Resource, [hashtable] $Context)
    switch ($Resource.kind) {
        'winget' { Set-WorkstationWinget -Resource $Resource -Context $Context }
        'archive' { Set-WorkstationArchive -Resource $Resource -Context $Context }
        'npm' { Set-WorkstationNpm -Resource $Resource -Context $Context }
        'font' { Set-WorkstationFont -Resource $Resource -Context $Context }
        default { throw "Unsupported application kind $($Resource.kind)" }
    }
}

function Invoke-Workstation {
    [CmdletBinding(DefaultParameterSetName = 'DryRun')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'DryRun')][switch] $DryRun,
        [Parameter(Mandatory, ParameterSetName = 'Apply')][switch] $Apply,
        [string] $DataPath = (Join-Path $PSScriptRoot 'workstation.json'),
        [string] $SchemaPath = (Join-Path $PSScriptRoot 'workstation.schema.json')
    )
    try {
        if (-not $IsWindows) { throw 'The workstation engine requires Windows' }
        if (Test-WorkstationElevated) { throw 'Run the workstation engine as the standard user, never Administrator' }
        $data = Read-WorkstationData -DataPath $DataPath -SchemaPath $SchemaPath
        $context = @{ Data = $data; Installed = Get-WorkstationWingetSnapshot -Data $data; WingetChanged = $false }
        $drift = $false
        $changedWinget = [Collections.Generic.List[hashtable]]::new()
        foreach ($resource in $data.applications) {
            if (Test-WorkstationApplication -Resource $resource -Context $context) { Write-Host "desired: $($resource.name)"; continue }
            $drift = $true
            Write-Host "drift: $($resource.name)"
            if ($DryRun) { continue }
            Set-WorkstationApplication -Resource $resource -Context $context
            if ($resource.kind -eq 'winget' -and $context.WingetChanged) { $changedWinget.Add($resource); continue }
            if (-not (Test-WorkstationApplication -Resource $resource -Context $context)) { throw "Postcondition failed: $($resource.name)" }
            Write-Host "applied: $($resource.name)"
        }
        if ($context.WingetChanged) {
            $context.Installed = Get-WorkstationWingetSnapshot -Data $data
            foreach ($resource in $changedWinget) {
                if (-not (Test-WorkstationWinget -Resource $resource -Context $context)) { throw "Postcondition failed: $($resource.name)" }
                Write-Host "applied: $($resource.name)"
            }
        }
        foreach ($resource in $data.settings) {
            if (Test-WorkstationSetting -Resource $resource) { Write-Host "desired: $($resource.name)"; continue }
            $drift = $true
            Write-Host "drift: $($resource.name)"
            if ($DryRun) { continue }
            Set-WorkstationSetting -Resource $resource
            if (-not (Test-WorkstationSetting -Resource $resource)) { throw "Postcondition failed: $($resource.name)" }
            Write-Host "applied: $($resource.name)"
        }
        if ($DryRun -and $drift) { return 1 }
        return 0
    } catch {
        Write-Host "error: $($_.Exception.Message)"
        return 2
    }
}

Export-ModuleMember -Function Read-WorkstationData, Invoke-Workstation
