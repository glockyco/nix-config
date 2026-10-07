[CmdletBinding()]
param(
    [string]$RepositoryRoot,
    [string]$ToolsRoot,
    [switch]$SkipHook,
    [switch]$IncludeTestDependencies
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
. (Join-Path $PSScriptRoot 'tools.ps1') -RepositoryRoot $RepositoryRoot

function Receive-NativeArtifact {
    param([string]$Uri, [string]$Destination)
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -UseBasicParsing -Uri $Uri -OutFile $Destination
}

function Test-NativeArtifactHash {
    param($Artifact, [string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Missing downloaded artifact $($Artifact.file)." }
    $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -cne $Artifact.sha256) { throw "SHA-256 mismatch for $($Artifact.file); expected $($Artifact.sha256), got $hash." }
    if ($Artifact.PSObject.Properties.Name -contains 'integrity') {
        $algorithm = [Security.Cryptography.SHA512]::Create()
        $stream = [IO.File]::OpenRead($Path)
        try { $integrity = 'sha512-' + [Convert]::ToBase64String($algorithm.ComputeHash($stream)) }
        finally { $stream.Dispose(); $algorithm.Dispose() }
        if ($integrity -cne $Artifact.integrity) { throw "npm integrity mismatch for $($Artifact.file)." }
    }
}

function Expand-NativeArtifact {
    param($Artifact, [string]$Path, [string]$Destination)
    $null = New-Item -ItemType Directory -Path $Destination -Force
    if ($Artifact.kind -eq 'exe') {
        Copy-Item -LiteralPath $Path -Destination (Join-Path $Destination ($Artifact.name + '.exe'))
    } elseif ($Artifact.kind -eq 'zip' -or $Artifact.kind -eq 'wheel') {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [IO.Compression.ZipFile]::OpenRead($Path)
        try {
            foreach ($entry in $archive.Entries) {
                $target = Resolve-NativeLockedPath -ToolsRoot $Destination -RelativePath $entry.FullName
                if (-not $entry.Name) { $null = New-Item -ItemType Directory -Path $target -Force; continue }
                $null = New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $target, $true)
            }
        } finally { $archive.Dispose() }
    } elseif ($Artifact.kind -eq 'tar') {
        $listing = Invoke-NativeProcess -Command 'tar.exe' -Arguments @('-tzf', $Path)
        if ($listing.ExitCode -ne 0) { throw "Cannot inspect $($Artifact.file): tar exit $($listing.ExitCode): $($listing.Output)" }
        foreach ($entry in ($listing.Output -split "`n")) {
            if ($entry) { $null = Resolve-NativeLockedPath -ToolsRoot $Destination -RelativePath $entry.TrimEnd("`r", '/') }
        }
        $result = Invoke-NativeProcess -Command 'tar.exe' -Arguments @('-xzf', $Path, '-C', $Destination)
        if ($result.ExitCode -ne 0) { throw "Cannot extract $($Artifact.file): tar exit $($result.ExitCode): $($result.Output)" }
    } else { throw "Unsupported native artifact type $($Artifact.kind)." }
}

function Get-NativeHookContent {
    # Git's sh quotes paths (including UNC roots and spaces); PowerShell never depends on a profile or PATH formatter.
    @'
#!/bin/sh
# nix-config managed native pre-commit v1
root=$(git rev-parse --show-toplevel) || exit $?
if ! command -v powershell.exe >/dev/null 2>&1; then
  echo 'Native development environment missing: Windows PowerShell is required; run windows/dev/bootstrap.ps1.' >&2
  exit 1
fi
if [ ! -f "$root/windows/dev/tools.ps1" ]; then
  echo 'Native development environment missing: restore windows/dev/tools.ps1 and run windows/dev/bootstrap.ps1.' >&2
  exit 1
fi
exec powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$root/windows/dev/tools.ps1" -HookName pre-commit -RepositoryRoot "$root"
'@ + "`n"
}

function Get-NativeHookPath {
    param([string]$RepositoryRoot)
    $result = Invoke-NativeProcess -Command 'git' -Arguments @('-C', $RepositoryRoot, 'rev-parse', '--git-path', 'hooks/pre-commit')
    if ($result.ExitCode -ne 0) { throw "Cannot resolve hook path: git exit $($result.ExitCode): $($result.Output)" }
    $path = $result.Output
    if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $RepositoryRoot $path }
    [IO.Path]::GetFullPath($path)
}

function Assert-NativeHookOwnership {
    param([string]$HookPath)
    if ((Test-Path -LiteralPath $HookPath) -and [IO.File]::ReadAllText($HookPath) -cne (Get-NativeHookContent)) {
        throw "Refusing to replace unrelated or modified hook '$HookPath'; review it before native bootstrap."
    }
}

function Install-NativeHook {
    param([string]$RepositoryRoot)
    $hookPath = Get-NativeHookPath -RepositoryRoot $RepositoryRoot
    Assert-NativeHookOwnership -HookPath $hookPath
    if (-not (Test-Path -LiteralPath $hookPath)) {
        $null = New-Item -ItemType Directory -Path (Split-Path $hookPath -Parent) -Force
        [IO.File]::WriteAllText($hookPath, (Get-NativeHookContent), (New-Object Text.UTF8Encoding($false)))
    }
}

