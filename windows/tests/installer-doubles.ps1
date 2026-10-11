# Execute shipped installer logic, replacing only OS/native side effects by AST extent.
# All real filesystem operations are confined to a disposable profile with spaces.
function ConvertTo-FixtureScript {
  param([string]$Name, [string]$Source, [switch]$NativeStderr)
  $record = Get-ScriptRecord $Name $Source
  $edits = @()
  foreach ($command in $record.Commands) {
    if ($command.InvocationOperator -eq 'Ampersand') {
      $text = $command.Extent.Text
      $replacement = 'Invoke-FixtureNative ' + $text.Substring(1).TrimStart()
      if ($NativeStderr) {
        # Preserve a real native ampersand expression and the shipped surrounding
        # preference/exit-code logic. Only arguments and external side effects change.
        $arguments = @($command.CommandElements | ForEach-Object { $_.Extent.Text }) -join ' '
        $replacement = '& $fixtureEngine -NoProfile -NonInteractive -EncodedCommand (Get-FixtureNativeCommand ' + $arguments + ')'
        $replacement += (@($command.Redirections | ForEach-Object { ' ' + $_.Extent.Text }) -join '')
      }
      $edits += [PSCustomObject]@{ Start = $command.Extent.StartOffset; Length = $text.Length; Text = $replacement }
    }
    if ($command.GetCommandName() -eq 'New-Object' -and @($command.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $_.Value -eq 'WindowsInstaller.Installer' }).Count -eq 1) {
      $edits += [PSCustomObject]@{ Start = $command.Extent.StartOffset; Length = $command.Extent.Text.Length; Text = 'New-FixtureInstaller' }
    }
  }
  foreach ($member in $record.Members) {
    if ($member.Member.Value -eq 'InvokeMember' -and $member.Arguments.Count -eq 5 -and $member.Arguments[0] -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $member.Arguments[0].Value -in @('RelatedProducts', 'ProductInfo')) {
      $replacement = '(Invoke-FixtureInstallerInfo (' + $member.Arguments[0].Extent.Text + ') (' + $member.Arguments[4].Extent.Text + '))'
      $edits += [PSCustomObject]@{ Start = $member.Extent.StartOffset; Length = $member.Extent.Text.Length; Text = $replacement }
    }
    if ($member.Expression -is [System.Management.Automation.Language.TypeExpressionAst]) {
      $type = $member.Expression.TypeName.FullName
      $replacement = $null
      if ($type -in @('Environment', 'System.Environment') -and $member.Member.Value -in @('SetEnvironmentVariable', 'GetEnvironmentVariable')) {
        $replacement = '(Invoke-FixtureEnvironment ' + $member.Member.Value + ' ' + (($member.Arguments | ForEach-Object { '(' + $_.Extent.Text + ')' }) -join ' ') + ')'
      }
      if ($type -in @('IO.Compression.ZipFile', 'System.IO.Compression.ZipFile') -and $member.Member.Value -eq 'ExtractToDirectory') {
        $replacement = '(Expand-FixtureArchive ' + (($member.Arguments | ForEach-Object { '(' + $_.Extent.Text + ')' }) -join ' ') + ')'
      }
      if ($type -eq 'Runtime.InteropServices.Marshal' -and $member.Member.Value -eq 'FinalReleaseComObject') {
        $replacement = '(Close-FixtureInstaller (' + $member.Arguments[0].Extent.Text + '))'
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
  param($Resource, [string]$Scenario, [string]$Root, [string]$ArchivePath)
  $record = Get-ScriptRecord "$($Resource.name) specification" $Resource.properties.setScript
  $spec = @(Get-EmbeddedJson $record)[0]
  $archiveResource = $Resource.metadata.application.source -in @('official-zip', 'official-archive')
  $caseRoot = Microsoft.PowerShell.Management\Join-Path $Root ([guid]::NewGuid().ToString())
  $null = New-Item -ItemType Directory -Path $caseRoot -Force
  $saved = @{}
  foreach ($name in @('HOME', 'USERPROFILE', 'LOCALAPPDATA', 'APPDATA', 'TEMP', 'Path', 'SystemRoot')) {
    $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    # A real native PowerShell child needs the real Windows installation to initialize.
    if ($name -ne 'Path' -and -not ($name -eq 'SystemRoot' -and ($ArchivePath -or $Scenario -like '*stderr*'))) { [Environment]::SetEnvironmentVariable($name, $caseRoot, 'Process') }
  }
  try {
    $nativeStderr = $Scenario -like '*stderr*'
    $fixtureEngine = (Get-Process -Id $PID).Path
    $state = @{ Installed = ($Scenario -notin @('missing', 'missing-row', 'hash-failure', 'install-failure', 'install-stderr-failure', 'native-stderr-install', 'runtime-missing', 'node-machine', 'candidate-version-mismatch', 'candidate-native-failure')); Installs = 0; Downloads = 0; Extracts = 0; Hashes = 0; NativeVersions = 0; StderrCommands = 0; SeenTools = @(); UserPath = ''; Version = $spec.version }
    $state.MsiOpens = 0; $state.MsiCloses = 0
    if ($archiveResource -and $Scenario -in @('hash-failure', 'extraction-native-failure', 'candidate-version-mismatch', 'candidate-native-failure', 'candidate-missing', 'promotion-failure')) { $state.Installed = $true; $state.Version = '0.0.1' }
    $state.UpgradeAvailable = $spec.PSObject.Properties['policy'] -and $spec.policy -eq 'self-updating' -and $Scenario -in @('upgrade', 'drift')
    $state.NativeDrift = $Scenario -in @('pdf-text-native-drift', 'pdf-info-native-drift')
    if ($Scenario -in @('drift', 'runtime-missing', 'msi-version-drift')) { $state.Version = '0.0.1' }
    if ($Scenario -eq 'newer') { $state.Version = '999.0.0' }
    if ($Scenario -eq 'revision-drift') { $state.Version = '7.1.2-32' }
    if ($Scenario -eq 'catalog-revision-drift') { $state.Version = '25.07.0-1' }
    if (-not $state.Version) { $state.Version = '999.0.0' }
    function New-FixtureInstaller { $state.MsiOpens++; [PSCustomObject]@{} }
    function Close-FixtureInstaller { param($Installer) $state.MsiCloses++ }
    function Invoke-FixtureInstallerInfo {
      param([string]$Property, [object[]]$Arguments)
      if ($Scenario -eq 'list-failure') { throw 'Windows Installer API failed' }
      if ($Property -eq 'RelatedProducts') {
        Assert-Contract ($Arguments.Count -eq 1 -and $Arguments[0] -eq $spec.upgradeCode) "resource $($Resource.name): MSI UpgradeCode selector differs"
        if (-not $state.Installed) { return }
        if ($Scenario -eq 'msi-ambiguous') { return @('{11111111-1111-1111-1111-111111111111}', '{22222222-2222-2222-2222-222222222222}') }
        return '{11111111-1111-1111-1111-111111111111}'
      }
      Assert-Contract ($Property -eq 'ProductInfo' -and $Arguments.Count -eq 2 -and $Arguments[0] -eq '{11111111-1111-1111-1111-111111111111}') "resource $($Resource.name): MSI product selector differs"
      if ($Arguments[1] -eq 'AssignmentType') { return $(if ($Scenario -eq 'msi-machine') { '1' } else { '0' }) }
      Assert-Contract ($Arguments[1] -eq 'VersionString') "resource $($Resource.name): unsupported MSI property"
      return $state.Version
    }
    # Normalize Windows relative declarations so the same doubles run on PS7 Linux.
    function Join-Path {
      param([string]$Path, [string]$ChildPath)
      [IO.Path]::Combine($Path.Replace('\', [IO.Path]::DirectorySeparatorChar), $ChildPath.Replace('\', [IO.Path]::DirectorySeparatorChar))
    }
    function Write-FixtureFile([string]$Path, [string]$Content = '') {
      $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($Path)) -Force
      [IO.File]::WriteAllText($Path, $Content)
    }
    function Move-Item {
      param([string]$LiteralPath, [string]$Destination)
      if ($Scenario -eq 'promotion-failure' -and $LiteralPath -like '*expanded*') { throw 'fixture promotion failure' }
      Microsoft.PowerShell.Management\Move-Item -LiteralPath $LiteralPath -Destination $Destination
    }
    function Get-FixturePackageRoot([string]$Id = $spec.id) {
      Join-Path $env:LOCALAPPDATA ('Microsoft\WinGet\Packages\' + $Id + '_Microsoft.Winget.Source_8wekyb3d8bbwe')
    }
    function Get-FixturePortablePath([string]$Executable = $spec.executable, [string]$Id = $spec.id) {
      Join-Path (Join-Path (Get-FixturePackageRoot $Id) 'payload with spaces\bin') $Executable
    }
    function Get-FixtureToolPath {
      if ($spec.id -eq 'Git.Git') { return (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe') }
      if ($spec.id -eq 'Python.Python.3.13') { return (Join-Path $env:LOCALAPPDATA 'Programs\Python\Python313\python.exe') }
      if ($spec.id -eq 'JohnMacFarlane.Pandoc') { return (Join-Path $env:LOCALAPPDATA 'Programs\Pandoc\pandoc.exe') }
      if ($archiveResource) { return (Join-Path (Join-Path $env:LOCALAPPDATA $spec.directory) $spec.executable) }
      return (Get-FixturePortablePath)
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
    function Get-FixtureNativeCommand {
      $output = @(Invoke-FixtureNative @args)
      $code = $global:LASTEXITCODE
      # A missing registration can also be represented by successful list output
      # without a matching row, avoiding Unix truncation of Windows HRESULTs.
      if ($code -in @(-1978335212, -1978335189)) { $code = 0; $output = @('No installed package found matching input criteria.') }
      $state.StderrCommands++
      $program = "[Console]::Error.WriteLine('fixture real native stderr'); "
      foreach ($line in $output) { $program += "[Console]::Out.WriteLine('" + ([string]$line).Replace("'", "''") + "'); " }
      $program += "exit $code"
      [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($program))
    }
    function Invoke-FixtureNative {
      $target = [string]$args[0]
      # Native applications expand array-valued arguments; a PowerShell function
      # double receives the array as one argument unless it is expanded here.
      $arguments = @(foreach ($argument in @($args | Select-Object -Skip 1)) {
        foreach ($value in @($argument)) { [string]$value }
      })
      $global:LASTEXITCODE = 0
      if ($archiveResource -and $spec.archiveKind -eq '7z' -and $target -eq (Join-Path $env:SystemRoot 'System32\tar.exe')) {
        Assert-Contract ($arguments.Count -eq 4 -and $arguments[0] -eq '-xf' -and $arguments[2] -eq '-C') "resource $($Resource.name): inbox tar argument boundary differs"
        Assert-Contract ($state.Hashes -gt $state.Extracts) "resource $($Resource.name): native extraction occurred before digest verification"
        if ($ArchivePath) {
          $state.Extracts++
          & $target @arguments
          return
        }
        if ($Scenario -eq 'extraction-native-failure') { $state.Extracts++; $global:LASTEXITCODE = 23; return }
        Expand-FixtureArchive $arguments[1] $arguments[3]
        return
      }
      if ([IO.Path]::GetFileNameWithoutExtension($target) -eq 'svelteserver' -and '--version' -in $arguments) {
        throw "resource $($Resource.name): svelteserver has no --version mode; verify its manifest and wrapper instead"
      }
      if ($target -eq 'winget') {
        $scope = [Array]::IndexOf($arguments, '--scope')
        Assert-Contract ($scope -ge 0 -and $arguments[$scope + 1] -eq $Resource.metadata.application.scope) "resource $($Resource.name): double observed wrong installer scope"
        $idIndex = [Array]::IndexOf($arguments, '--id')
        Assert-Contract ($idIndex -ge 0 -and $arguments[$idIndex + 1] -eq $spec.id -and '--exact' -in $arguments -and '--source' -in $arguments) "resource $($Resource.name): double observed wrong ID/source"
        if ($arguments[0] -eq 'list') {
          Assert-Contract (-not $spec.upgradeCode) "resource $($Resource.name): MSI discovery must not use WinGet ARP scope filtering"
          if ($Scenario -in @('list-failure', 'list-stderr-failure')) { $global:LASTEXITCODE = 23; return }
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
        if ($spec.id -eq 'JohnMacFarlane.Pandoc') {
          $locationIndex = [Array]::IndexOf($arguments, '--location')
          Assert-Contract ($locationIndex -ge 0 -and $arguments[$locationIndex + 1] -eq (Join-Path $env:LOCALAPPDATA 'Programs\Pandoc')) "resource $($Resource.name): Pandoc user install location differs"
        }
        $state.Installs++
        if ($Scenario -in @('install-failure', 'install-stderr-failure')) { $global:LASTEXITCODE = 23; return }
        $state.Installed = $true; $state.UpgradeAvailable = $false
        $state.Version = if ($spec.version) { $spec.version } else { '1.0.0' }
        if ($spec.executable) { Write-FixtureFile (Get-FixtureToolPath) }
        if ($spec.id -eq 'oschwartz10612.Poppler') {
          Write-FixtureFile (Get-FixturePortablePath 'pdfinfo.exe')
          $state.NativeDrift = $false
        }
        if ($spec.id -eq 'OpenJS.NodeJS.LTS') {
          Write-FixtureFile (Get-FixturePortablePath 'node.exe')
          Write-FixtureFile (Get-FixturePortablePath 'npm.cmd')
        }
        return
      }
      if ($arguments[0] -eq 'ci') {
        Assert-Contract ('--prefix' -in $arguments -and '--ignore-scripts' -in $arguments) "resource $($Resource.name): npm prefix/script boundary differs"
        $state.Installs++
        if ($Scenario -in @('install-failure', 'install-stderr-failure')) { $global:LASTEXITCODE = 23; return }
        Install-FixtureNpm
        return
      }
      if ($Resource.metadata.application.source -eq 'winget') {
        $expected = if ($spec.id -eq 'oschwartz10612.Poppler') { Get-FixturePortablePath ([IO.Path]::GetFileName($target)) } else { Get-FixtureToolPath }
        Assert-Contract ($target -eq $expected) "resource $($Resource.name): native discovery escaped the selected package root ($target)"
        $state.SeenTools += [IO.Path]::GetFileName($target)
      }
      if ($archiveResource) {
        Assert-Contract ($target -eq (Get-FixtureToolPath) -or $target -like '*expanded*') "resource $($Resource.name): archive tool discovery escaped owned directory ($target)"
        Assert-Contract (($arguments -join ',') -eq (@($spec.versionArgs) -join ',')) "resource $($Resource.name): archive native version arguments differ"
        $state.NativeVersions++
      }
      if ($Scenario -in @('native-failure', 'version-stderr-failure')) { $global:LASTEXITCODE = 23; return }
      if ($Scenario -eq 'candidate-native-failure' -and $target -like '*expanded*') { $global:LASTEXITCODE = 23; return }
      if ($Resource.metadata.application.source -eq 'npm') {
        if ($Scenario -eq 'npm-native-version-drift') { return '0.0.1' }
        $command = [IO.Path]::GetFileNameWithoutExtension($target)
        foreach ($package in $spec.packages.PSObject.Properties) {
          if ($command -in $package.Value.bin.PSObject.Properties.Name) { return $package.Value.version }
        }
        throw "resource $($Resource.name): unexpected native wrapper $target"
      }
      if ($Scenario -eq 'version-unrecognized') { return 'fixture has no version output' }
      if ($spec.id -eq 'oschwartz10612.Poppler') {
        Assert-Contract ($arguments.Count -eq 1 -and $arguments[0] -eq '-v') "resource $($Resource.name): Poppler must use native -v"
        $name = [IO.Path]::GetFileName($target)
        Assert-Contract ($name -in @('pdftotext.exe', 'pdfinfo.exe')) "resource $($Resource.name): unexpected Poppler discovery $target"
        if ($state.NativeDrift -and (($Scenario -eq 'pdf-text-native-drift' -and $name -eq 'pdftotext.exe') -or ($Scenario -eq 'pdf-info-native-drift' -and $name -eq 'pdfinfo.exe'))) { return '0.0.1' }
        return ($state.Version -replace '-\d+$', '')
      }
      if ($Scenario -eq 'candidate-version-mismatch' -and $target -like '*expanded*') { return '0.0.1' }
      if ($target -like '*expanded*') { return $spec.version }
      if ($Scenario -eq 'msi-version-drift') { return $spec.version }
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
      Assert-Contract ($Uri -eq $spec.url) "resource $($Resource.name): archive URL differs"
      $state.Downloads++
      if ($ArchivePath) { Copy-Item -LiteralPath $ArchivePath -Destination $OutFile }
      else { Write-FixtureFile $OutFile 'fixture archive' }
    }
    function Get-FileHash {
      param($LiteralPath, $Algorithm)
      Assert-Contract ($Algorithm -eq 'SHA256') "resource $($Resource.name): archive digest algorithm differs"
      $state.Hashes++
      [PSCustomObject]@{ Hash = $(if ($Scenario -eq 'hash-failure') { '0' * 64 } else { $spec.sha256 }) }
    }
    function Expand-FixtureArchive {
      param($Archive, $Destination)
      Assert-Contract ($state.Hashes -gt $state.Extracts) "resource $($Resource.name): extraction occurred before digest verification"
      $state.Extracts++
      if ($Scenario -eq 'extraction-native-failure') { throw 'Native command failed with exit code 23' }
      if ($Scenario -ne 'candidate-missing') { Write-FixtureFile (Join-Path (Join-Path $Destination $spec.payload) $spec.executable) }
    }
    function Get-ItemProperty {
      param($Path, $ErrorAction)
      Assert-Contract ($Path -eq 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64') "resource $($Resource.name): unexpected machine runtime read"
      [PSCustomObject]@{ Installed = $(if ($Scenario -eq 'runtime-missing') { 0 } else { 1 }) }
    }
    if ($Resource.metadata.application.source -eq 'npm') {
      if ($Scenario -in @('node-machine', 'node-owned-root-exclusion')) {
        Write-FixtureFile (Join-Path $env:LOCALAPPDATA 'unrelated machine Node\node.exe')
        Write-FixtureFile (Join-Path $env:LOCALAPPDATA 'unrelated machine Node\npm.cmd')
        $env:Path = (Join-Path $env:LOCALAPPDATA 'unrelated machine Node') + [IO.Path]::PathSeparator + $env:Path
      } else {
        Write-FixtureFile (Get-FixturePortablePath 'node.exe' 'OpenJS.NodeJS.LTS')
        Write-FixtureFile (Get-FixturePortablePath 'npm.cmd' 'OpenJS.NodeJS.LTS')
      }
      if ($Scenario -eq 'node-executable-ambiguous') {
        Write-FixtureFile (Join-Path (Join-Path (Get-FixturePackageRoot 'OpenJS.NodeJS.LTS') 'second payload with spaces') 'node.exe')
      }
      if ($state.Installed) {
        Install-FixtureNpm
        $state.UserPath = Join-Path (Join-Path $env:LOCALAPPDATA $spec.directory) 'node_modules\.bin'
      }
    } elseif ($state.Installed -and $spec.executable) { Write-FixtureFile (Get-FixtureToolPath) }
    if ($state.Installed -and $spec.id -eq 'OpenJS.NodeJS.LTS') {
      Write-FixtureFile (Get-FixturePortablePath 'node.exe')
      Write-FixtureFile (Get-FixturePortablePath 'npm.cmd')
      $state.UserPath = Split-Path -Parent (Get-FixturePortablePath 'node.exe')
    }
    if ($state.Installed -and $spec.id -eq 'oschwartz10612.Poppler') {
      Write-FixtureFile (Get-FixturePortablePath 'pdfinfo.exe')
      if ($Scenario -eq 'pdf-text-missing') { Remove-Item -LiteralPath (Get-FixtureToolPath) }
      if ($Scenario -eq 'pdf-info-missing') { Remove-Item -LiteralPath (Get-FixturePortablePath 'pdfinfo.exe') }
    }
    $portable = $Resource.metadata.application.source -eq 'winget' -and $spec.executable -and $spec.id -notin @('Git.Git', 'Python.Python.3.13', 'JohnMacFarlane.Pandoc')
    $links = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
    $null = New-Item -ItemType Directory -Path $links -Force
    if ($portable) {
      # A valid-looking executable in another package is never a candidate.
      Write-FixtureFile (Get-FixturePortablePath $spec.executable 'Fixture.Unrelated')
      Write-FixtureFile (Join-Path (Join-Path $env:LOCALAPPDATA ('Microsoft\WinGet\Packages\' + $spec.id + '_Fixture.Unapproved.Source')) $spec.executable)
      Write-FixtureFile (Join-Path (Join-Path $env:LOCALAPPDATA 'unrelated PATH with spaces') $spec.executable)
      $env:Path = (Join-Path $env:LOCALAPPDATA 'unrelated PATH with spaces') + [IO.Path]::PathSeparator + $env:Path
      if ($Scenario -in @('portable-executable-missing', 'owned-root-exclusion')) { Remove-Item -LiteralPath (Get-FixtureToolPath) }
      if ($Scenario -eq 'portable-executable-ambiguous') { Write-FixtureFile (Join-Path (Join-Path (Get-FixturePackageRoot) 'second payload with spaces') $spec.executable) }
      if ($Scenario -eq 'pdf-info-ambiguous') { Write-FixtureFile (Join-Path (Join-Path (Get-FixturePackageRoot) 'second payload with spaces') 'pdfinfo.exe') }
    }
    if ($state.Installed -and $archiveResource) {
      $state.UserPath = Split-Path -Parent (Get-FixtureToolPath)
      Write-FixtureFile (Join-Path (Join-Path $env:LOCALAPPDATA $spec.directory) 'prior-directory.txt') 'preserve prior payload'
      if ($Scenario -eq 'path-drift') { $state.UserPath = '' }
      if ($Scenario -eq 'executable-missing') { Remove-Item -LiteralPath (Get-FixtureToolPath) }
    }
    if ($archiveResource -and $spec.archiveKind -eq '7z' -and -not $ArchivePath) { Write-FixtureFile (Join-Path $env:SystemRoot 'System32\tar.exe') }
    $test = ConvertTo-FixtureScript "$($Resource.name) testScript" $Resource.properties.testScript -NativeStderr:$nativeStderr
    $set = ConvertTo-FixtureScript "$($Resource.name) setScript" $Resource.properties.setScript -NativeStderr:$nativeStderr
    $failure = $null
    $desired = $null
    try {
      $desired = & $test
      $null = & $set
      if ($Scenario -in @('missing', 'missing-row', 'drift', 'upgrade', 'revision-drift', 'path-drift', 'executable-missing', 'portable-executable-missing', 'owned-root-exclusion', 'native-stderr-install', 'pdf-text-missing', 'pdf-info-missing', 'pdf-text-native-drift', 'pdf-info-native-drift', 'catalog-revision-drift', 'msi-version-drift')) {
        if ($spec.version) { $state.Version = $spec.version }
        $null = & $set
        Assert-Contract ($state.Installs -eq $(if ($archiveResource) { 0 } else { 1 })) "resource $($Resource.name): repeat apply is not idempotent"
        Assert-Contract ((& $test) -eq $true) "resource $($Resource.name): repeat apply did not reach desired state"
      }
      if ($archiveResource) { Assert-Contract ($state.NativeVersions -gt 0) "resource $($Resource.name): archive fixture never discovered a native version" }
      if ($Scenario -in @('desired', 'native-stderr-success')) {
        $null = & $set
        Assert-Contract ((& $test) -eq $true -and $state.Installs -eq 0) "resource $($Resource.name): exact installed repeat apply changed state"
      }
    } catch { $failure = $_.Exception.Message }
    $label = "resource $($Resource.name) fixture $Scenario"
    switch ($Scenario) {
      'hash-failure' { Assert-Contract ($failure -match 'SHA-256' -and $state.Extracts -eq 0) "${label}: failed hash did not stop extraction" }
      'extraction-native-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|Native (command|archive extraction) failed with exit code 23|tar failed with exit code 23)$' -and $state.Extracts -eq 1) "${label}: extraction exit 23 lost ($failure)" }
      'candidate-missing' { Assert-Contract ($failure -match 'release executable missing') "${label}: archive without native executable accepted ($failure)" }
      'promotion-failure' { Assert-Contract ($failure -eq 'fixture promotion failure') "${label}: promotion failure was swallowed ($failure)" }
      'version-unrecognized' { Assert-Contract ($failure -match 'unrecognized version output' -and $state.Downloads -eq 0) "${label}: invalid version output accepted ($failure)" }
      'path-drift' { Assert-Contract (-not $failure -and $desired -eq $false -and $state.Downloads -eq 0 -and (Split-Path -Parent (Get-FixtureToolPath)) -in @($state.UserPath -split ';')) "${label}: owned discovery path drift did not converge ($failure)" }
      'install-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$') "${label}: installer exit 23 lost ($failure)" }
      'native-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$') "${label}: executable exit 23 lost ($failure)" }
      'candidate-native-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$') "${label}: candidate executable exit 23 lost ($failure)" }
      'list-failure' {
        $expected = if ($spec.upgradeCode) { '^Windows Installer API failed$' } else { '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$' }
        Assert-Contract ($failure -match $expected -and $state.Installs -eq 0) "${label}: registration failure lost ($failure)"
      }
      'list-stderr-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$' -and $state.Installs -eq 0) "${label}: native registration stderr exit 23 lost ($failure)" }
      'install-stderr-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$' -and $state.Installs -eq 1) "${label}: native installer stderr exit 23 lost ($failure)" }
      'version-stderr-failure' { Assert-Contract ($failure -match '^(fixture-native-exit:23|(Native command|winget) failed with exit code 23)$' -and $state.Installs -eq 0) "${label}: native version stderr exit 23 lost ($failure)" }
      { $_ -in @('portable-executable-ambiguous', 'pdf-info-ambiguous', 'node-executable-ambiguous') } { Assert-Contract ($failure -match 'ambiguous' -and $state.Installs -eq 0) "${label}: ambiguous owned executable accepted ($failure)" }
      'runtime-missing' { Assert-Contract ($failure -match 'runtime is missing' -and $state.Installs -eq 0) "${label}: absent employer runtime did not block installer" }
      'node-machine' { Assert-Contract ($failure -match 'native per-user Node' -and $state.Installs -eq 0) "${label}: machine/WSL Node accepted" }
      'node-owned-root-exclusion' { Assert-Contract ($desired -eq $false -and $failure -match 'native per-user Node' -and $state.Installs -eq 0) "${label}: unrelated Node executable escaped owned-root exclusion ($failure)" }
      { $_ -in @('msi-machine', 'msi-ambiguous') } {
        $expected = if ($Scenario -eq 'msi-machine') { 'machine-context MSI product refused' } else { 'ambiguous Windows Installer related products' }
        Assert-Contract ($failure -match $expected) "${label}: invalid MSI registration accepted by test ($failure)"
        $setFailure = $null
        try { $null = & $set } catch { $setFailure = $_.Exception.Message }
        Assert-Contract ($setFailure -match $expected -and $state.Installs -eq 0) "${label}: invalid MSI registration accepted by set ($setFailure)"
      }
      'candidate-version-mismatch' { Assert-Contract ($failure -match 'version mismatch') "${label}: wrong downloaded version accepted" }
      'newer' {
        if ($spec.policy -eq 'self-updating') { Assert-Contract ($desired -eq $true -and -not $failure -and $state.Installs -eq 0) "${label}: newer self-update downgraded/reinstalled ($failure)" }
        else { Assert-Contract ($failure -match 'refusing downgrade' -and $state.Installs -eq 0) "${label}: newer exact installation downgraded ($failure)" }
      }
      'desired' { Assert-Contract ($desired -eq $true -and -not $failure -and $state.Installs -eq 0 -and $state.Downloads -eq 0) "${label}: desired installation changed ($failure)" }
      'native-stderr-success' { Assert-Contract ($desired -eq $true -and -not $failure -and $state.Installs -eq 0 -and $state.Downloads -eq 0) "${label}: exit-zero native stderr changed desired installation ($failure)" }
      'npm-version-drift' { Assert-Contract ($desired -eq $false) "${label}: manifest version drift accepted" }
      'npm-wrapper-missing' { Assert-Contract ($desired -eq $false) "${label}: missing native wrapper accepted" }
      'npm-lock-drift' { Assert-Contract ($desired -eq $false) "${label}: lock integrity drift accepted" }
      'npm-native-version-drift' { Assert-Contract ($desired -eq $false) "${label}: native command version drift accepted" }
      'msi-version-drift' { Assert-Contract ($desired -eq $false -and -not $failure) "${label}: wrong MSI version accepted despite correct executable version ($failure)" }
      default { Assert-Contract (-not $failure -and $desired -eq $false) "${label}: missing/drift did not converge ($failure)" }
    }
    if ($spec.upgradeCode) { Assert-Contract ($state.MsiOpens -gt 0 -and $state.MsiOpens -eq $state.MsiCloses) "${label}: Windows Installer COM object was not released" }
    if ($nativeStderr) { Assert-Contract ($state.StderrCommands -gt 0) "${label}: regression never invoked a real native stderr process" }
    if ($portable) {
      Assert-Contract (@(Get-ChildItem -LiteralPath $links -Force).Count -eq 0) "${label}: fixture created a WinGet link instead of PATH-mode discovery"
      Assert-Contract ((Get-FixtureToolPath).Contains('payload with spaces')) "${label}: portable fixture did not exercise nested spaces"
      if (-not $failure -and $spec.id -eq 'oschwartz10612.Poppler') {
        Assert-Contract ('pdftotext.exe' -in $state.SeenTools -and 'pdfinfo.exe' -in $state.SeenTools) "${label}: Poppler did not verify both owned native executables"
      }
    }
    if ($archiveResource -and $Scenario -in @('missing', 'drift', 'revision-drift', 'executable-missing')) {
      Assert-Contract ($state.Downloads -eq 1 -and $state.Extracts -eq 1) "${label}: archive repeat install/download is not idempotent"
      Assert-Contract ((Split-Path -Parent (Get-FixtureToolPath)) -in @($state.UserPath -split ';')) "${label}: owned native tool path was not registered"
      Assert-Contract ($caseRoot.Contains(' ')) "${label}: fixture did not exercise paths containing spaces"
    }
    if ($archiveResource -and $Scenario -in @('hash-failure', 'extraction-native-failure', 'candidate-version-mismatch', 'candidate-native-failure', 'candidate-missing', 'native-failure', 'version-unrecognized', 'promotion-failure')) {
      $prior = Join-Path (Join-Path $env:LOCALAPPDATA $spec.directory) 'prior-directory.txt'
      Assert-Contract ((Test-Path -LiteralPath $prior) -and [IO.File]::ReadAllText($prior) -ceq 'preserve prior payload') "${label}: failure destroyed the prior installation"
    }
    if ($archiveResource -and $Scenario -in @('drift', 'revision-drift', 'executable-missing')) {
      $backups = @(Get-ChildItem -LiteralPath (Split-Path -Parent (Join-Path $env:LOCALAPPDATA $spec.directory)) -Directory | Where-Object { $_.Name -like ((Split-Path -Leaf (Join-Path $env:LOCALAPPDATA $spec.directory)) + '.previous-*') })
      Assert-Contract ($backups.Count -eq 1 -and [IO.File]::ReadAllText((Join-Path $backups[0].FullName 'prior-directory.txt')) -ceq 'preserve prior payload') "${label}: successful replacement did not preserve the prior directory"
    }
    Write-Output "fixture passed: $label"
  } finally {
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
    Remove-Item -LiteralPath $caseRoot -Recurse -Force
  }
}
