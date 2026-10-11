[CmdletBinding()]
param(
  [string]$RunnerToolsRoot = (Join-Path $env:RUNNER_TEMP 'native-check'),
  [string]$ArchiveCacheRoot
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci-dependencies.ps1')
function Receive-CiArtifact {
  param($Artifact, [string]$ArchiveRoot)
  $path = Join-Path $ArchiveRoot ([IO.Path]::GetFileName(([uri]$Artifact.url).AbsolutePath))
  $timer = [Diagnostics.Stopwatch]::StartNew()
  try {
    if (Test-Path -LiteralPath $path) {
      Write-Host "archive cache hit: $($Artifact.id)"
    } else {
      $savedProgressPreference = $ProgressPreference
      try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -UseBasicParsing -Uri $Artifact.url -OutFile $path
      } finally { $ProgressPreference = $savedProgressPreference }
    }
  } finally { Write-Host ("timing: provision {0} download/cache {1:F3}s" -f $Artifact.id, $timer.Elapsed.TotalSeconds) }
  $timer.Restart()
  try { Assert-CiArtifactHash $Artifact $path }
  finally { Write-Host ("timing: provision {0} SHA256 {1:F3}s" -f $Artifact.id, $timer.Elapsed.TotalSeconds) }
  return $path
}

function Invoke-CiProvision {
  param([string]$RunnerToolsRoot, [string]$ArchiveCacheRoot)
  # Installation is restricted to an ephemeral hosted runner, never a workstation.
  Assert-CiDependency ($env:GITHUB_ACTIONS -eq 'true' -and $env:RUNNER_ENVIRONMENT -eq 'github-hosted') 'ci-provision.ps1 requires a GitHub-hosted Actions runner'
  Assert-CiDependency ($env:OS -eq 'Windows_NT' -and [Environment]::Is64BitProcess) 'Windows x64 PowerShell is required'
  $tempRoot = [IO.Path]::GetFullPath($env:RUNNER_TEMP).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
  $RunnerToolsRoot = [IO.Path]::GetFullPath($RunnerToolsRoot)
  Assert-CiDependency ($RunnerToolsRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) 'runner tools must live below RUNNER_TEMP'
  Assert-CiDependency (-not (Test-Path -LiteralPath $RunnerToolsRoot)) 'runner tools directory already exists; use a fresh hosted runner directory'
  if ($ArchiveCacheRoot) {
    $ArchiveCacheRoot = [IO.Path]::GetFullPath($ArchiveCacheRoot)
    $cachePrefix = $ArchiveCacheRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $toolsPrefix = $RunnerToolsRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    Assert-CiDependency (-not ($cachePrefix.StartsWith($toolsPrefix, [StringComparison]::OrdinalIgnoreCase) -or $toolsPrefix.StartsWith($cachePrefix, [StringComparison]::OrdinalIgnoreCase))) 'archive cache and runner tools must be separate, non-overlapping directories'
  }
  $lock = Get-CiDependencyLock
  $null = New-Item -ItemType Directory -Path $RunnerToolsRoot
  $downloadRoot = if ($ArchiveCacheRoot) { $ArchiveCacheRoot } else { Join-Path $RunnerToolsRoot 'downloads' }
  $null = New-Item -ItemType Directory -Path $downloadRoot -Force
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $archives = @{}
  foreach ($artifact in $lock.artifacts) {
    # Hash every restored or freshly downloaded archive before extraction/registration.
    # A corrupt cache entry is fatal; it is never replaced by another download.
    $path = Receive-CiArtifact $artifact $downloadRoot
    $archives[$artifact.id] = $path
    $target = Join-Path $RunnerToolsRoot $artifact.id
    if ($artifact.kind -in @('zip', 'portable-git')) {
      $timer = [Diagnostics.Stopwatch]::StartNew()
      try {
        if ($artifact.kind -eq 'zip') {
          [IO.Compression.ZipFile]::ExtractToDirectory($path, $target)
        } else {
          # The official PortableGit self-extracting archive only unpacks into this directory.
          $process = Start-Process -FilePath $path -ArgumentList @('-y', ('-o"' + $target + '"')) -Wait -PassThru
          Assert-CiDependency ($process.ExitCode -eq 0) "PortableGit extraction exited $($process.ExitCode)"
        }
      } finally { Write-Host ("timing: provision {0} extraction {1:F3}s" -f $artifact.id, $timer.Elapsed.TotalSeconds) }
    }
  }
  $frameworks = @($lock.artifacts | Where-Object id -eq 'winget-frameworks')[0]
  $dependencyPaths = @()
  foreach ($relative in $frameworks.packages) {
    $path = Join-Path (Join-Path $RunnerToolsRoot 'winget-frameworks') $relative
    Assert-CiDependency (Test-Path -LiteralPath $path -PathType Leaf) "missing locked WinGet framework $relative"
    $dependencyPaths += $path
  }
  # Only test-processor AppX dependencies are registered; no workstation resources run.
  $timer = [Diagnostics.Stopwatch]::StartNew()
  try { Add-AppxPackage -Path $archives['winget'] -DependencyPath $dependencyPaths -ForceUpdateFromAnyVersion }
  finally { Write-Host ("timing: provision winget AppX registration {0:F3}s" -f $timer.Elapsed.TotalSeconds) }
  $winget = @($lock.artifacts | Where-Object id -eq 'winget')[0]
  $packages = @(Get-AppxPackage -Name Microsoft.DesktopAppInstaller | Where-Object { $_.Version.ToString() -ceq $winget.packageVersion -and $_.Architecture.ToString() -eq 'X64' })
  Assert-CiDependency ($packages.Count -eq 1) "exact DesktopAppInstaller $($winget.packageVersion) registration failed"
  $commands = [ordered]@{}
  foreach ($artifact in $lock.artifacts) {
    if ($artifact.id -eq 'winget-frameworks') { continue }
    $base = if ($artifact.id -eq 'winget') { $packages[0].InstallLocation } else { Join-Path $RunnerToolsRoot $artifact.id }
    $command = Join-Path $base $artifact.executable
    Assert-CiNativeVersion $artifact $command
    $commands[$artifact.id] = [ordered]@{
      command = $command
      version = $artifact.version
      sha256 = (Get-FileHash -LiteralPath $command -Algorithm SHA256).Hash.ToLowerInvariant()
    }
  }
  $ssh = Join-Path (Join-Path $RunnerToolsRoot 'git') 'usr/bin/ssh.exe'
  Assert-CiDependency (Test-Path -LiteralPath $ssh -PathType Leaf) 'PortableGit archive lacks SSH fixture dependency'
  $manifest = [ordered]@{
    lockSha256 = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'ci-dependencies.json') -Algorithm SHA256).Hash.ToLowerInvariant()
    commands = $commands
    sshSha256 = (Get-FileHash -LiteralPath $ssh -Algorithm SHA256).Hash.ToLowerInvariant()
  }
  $manifestPath = Join-Path $RunnerToolsRoot 'runner-tools.json'
  [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding $false))
  Write-Output "Provisioned locked runner dependencies in $RunnerToolsRoot; no workstation configuration was applied."
}

if ($MyInvocation.InvocationName -ne '.') {
  Invoke-CiProvision -RunnerToolsRoot $RunnerToolsRoot -ArchiveCacheRoot $ArchiveCacheRoot
}