function Invoke-NativeBootstrap {
    param([string]$RepositoryRoot, [string]$ToolsRoot, [switch]$SkipHook, [switch]$IncludeTestDependencies)
    if ($env:OS -ne 'Windows_NT') { throw 'The native bootstrap requires Windows x64; Darwin/Linux use the pinned Nix shell.' }
    if (-not [Environment]::Is64BitProcess) { throw 'Run the native bootstrap in a 64-bit PowerShell process.' }
    $RepositoryRoot = [IO.Path]::GetFullPath($RepositoryRoot)
    if (-not $ToolsRoot) { $ToolsRoot = Get-NativeToolsRoot -RepositoryRoot $RepositoryRoot }
    $ToolsRoot = [IO.Path]::GetFullPath($ToolsRoot)
    if (-not $SkipHook) { Assert-NativeHookOwnership -HookPath (Get-NativeHookPath -RepositoryRoot $RepositoryRoot) }
    $lock = Get-NativeDependencies
    $tools = @($lock.tools | Where-Object { -not $_.testOnly -or $IncludeTestDependencies })
    $alreadyInstalled = Test-Path -LiteralPath $ToolsRoot
    if ($alreadyInstalled) {
        # Existing managed tools must be healthy; never hide missing files, version drift or lock changes by reinstalling.
        foreach ($definition in $tools) { $null = Get-NativeTool -Name $definition.id -ToolsRoot $ToolsRoot }
        $manifest = Get-Content -LiteralPath (Join-Path $ToolsRoot 'tools.json') -Raw | ConvertFrom-Json
        if (-not $IncludeTestDependencies -or $manifest.includeTestDependencies) {
            if (-not $SkipHook) { Install-NativeHook -RepositoryRoot $RepositoryRoot }
            Write-Output "Native development tools already installed at $ToolsRoot"
            return
        }
    }
    $parent = Split-Path $ToolsRoot -Parent
    $null = New-Item -ItemType Directory -Path $parent -Force
    $stage = Join-Path $parent ('native-dev-stage-' + [Guid]::NewGuid().ToString('N'))
    $download = Join-Path ([IO.Path]::GetTempPath()) ('native-dev-download-' + [Guid]::NewGuid().ToString('N'))
    $backup = $null
    try {
        $null = New-Item -ItemType Directory -Path $stage
        $null = New-Item -ItemType Directory -Path $download
        foreach ($artifact in @($lock.artifacts | Where-Object { -not $_.testOnly -or $IncludeTestDependencies })) {
            $path = Join-Path $download $artifact.file
            Receive-NativeArtifact -Uri $artifact.url -Destination $path
            Test-NativeArtifactHash -Artifact $artifact -Path $path
            Expand-NativeArtifact -Artifact $artifact -Path $path -Destination (Resolve-NativeLockedPath -ToolsRoot $stage -RelativePath $artifact.target)
        }
        # Embedded Python is isolated from user/site/PYTHONPATH and contains only the hashed wheel closure.
        [IO.File]::WriteAllText((Join-Path $stage 'python/python313._pth'), "python313.zip`n.`nLib/site-packages`n", (New-Object Text.UTF8Encoding($false)))
        $manifest = [ordered]@{
            schemaVersion = 1
            lockSha256 = (Get-FileHash -LiteralPath $script:NativeLockPath -Algorithm SHA256).Hash.ToLowerInvariant()
            includeTestDependencies = [bool]$IncludeTestDependencies
            tools = $tools
        }
        [IO.File]::WriteAllText((Join-Path $stage 'tools.json'), ($manifest | ConvertTo-Json -Depth 10) + "`n", (New-Object Text.UTF8Encoding($false)))
        foreach ($definition in $tools) { $null = Get-NativeTool -Name $definition.id -ToolsRoot $stage }
        if ($alreadyInstalled) {
            $backup = Join-Path $parent ('native-dev-previous-' + [Guid]::NewGuid().ToString('N'))
            Move-Item -LiteralPath $ToolsRoot -Destination $backup
        }
        try { Move-Item -LiteralPath $stage -Destination $ToolsRoot }
        catch {
            if ($backup) { Move-Item -LiteralPath $backup -Destination $ToolsRoot; $backup = $null }
            throw
        }
        if ($backup) { Remove-Item -LiteralPath $backup -Recurse -Force; $backup = $null }
        if (-not $SkipHook) { Install-NativeHook -RepositoryRoot $RepositoryRoot }
        Write-Output "Native development tools installed at $ToolsRoot"
    } finally {
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
        if (Test-Path -LiteralPath $download) { Remove-Item -LiteralPath $download -Recurse -Force }
    }
}

if ($MyInvocation.InvocationName -ne '.') {
    try { Invoke-NativeBootstrap -RepositoryRoot $RepositoryRoot -ToolsRoot $ToolsRoot -SkipHook:$SkipHook -IncludeTestDependencies:$IncludeTestDependencies }
    catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
}
