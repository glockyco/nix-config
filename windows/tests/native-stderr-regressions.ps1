param([string]$DocumentPath, [switch]$HostRun)

function Invoke-NativeStderrHostFixtures {
  param($Document, [string]$Root)
  # Exercise PS7's optional native-error preference as well as PS5's native
  # stderr ErrorRecords; this variable is scoped to this fixture function.
  $PSNativeCommandUseErrorActionPreference = $true
  $ids = @('twpayne.chezmoi', 'Git.Git', 'OpenJS.NodeJS.LTS', 'oschwartz10612.Poppler', 'PowerShell.PowerShell')
  $resources = @($Document.resources | Where-Object { $_.metadata.application.id -in $ids -or $_.metadata.application.source -eq 'npm' })
  foreach ($resource in $resources) {
    $app = $resource.metadata.application
    $spec = @(Get-EmbeddedJson (Get-ScriptRecord $resource.name $resource.properties.setScript))[0]
    Invoke-InstallerFixture $resource 'native-stderr-success' $Root
    if ($app.source -eq 'winget') {
      Invoke-InstallerFixture $resource 'list-stderr-failure' $Root
      Invoke-InstallerFixture $resource 'install-stderr-failure' $Root
      Invoke-InstallerFixture $resource 'native-stderr-install' $Root
    } elseif ($app.source -eq 'npm') {
      Invoke-InstallerFixture $resource 'install-stderr-failure' $Root
      Invoke-InstallerFixture $resource 'native-stderr-install' $Root
    }
    if (-not $spec.registrationOnly) { Invoke-InstallerFixture $resource 'version-stderr-failure' $Root }
  }
  Write-Output "fixture passed: real native stderr under PowerShell $($PSVersionTable.PSVersion)"
}

function Invoke-NativeStderrRegressions {
  param($Document, [string]$WindowsRoot, [string]$Root)
  $current = (Get-Process -Id $PID).Path
  $engines = @($current)
  if ($env:OS -eq 'Windows_NT') {
    $engines += Join-Path ([Environment]::GetFolderPath('System')) 'WindowsPowerShell\v1.0\powershell.exe'
    $engines += Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'Programs\PowerShell\7\pwsh.exe'
    if ($env:ProgramFiles) { $engines += Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe' }
    $engines += @(Get-Command pwsh.exe -CommandType Application -ErrorAction SilentlyContinue | ForEach-Object { $_.Source })
  }
  $fixtureDocument = Join-Path $Root 'native stderr document.winget'
  [IO.File]::WriteAllText($fixtureDocument, ($Document | ConvertTo-Json -Depth 100))
  foreach ($engine in @($engines | Select-Object -Unique)) {
    if (-not (Test-Path -LiteralPath $engine)) { continue }
    if ($engine -eq $current) { Invoke-NativeStderrHostFixtures $Document $Root; continue }
    $previous = $ErrorActionPreference
    try {
      $ErrorActionPreference = 'Continue'
      $output = & $engine -NoProfile -NonInteractive -File (Join-Path $WindowsRoot 'tests/native-stderr-regressions.ps1') -DocumentPath $fixtureDocument -HostRun 2>&1
      $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previous }
    Assert-Contract ($code -eq 0) "fixture native stderr host ${engine}: $($output -join '; ')"
    Write-Output $output
  }
}

if ($HostRun) {
  $ErrorActionPreference = 'Stop'
  $root = Join-Path ([IO.Path]::GetTempPath()) ('Native stderr host with spaces ' + [guid]::NewGuid().ToString())
  try {
    . (Join-Path $PSScriptRoot 'native-contract.ps1')
    . (Join-Path $PSScriptRoot 'installer-doubles.ps1')
    $document = Get-Content -LiteralPath $DocumentPath -Raw | ConvertFrom-Json
    $null = New-Item -ItemType Directory -Path $root
    Invoke-NativeStderrHostFixtures $document $root
  } catch {
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
  } finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
  }
}
