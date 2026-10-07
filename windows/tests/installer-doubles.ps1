# Execute shipped installer logic, replacing only OS/native side effects by AST extent.
# All real filesystem operations are confined to a disposable profile with spaces.
function ConvertTo-FixtureScript {
  param([string]$Name, [string]$Source)
  $record = Get-ScriptRecord $Name $Source
  $edits = @()
  foreach ($command in $record.Commands) {
    if ($command.InvocationOperator -eq 'Ampersand') {
      $text = $command.Extent.Text
      $edits += [PSCustomObject]@{ Start = $command.Extent.StartOffset; Length = $text.Length; Text = ('Invoke-FixtureNative ' + $text.Substring(1).TrimStart()) }
    }
  }
  foreach ($member in $record.Members) {
    if ($member.Expression -is [System.Management.Automation.Language.TypeExpressionAst]) {
      $type = $member.Expression.TypeName.FullName
      $replacement = $null
      if ($type -in @('Environment', 'System.Environment') -and $member.Member.Value -in @('SetEnvironmentVariable', 'GetEnvironmentVariable')) {
        $replacement = '(Invoke-FixtureEnvironment ' + $member.Member.Value + ' ' + (($member.Arguments | ForEach-Object { '(' + $_.Extent.Text + ')' }) -join ' ') + ')'
      }
      if ($type -in @('IO.Compression.ZipFile', 'System.IO.Compression.ZipFile') -and $member.Member.Value -eq 'ExtractToDirectory') {
        $replacement = '(Expand-FixtureArchive ' + (($member.Arguments | ForEach-Object { '(' + $_.Extent.Text + ')' }) -join ' ') + ')'
      }
      if ($replacement) { $edits += [PSCustomObject]@{ Start = $member.Extent.StartOffset; Length = $member.Extent.Text.Length; Text = $replacement } }
    }
  }
  foreach ($exit in @($record.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ExitStatementAst] }, $true))) {
    $expression = if ($exit.Pipeline) { $exit.Pipeline.Extent.Text } else { '0' }
    $edits += [PSCustomObject]@{ Start = $exit.Extent.StartOffset; Length = $exit.Extent.Text.Length; Text = ('throw ("fixture-native-exit:" + (' + $expression + '))') }
  }
  foreach ($edit in @($edits | Sort-Object Start -Descending)) { $Source = $Source.Remove($edit.Start, $edit.Length).Insert($edit.Start, $edit.Text) }
  [scriptblock]::Create($Source)
}

