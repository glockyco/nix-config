# Read-only helpers are dot-sourceable on PowerShell 5.1/7, including Linux fixtures.
Set-StrictMode -Version Latest

function Assert-CiDependency {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw "Windows CI dependency: $Message" }
}

function Get-CiDependencyLock {
  param([string]$Path = (Join-Path $PSScriptRoot 'ci-dependencies.json'))
  Assert-CiDependency (Test-Path -LiteralPath $Path -PathType Leaf) "missing lock $Path"
  $lock = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-CiDependency ($lock.schemaVersion -eq 1) 'unsupported dependency lock schema'
  $ids = @()
  foreach ($artifact in $lock.artifacts) {
    Assert-CiDependency ($artifact.id -notin $ids) "duplicate artifact $($artifact.id)"
    $ids += $artifact.id
    Assert-CiDependency ($artifact.kind -in @('zip', 'portable-git', 'msixbundle')) "unsupported artifact type $($artifact.kind) for $($artifact.id)"
    Assert-CiDependency ($artifact.sha256 -cmatch '^[a-f0-9]{64}$') "invalid SHA-256 for $($artifact.id)"
    Assert-CiDependency ($artifact.url -cmatch '^https://github\.com/[^/]+/[^/]+/releases/download/') "untrusted artifact URL for $($artifact.id)"
  }
  foreach ($id in @('dsc', 'powershell', 'chezmoi', 'git', 'winget', 'winget-frameworks')) {
    Assert-CiDependency ($id -in $ids) "required artifact $id missing from lock"
  }
  return $lock
}

function Assert-CiArtifactHash {
  param($Artifact, [string]$Path)
  Assert-CiDependency (Test-Path -LiteralPath $Path -PathType Leaf) "missing downloaded artifact $($Artifact.id)"
  $hash = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
  Assert-CiDependency ($hash -ceq $Artifact.sha256) "download hash mismatch for $($Artifact.id)"
}

function Invoke-CiNative {
  param([string]$Command, [string[]]$Arguments = @())
  Assert-CiDependency (Test-Path -LiteralPath $Command -PathType Leaf) "missing executable $Command; provision runner dependencies first"
  $global:LASTEXITCODE = 0
  $lines = @(& $Command @Arguments)
  $code = $LASTEXITCODE
  Assert-CiDependency ($code -eq 0) "command $Command exited $code (arguments: $($Arguments -join ' '))"
  return ($lines -join "`n").Trim()
}

function Assert-CiNativeVersion {
  param($Artifact, [string]$Command)
  $output = Invoke-CiNative $Command ([string[]]$Artifact.versionArguments)
  Assert-CiDependency ($output -cmatch $Artifact.versionPattern) "$($Artifact.id) must be $($Artifact.version), got '$output' from $Command"
  Write-Host "runner dependency: $($Artifact.id) $output"
}

function Assert-CiResourceDiscovery {
  param([string]$Json, [string]$Type, [string]$Version)
  # DSC resource list emits JSON Lines, not a single JSON array.
  $records = @()
  foreach ($line in ($Json -split '\r?\n')) {
    if (-not [string]::IsNullOrWhiteSpace($line)) { $records += ($line | ConvertFrom-Json) }
  }
  $matches = @($records | Where-Object { $_.type -ceq $Type })
  Assert-CiDependency ($matches.Count -eq 1) "resource ${Type}: expected one discovered resource, got $($matches.Count)"
  Assert-CiDependency ($matches[0].version -ceq $Version) "resource ${Type}: expected version $Version, got $($matches[0].version)"
  Write-Host "discovered resource: $Type $Version"
}

function Get-CiRunnerCommands {
  param([string]$RunnerToolsRoot, $Lock)
  $manifestPath = Join-Path $RunnerToolsRoot 'runner-tools.json'
  Assert-CiDependency (Test-Path -LiteralPath $manifestPath -PathType Leaf) "missing $manifestPath; run ci-provision.ps1 on the hosted runner"
  $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $lockHash = (Get-FileHash -LiteralPath (Join-Path $PSScriptRoot 'ci-dependencies.json') -Algorithm SHA256).Hash.ToLowerInvariant()
  Assert-CiDependency ($manifest.lockSha256 -ceq $lockHash) 'runner manifest does not match the repository dependency lock'
  $commands = @{}
  foreach ($artifact in $Lock.artifacts) {
    if ($artifact.id -eq 'winget-frameworks') { continue }
    $property = $manifest.commands.PSObject.Properties[$artifact.id]
    Assert-CiDependency ($null -ne $property) "missing $($artifact.id) command record"
    $entry = $property.Value
    Assert-CiDependency ($entry.version -ceq $artifact.version) "manifest version mismatch for $($artifact.id)"
    if ($artifact.id -eq 'winget') {
      $packages = @(Get-AppxPackage -Name Microsoft.DesktopAppInstaller | Where-Object { $_.Version.ToString() -ceq $artifact.packageVersion -and $_.Architecture.ToString() -eq 'X64' })
      Assert-CiDependency ($packages.Count -eq 1) "DesktopAppInstaller $($artifact.packageVersion) registration missing"
      $expected = Join-Path $packages[0].InstallLocation $artifact.executable
    } else {
      $expected = Join-Path (Join-Path $RunnerToolsRoot $artifact.id) $artifact.executable
    }
    Assert-CiDependency ([IO.Path]::GetFullPath($entry.command) -ceq [IO.Path]::GetFullPath($expected)) "unexpected executable path for $($artifact.id)"
    Assert-CiDependency (Test-Path -LiteralPath $expected -PathType Leaf) "missing executable $expected"
    $hash = (Get-FileHash -LiteralPath $expected -Algorithm SHA256).Hash.ToLowerInvariant()
    Assert-CiDependency ($hash -ceq $entry.sha256) "runner executable changed for $($artifact.id)"
    Assert-CiNativeVersion $artifact $expected
    $commands[$artifact.id] = $expected
  }
  $ssh = Join-Path (Join-Path $RunnerToolsRoot 'git') 'usr/bin/ssh.exe'
  Assert-CiDependency (Test-Path -LiteralPath $ssh -PathType Leaf) 'locked PortableGit SSH client is missing'
  Assert-CiDependency ((Get-FileHash -LiteralPath $ssh -Algorithm SHA256).Hash.ToLowerInvariant() -ceq $manifest.sshSha256) 'locked PortableGit SSH client changed'
  $commands['ssh'] = $ssh
  return $commands
}
