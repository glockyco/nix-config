[CmdletBinding()]
param(
    [string]$HookName,
    [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
$script:NativeLockPath = Join-Path $PSScriptRoot 'dependencies.lock.json'

function Invoke-NativeProcess {
    param([string]$Command, [string[]]$Arguments)
    # PowerShell 5.1 can treat native stderr as an error record; the exit code is authoritative.
    $savedPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = @(& $Command @Arguments 2>&1)
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $savedPreference }
    [PSCustomObject]@{ ExitCode = $code; Output = (($output | ForEach-Object { "$_" }) -join "`n").Trim() }
}

function Get-NativeDependencies {
    $lock = Get-Content -LiteralPath $script:NativeLockPath -Raw | ConvertFrom-Json
    if ($lock.schemaVersion -ne 1 -or $lock.platform -ne 'windows-x64') {
        throw 'Unsupported native dependency lock; review windows/dev/dependencies.lock.json.'
    }
    $lock
}

function Get-NativeToolsRoot {
    param([string]$RepositoryRoot)
    $result = Invoke-NativeProcess -Command 'git' -Arguments @('-C', $RepositoryRoot, 'rev-parse', '--git-path', 'native-dev')
    if ($result.ExitCode -ne 0) { throw "Cannot resolve native tool directory: git exit $($result.ExitCode): $($result.Output)" }
    $path = $result.Output
    if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $RepositoryRoot $path }
    [IO.Path]::GetFullPath($path)
}

function Resolve-NativeLockedPath {
    param([string]$ToolsRoot, [string]$RelativePath)
    $root = [IO.Path]::GetFullPath($ToolsRoot).TrimEnd([IO.Path]::DirectorySeparatorChar, [IO.Path]::AltDirectorySeparatorChar)
    $path = [IO.Path]::GetFullPath((Join-Path $root $RelativePath))
    if (-not $path.StartsWith($root + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Native lock path escapes its tool directory: $RelativePath"
    }
    $path
}

function Get-NativeTool {
    param([Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][string]$ToolsRoot)
    $diagnostic = 'Run powershell.exe -NoProfile -ExecutionPolicy Bypass -File windows/dev/bootstrap.ps1 from this native checkout (add -IncludeTestDependencies for test dependencies).'
    try {
        $lock = Get-NativeDependencies
        $manifestPath = Join-Path $ToolsRoot 'tools.json'
        if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'Missing native tools.json.' }
        $manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
        $digest = (Get-FileHash -LiteralPath $script:NativeLockPath -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($manifest.schemaVersion -ne 1 -or $manifest.lockSha256 -cne $digest) { throw 'Native tools.json does not match the repository dependency lock.' }
        $expected = @($lock.tools | Where-Object { -not $_.testOnly -or $manifest.includeTestDependencies })
        if (@($manifest.tools).Count -ne $expected.Count) { throw 'Native tools.json has a different tool set than the lock.' }
        foreach ($entry in $expected) {
            $record = @($manifest.tools | Where-Object { $_.id -ceq $entry.id })
            if ($record.Count -ne 1 -or ($record[0] | ConvertTo-Json -Depth 10 -Compress) -cne ($entry | ConvertTo-Json -Depth 10 -Compress)) {
                throw "Native tools.json has an unlocked record for $($entry.id)."
            }
        }
        $matches = @($expected | Where-Object { $_.id -ceq $Name })
        if ($matches.Count -ne 1) { throw "No locked native tool named $Name." }
        $definition = $matches[0]
        $command = Resolve-NativeLockedPath -ToolsRoot $ToolsRoot -RelativePath $definition.command
        foreach ($relative in @($definition.command) + @($definition.requiredPaths)) {
            $required = Resolve-NativeLockedPath -ToolsRoot $ToolsRoot -RelativePath $relative
            if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing locked artifact $relative." }
        }
        $prefix = @($definition.prefixArguments | ForEach-Object {
            if ($Name -eq 'prettier') { Resolve-NativeLockedPath -ToolsRoot $ToolsRoot -RelativePath $_ } else { $_ }
        })
        if ($definition.runtime) { $null = Get-NativeTool -Name $definition.runtime -ToolsRoot $ToolsRoot }
        $result = Invoke-NativeProcess -Command $command -Arguments @($prefix + @($definition.versionArguments))
        if ($result.ExitCode -ne 0) { throw "$Name version command exited $($result.ExitCode): $($result.Output)" }
        if ($result.Output -notmatch $definition.versionPattern -or $Matches.version -cne $definition.version) {
            throw "$Name version mismatch; expected $($definition.version), got '$($result.Output)'."
        }
        if ($Name -eq 'mdformat') {
            # Check plugin and transitive distribution versions too, not just the CLI's version.
            $wheels = @($lock.artifacts | Where-Object { $_.kind -eq 'wheel' -and (-not $_.testOnly -or $manifest.includeTestDependencies) })
            $names = ($wheels | ForEach-Object { "'$($_.name)'" }) -join ','
            $versions = ($wheels | ForEach-Object { "$($_.name)=$($_.version)" }) -join ';'
            $code = "import importlib.metadata as m; print(';'.join(n+'='+m.version(n) for n in [$names]))"
            $closure = Invoke-NativeProcess -Command $command -Arguments @('-c', $code)
            if ($closure.ExitCode -ne 0 -or $closure.Output -cne $versions) { throw "Python dependency closure mismatch (exit $($closure.ExitCode)): $($closure.Output)" }
        }
        [PSCustomObject]@{ command = $command; prefixArguments = [string[]]$prefix }
    } catch { throw "Native tool '$Name' unavailable: $($_.Exception.Message) $diagnostic" }
}

if ($HookName) {
    try {
        if ($HookName -cne 'pre-commit') { throw "Unsupported native hook: $HookName" }
        $root = Get-NativeToolsRoot -RepositoryRoot $RepositoryRoot
        $tool = Get-NativeTool -Name lefthook -ToolsRoot $root
        Push-Location -LiteralPath $RepositoryRoot
        try {
            $arguments = @($tool.prefixArguments) + @('run', '--no-auto-install', $HookName)
            & $tool.command @arguments
            $code = $LASTEXITCODE
        } finally { Pop-Location }
        exit $code
    } catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
}
