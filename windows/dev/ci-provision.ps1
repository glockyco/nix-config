[CmdletBinding()]
param(
  [string]$RunnerToolsRoot = (Join-Path $env:RUNNER_TEMP 'native-check')
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'ci-dependencies.ps1')
# Installation is restricted to an ephemeral hosted runner, never a workstation.
Assert-CiDependency ($env:GITHUB_ACTIONS -eq 'true' -and $env:RUNNER_ENVIRONMENT -eq 'github-hosted') 'ci-provision.ps1 requires a GitHub-hosted Actions runner'
Assert-CiDependency ($env:OS -eq 'Windows_NT' -and [Environment]::Is64BitProcess) 'Windows x64 PowerShell is required'
$tempRoot = [IO.Path]::GetFullPath($env:RUNNER_TEMP).TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
$RunnerToolsRoot = [IO.Path]::GetFullPath($RunnerToolsRoot)
Assert-CiDependency ($RunnerToolsRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase)) 'runner tools must live below RUNNER_TEMP'
Assert-CiDependency (-not (Test-Path -LiteralPath $RunnerToolsRoot)) 'runner tools directory already exists; use a fresh hosted runner directory'
$lock = Get-CiDependencyLock
$null = New-Item -ItemType Directory -Path $RunnerToolsRoot
$downloadRoot = Join-Path $RunnerToolsRoot 'downloads'
$null = New-Item -ItemType Directory -Path $downloadRoot
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archives = @{}
foreach ($artifact in $lock.artifacts) {
  $path = Join-Path $downloadRoot ([IO.Path]::GetFileName(([uri]$artifact.url).AbsolutePath))
  Invoke-WebRequest -UseBasicParsing -Uri $artifact.url -OutFile $path
  Assert-CiArtifactHash $artifact $path
  $archives[$artifact.id] = $path
  $target = Join-Path $RunnerToolsRoot $artifact.id
  if ($artifact.kind -eq 'zip') {
    [IO.Compression.ZipFile]::ExtractToDirectory($path, $target)
  } elseif ($artifact.kind -eq 'portable-git') {
    # The official PortableGit self-extracting archive only unpacks into this directory.
    $process = Start-Process -FilePath $path -ArgumentList @('-y', ('-o"' + $target + '"')) -Wait -PassThru
    Assert-CiDependency ($process.ExitCode -eq 0) "PortableGit extraction exited $($process.ExitCode)"
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
Add-AppxPackage -Path $archives['winget'] -DependencyPath $dependencyPaths -ForceUpdateFromAnyVersion
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