function Invoke-InstallerFixture {
  param($Resource, [string]$Scenario, [string]$Root)
  $record = Get-ScriptRecord "$($Resource.name) specification" $Resource.properties.setScript
  $spec = @(Get-EmbeddedJson $record)[0]
  $caseRoot = Microsoft.PowerShell.Management\Join-Path $Root ([guid]::NewGuid().ToString())
  $null = New-Item -ItemType Directory -Path $caseRoot -Force
  $saved = @{}
  foreach ($name in @('HOME', 'USERPROFILE', 'LOCALAPPDATA', 'APPDATA', 'TEMP', 'Path')) {
    $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    if ($name -ne 'Path') { [Environment]::SetEnvironmentVariable($name, $caseRoot, 'Process') }
  }
  try {
    $state = @{ Installed = ($Scenario -notin @('missing', 'missing-row', 'hash-failure', 'install-failure', 'runtime-missing', 'node-machine', 'candidate-version-mismatch', 'candidate-native-failure')); Installs = 0; Downloads = 0; Extracts = 0; UserPath = ''; Version = $spec.version }
    $state.UpgradeAvailable = $spec.policy -eq 'self-updating' -and $Scenario -in @('upgrade', 'drift')
    if ($Scenario -in @('drift', 'runtime-missing')) { $state.Version = '0.0.1' }
    if ($Scenario -eq 'newer') { $state.Version = '999.0.0' }
    if (-not $state.Version) { $state.Version = '999.0.0' }
    # Normalize Windows relative declarations so the same doubles run on PS7 Linux.
    function Join-Path {
      param([string]$Path, [string]$ChildPath)
      [IO.Path]::Combine($Path.Replace('\', [IO.Path]::DirectorySeparatorChar), $ChildPath.Replace('\', [IO.Path]::DirectorySeparatorChar))
    }
    function Write-FixtureFile([string]$Path, [string]$Content = '') {
      $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($Path)) -Force
      [IO.File]::WriteAllText($Path, $Content)
    }
    function Get-FixtureToolPath {
      if ($spec.id -eq 'Git.Git') { return (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe') }
      if ($spec.id -eq 'Python.Python.3.13') { return (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python313\python.exe') }
      if ($Resource.metadata.application.source -eq 'official-zip') { return (Join-Path (Join-Path $env:LOCALAPPDATA $spec.directory) $spec.executable) }
      return (Join-Path $env:LOCALAPPDATA ('Microsoft\WinGet\Links\' + $spec.executable))
    }
    function Install-FixtureNpm {
      $prefix = Join-Path $env:LOCALAPPDATA $spec.directory
      $lock = ConvertFrom-NpmLockJson $spec.lock
      if ($Scenario -eq 'npm-lock-drift') { $lock.packages['node_modules/pyright'].integrity = 'sha512-Zml4dHVyZQ==' }
      Write-FixtureFile (Join-Path $prefix 'package-lock.json') ($lock | ConvertTo-Json -Depth 100)
      foreach ($package in $spec.packages.PSObject.Properties) {
        $version = if ($Scenario -eq 'npm-version-drift') { '0.0.1' } elseif ($Scenario -eq 'newer') { '999.0.0' } else { $package.Value.version }
        Write-FixtureFile (Join-Path $prefix ('node_modules\' + $package.Name + '\package.json')) (@{ version = $version } | ConvertTo-Json)
        foreach ($bin in $package.Value.bin.PSObject.Properties.Name) {
          if ($Scenario -ne 'npm-wrapper-missing') { Write-FixtureFile (Join-Path $prefix ('node_modules\.bin\' + $bin + '.cmd')) }
        }
      }
    }
    function Invoke-FixtureNative {
      $target = [string]$args[0]
      $arguments = @($args | Select-Object -Skip 1)
      $global:LASTEXITCODE = 0
      if ([IO.Path]::GetFileNameWithoutExtension($target) -eq 'svelteserver' -and '--version' -in $arguments) {
        throw "resource $($Resource.name): svelteserver has no --version mode; verify its manifest and wrapper instead"
      }
      if ($target -eq 'winget') {
        $scope = [Array]::IndexOf($arguments, '--scope')
        Assert-Contract ($scope -ge 0 -and $arguments[$scope + 1] -eq $Resource.metadata.application.scope) "resource $($Resource.name): double observed wrong installer scope"
        $idIndex = [Array]::IndexOf($arguments, '--id')
        Assert-Contract ($idIndex -ge 0 -and $arguments[$idIndex + 1] -eq $spec.id -and '--exact' -in $arguments -and '--source' -in $arguments) "resource $($Resource.name): double observed wrong ID/source"
        if ($arguments[0] -eq 'list') {
          if ($Scenario -eq 'list-failure') { $global:LASTEXITCODE = 23; return }
          if (-not $state.Installed -and $Scenario -eq 'missing-row') { return 'No installed package found matching input criteria.' }
          if (-not $state.Installed) { $global:LASTEXITCODE = -1978335212; return }
          if ('--upgrade-available' -in $arguments -and -not $state.UpgradeAvailable) { return 'No installed package found matching input criteria.' }
          return "$($spec.id) $($state.Version) winget"
        }
        Assert-Contract ($arguments[0] -eq 'install' -and '--skip-dependencies' -in $arguments) "resource $($Resource.name): competing dependency installation"
        $versionIndex = [Array]::IndexOf($arguments, '--version')
        Assert-Contract (($versionIndex -ge 0) -eq ($spec.policy -eq 'exact')) "resource $($Resource.name): wrong version-policy execution"
        if ($versionIndex -ge 0) { Assert-Contract ($arguments[$versionIndex + 1] -eq $spec.version) "resource $($Resource.name): wrong exact version execution" }
        if ($spec.installerType) {
          $typeIndex = [Array]::IndexOf($arguments, '--installer-type')
          Assert-Contract ($typeIndex -ge 0 -and $arguments[$typeIndex + 1] -eq $spec.installerType) "resource $($Resource.name): wrong installer type execution"
        }
        $state.Installs++
        if ($Scenario -eq 'install-failure') { $global:LASTEXITCODE = 23; return }
        $state.Installed = $true; $state.UpgradeAvailable = $false
        $state.Version = if ($spec.version) { $spec.version } else { '1.0.0' }
        if ($spec.executable) { Write-FixtureFile (Get-FixtureToolPath) }
        if ($spec.id -eq 'OpenJS.NodeJS.LTS') {
          Write-FixtureFile (Join-Path $env:LOCALAPPDATA 'Node ZIP with spaces\node.exe')
          Write-FixtureFile (Join-Path $env:LOCALAPPDATA 'Node ZIP with spaces\npm.cmd')
        }
        return
      }
      if ($arguments[0] -eq 'ci') {
        Assert-Contract ('--prefix' -in $arguments -and '--ignore-scripts' -in $arguments) "resource $($Resource.name): npm prefix/script boundary differs"
        $state.Installs++
        if ($Scenario -eq 'install-failure') { $global:LASTEXITCODE = 23; return }
        Install-FixtureNpm
        return
      }
      if ($Scenario -eq 'native-failure') { $global:LASTEXITCODE = 23; return }
      if ($Scenario -eq 'candidate-native-failure' -and $target -like '*expanded*') { $global:LASTEXITCODE = 23; return }
      if ($Resource.metadata.application.source -eq 'npm') {
        if ($Scenario -eq 'npm-native-version-drift') { return '0.0.1' }
        $command = [IO.Path]::GetFileNameWithoutExtension($target)
        foreach ($package in $spec.packages.PSObject.Properties) {
          if ($command -in $package.Value.bin.PSObject.Properties.Name) { return $package.Value.version }
        }
        throw "resource $($Resource.name): unexpected native wrapper $target"
      }
      if ($Scenario -eq 'candidate-version-mismatch' -and $target -like '*expanded*') { return '0.0.1' }
      if ($target -like '*expanded*') { return $spec.version }
      return $state.Version
    }
    function Invoke-FixtureEnvironment {
      param($Operation, $Name, $Value, $Target)
      if ($Operation -eq 'GetEnvironmentVariable') { return $state.UserPath }
      Assert-Contract ($Name -eq 'Path' -and $Target -eq 'User') "resource $($Resource.name): environment scope expansion"
      $state.UserPath = $Value
    }
    function Invoke-WebRequest {
      param($Uri, $OutFile, [switch]$UseBasicParsing)
      Assert-Contract ($Uri -eq $spec.url) "resource $($Resource.name): ZIP URL differs"
      $state.Downloads++; Write-FixtureFile $OutFile 'fixture archive'
    }
    function Get-FileHash {
      param($LiteralPath, $Algorithm)
      Assert-Contract ($Algorithm -eq 'SHA256') "resource $($Resource.name): ZIP digest algorithm differs"
      [PSCustomObject]@{ Hash = $(if ($Scenario -eq 'hash-failure') { '0' * 64 } else { $spec.sha256 }) }
    }
    function Expand-FixtureArchive {
      param($Archive, $Destination)
      $state.Extracts++
      Write-FixtureFile (Join-Path (Join-Path $Destination $spec.payload) $spec.executable)
    }
    function Get-ItemProperty {
      param($Path, $ErrorAction)
      Assert-Contract ($Path -eq 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64') "resource $($Resource.name): unexpected machine runtime read"
      [PSCustomObject]@{ Installed = $(if ($Scenario -eq 'runtime-missing') { 0 } else { 1 }) }
    }
    function Get-Command {
      param($Name, $ErrorAction)
      Assert-Contract ($Name -eq 'node.exe') "resource $($Resource.name): non-native runtime discovery"
      [PSCustomObject]@{ Source = (Join-Path $env:LOCALAPPDATA 'Node ZIP with spaces\node.exe') }
    }
    function Get-Item {
      param($LiteralPath)
      if ($Scenario -eq 'node-machine') { return [PSCustomObject]@{ Target = '/machine/node.exe'; FullName = '/machine/node.exe' } }
      if ($spec.id -eq 'OpenJS.NodeJS.LTS') { return [PSCustomObject]@{ Target = (Join-Path $env:LOCALAPPDATA 'Node ZIP with spaces\node.exe'); FullName = $LiteralPath } }
      [PSCustomObject]@{ Target = $null; FullName = $LiteralPath }
    }
    if ($Resource.metadata.application.source -eq 'npm') {
      Write-FixtureFile (Join-Path $env:LOCALAPPDATA 'Node ZIP with spaces\node.exe')
      Write-FixtureFile (Join-Path $env:LOCALAPPDATA 'Node ZIP with spaces\npm.cmd')
      if ($state.Installed) {
        Install-FixtureNpm
        $state.UserPath = Join-Path (Join-Path $env:LOCALAPPDATA $spec.directory) 'node_modules\.bin'
      }
    } elseif ($state.Installed -and $spec.executable) { Write-FixtureFile (Get-FixtureToolPath) }
    if ($state.Installed -and $spec.id -eq 'OpenJS.NodeJS.LTS') {
      Write-FixtureFile (Join-Path $env:LOCALAPPDATA 'Node ZIP with spaces\node.exe')
      Write-FixtureFile (Join-Path $env:LOCALAPPDATA 'Node ZIP with spaces\npm.cmd')
      $state.UserPath = Join-Path $env:LOCALAPPDATA 'Node ZIP with spaces'
    }
    if ($state.Installed -and $Resource.metadata.application.source -eq 'official-zip') {
      $state.UserPath = Split-Path -Parent (Get-FixtureToolPath)
    }
    $test = ConvertTo-FixtureScript "$($Resource.name) testScript" $Resource.properties.testScript
    $set = ConvertTo-FixtureScript "$($Resource.name) setScript" $Resource.properties.setScript
    $failure = $null
    $desired = $null
    try {
      $desired = & $test
      $null = & $set
      if ($Scenario -in @('missing', 'missing-row', 'drift', 'upgrade')) {
        if ($spec.version) { $state.Version = $spec.version }
        $null = & $set
        Assert-Contract ($state.Installs -eq $(if ($Resource.metadata.application.source -eq 'official-zip') { 0 } else { 1 })) "resource $($Resource.name): repeat apply is not idempotent"
      }
    } catch { $failure = $_.Exception.Message }
    $label = "resource $($Resource.name) fixture $Scenario"
    switch ($Scenario) {
      'hash-failure' { Assert-Contract ($failure -match 'SHA-256' -and $state.Extracts -eq 0) "${label}: failed hash did not stop extraction" }
      'install-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$') "${label}: installer exit 23 lost ($failure)" }
      'native-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$') "${label}: executable exit 23 lost ($failure)" }
      'candidate-native-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$') "${label}: candidate executable exit 23 lost ($failure)" }
      'list-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$') "${label}: registration exit 23 lost ($failure)" }
      'runtime-missing' { Assert-Contract ($failure -match 'runtime is missing' -and $state.Installs -eq 0) "${label}: absent employer runtime did not block installer" }
      'node-machine' { Assert-Contract ($failure -match 'native per-user Node' -and $state.Installs -eq 0) "${label}: machine/WSL Node accepted" }
      'candidate-version-mismatch' { Assert-Contract ($failure -match 'version mismatch') "${label}: wrong downloaded version accepted" }
      'newer' {
        if ($spec.policy -eq 'self-updating') { Assert-Contract ($desired -eq $true -and -not $failure -and $state.Installs -eq 0) "${label}: newer self-update downgraded/reinstalled ($failure)" }
        else { Assert-Contract ($failure -match 'refusing downgrade' -and $state.Installs -eq 0) "${label}: newer exact installation downgraded ($failure)" }
      }
      'desired' { Assert-Contract ($desired -eq $true -and -not $failure -and $state.Installs -eq 0 -and $state.Downloads -eq 0) "${label}: desired installation changed ($failure)" }
      'npm-version-drift' { Assert-Contract ($desired -eq $false) "${label}: manifest version drift accepted" }
      'npm-wrapper-missing' { Assert-Contract ($desired -eq $false) "${label}: missing native wrapper accepted" }
      'npm-lock-drift' { Assert-Contract ($desired -eq $false) "${label}: lock integrity drift accepted" }
      'npm-native-version-drift' { Assert-Contract ($desired -eq $false) "${label}: native command version drift accepted" }
      default { Assert-Contract (-not $failure -and $desired -eq $false) "${label}: missing/drift did not converge ($failure)" }
    }
    if ($Resource.metadata.application.source -eq 'official-zip' -and $Scenario -in @('missing', 'drift')) {
      Assert-Contract ($state.Downloads -eq 1 -and $state.Extracts -eq 1) "${label}: ZIP repeat install/download is not idempotent"
    }
    Write-Output "fixture passed: $label"
  } finally {
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
    Remove-Item -LiteralPath $caseRoot -Recurse -Force
  }
}
