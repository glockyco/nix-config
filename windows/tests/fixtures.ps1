function Copy-FixtureObject {
  param($Value)
  $Value | ConvertTo-Json -Depth 100 | ConvertFrom-Json
}

function Assert-FixtureRejection {
  param([string]$FixtureName, [scriptblock]$Action, [string]$Finding)
  $failure = $null
  try { $null = & $Action } catch { $failure = $_.Exception.Message }
  Assert-Contract ($failure -and $failure -match $Finding) "fixture ${FixtureName}: expected named rejection matching $Finding, got $failure"
  Write-Output "fixture passed: $FixtureName (rejected: $failure)"
}

function Invoke-NativeFixtures {
  param($Document, $Managed, [string]$WindowsRoot)
  $root = Join-Path ([IO.Path]::GetTempPath()) ('Windows native fixtures with spaces ' + [guid]::NewGuid().ToString())
  $null = New-Item -ItemType Directory -Path $root
  $saved = @{}
  foreach ($name in @('HOME', 'USERPROFILE', 'LOCALAPPDATA', 'APPDATA', 'TEMP')) {
    $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    [Environment]::SetEnvironmentVariable($name, $root, 'Process')
  }
  try {
    Test-WindowsDocument (Copy-FixtureObject $Document) $Managed
    . (Join-Path $WindowsRoot 'tests/schema-fixtures.ps1')
    Invoke-SchemaFixtures $Document $WindowsRoot $root
    Write-Output 'fixture passed: unchanged declaration including per-user Git and approved Zen/Tailscale exceptions'
    $cases = @(
      @{ Name = 'duplicate resource'; Finding = 'resource .+: duplicate name'; Edit = { param($d) $d.resources += $d.resources[0] } },
      @{ Name = 'undeclared dependency'; Finding = 'resource .+: undeclared/self dependency absent-fixture'; Edit = { param($d) $d.resources[0] | Add-Member dependsOn @('absent-fixture') -Force } },
      @{ Name = 'dependency cycle'; Finding = 'resource .+: dependency cycle'; Edit = { param($d) $d.resources[0] | Add-Member dependsOn @("[resourceId('$($d.resources[1].type)', '$($d.resources[1].name)')]") -Force; $d.resources[1] | Add-Member dependsOn @("[resourceId('$($d.resources[0].type)', '$($d.resources[0].name)')]") -Force } },
      @{ Name = 'dependency type mismatch'; Finding = 'resource .+: dependency .+ must use resourceId with its declared type'; Edit = { param($d) $d.resources[0] | Add-Member dependsOn @("[resourceId('Microsoft.Windows/Registry', '$($d.resources[1].name)')]") -Force } },
      @{ Name = 'schema'; Finding = '\$schema'; Edit = { param($d) $d.'$schema' = 'https://invalid.example/schema' } },
      @{ Name = 'processor'; Finding = 'metadata: expected dscv3'; Edit = { param($d) $d.metadata.winget.processor.identifier = 'not-dsc' } },
      @{ Name = 'missing application metadata'; Finding = 'resource .+: missing application metadata'; Edit = { param($d) $d.resources[0].type = 'Microsoft.WinGet/Package'; $d.resources[0].metadata.PSObject.Properties.Remove('application') } },
      @{ Name = 'no version policy'; Finding = 'resource .+: missing/ambiguous version policy'; Edit = { param($d) $d.resources[0].metadata.application.PSObject.Properties.Remove('versionPolicy') } },
      @{ Name = 'multiple version policies'; Finding = 'resource .+: missing/ambiguous version policy'; Edit = { param($d) $d.resources[0].metadata.application.versionPolicy = @('exact', 'self-updating') } },
      @{ Name = 'self-update with pin'; Finding = 'resource .+: invalid version selector'; Edit = { param($d) $d.resources[0].metadata.application | Add-Member version '0.0.1' } },
      @{ Name = 'exact without pin'; Finding = 'resource .+: invalid version selector'; Edit = { param($d) ($d.resources | Where-Object name -eq 'package git client').metadata.application.PSObject.Properties.Remove('version') } },
      @{ Name = 'package selector mismatch'; Finding = 'resource .+: package identity/source selector differs'; Edit = { param($d) $d.resources[0].type = 'Microsoft.WinGet/Package'; $d.resources[0].properties = [PSCustomObject]@{ id = 'Wrong.ID'; source = 'winget'; useLatest = $true } } },
      @{ Name = 'self-update without latest'; Finding = 'resource .+: self-updating/latest selector differs'; Edit = { param($d) $d.resources[0].type = 'Microsoft.WinGet/Package'; $d.resources[0].properties = [PSCustomObject]@{ id = $d.resources[0].metadata.application.id; source = 'winget'; useLatest = $false } } },
      @{ Name = 'exact selector mismatch'; Finding = 'resource .+: exact version selector differs'; Edit = { param($d) $d.resources += [PSCustomObject]@{ name = 'fixture exact package'; type = 'Microsoft.WinGet/Package'; metadata = [PSCustomObject]@{ application = [PSCustomObject]@{ id = 'Fixture.Exact'; source = 'winget'; scope = 'user'; roles = @('fixture-exact'); versionPolicy = 'exact'; version = '1.0.0' } }; properties = [PSCustomObject]@{ id = 'Fixture.Exact'; source = 'winget'; version = '0.0.1'; useLatest = $false } } } },
      @{ Name = 'Docker exclusion'; Finding = 'resource .+: centrally managed identifier Docker.DockerDesktop'; Edit = { param($d) $d.resources[0].metadata.application.id = 'Docker.DockerDesktop' } },
      @{ Name = 'another audited exclusion'; Finding = 'resource .+: centrally managed identifier Google.Chrome'; Edit = { param($d) $d.resources[0].metadata.application.id = 'Google.Chrome' } },
      @{ Name = 'machine scope expansion'; Finding = 'resource .+: unapproved application scope'; Edit = { param($d) $d.resources[0].metadata.application.scope = 'machine' } },
      @{ Name = 'Zen wrong scope'; Finding = 'resource .+: unapproved application scope'; Edit = { param($d) ($d.resources | Where-Object name -eq 'package browser').metadata.application.scope = 'user' } },
      @{ Name = 'Tailscale wrong scope'; Finding = 'resource .+: unapproved application scope'; Edit = { param($d) ($d.resources | Where-Object { $_.metadata.application.id -eq 'Tailscale.Tailscale' }).metadata.application.scope = 'user' } },
      @{ Name = 'elevated user apply'; Finding = 'resource .+: unapproved elevated resource'; Edit = { param($d) $d.resources[0].metadata | Add-Member winget ([PSCustomObject]@{ securityContext = 'elevated' }) -Force } },
      @{ Name = 'feature declaration'; Finding = 'resource .+: Windows feature is forbidden'; Edit = { param($d) $d.resources[0].type = 'Microsoft.Windows/OptionalFeatureList' } },
      @{ Name = 'HKLM declaration'; Finding = 'resource .+: forbidden machine registry'; Edit = { param($d) $d.resources[0].properties | Add-Member keyPath 'HKLM\Software\Fixture' } },
      @{ Name = 'CloudStore'; Finding = 'resource .+: forbidden machine registry/CloudStore'; Edit = { param($d) $d.resources[0].properties | Add-Member keyPath 'HKCU\Software\CloudStore' } },
      @{ Name = 'default association'; Finding = 'resource .+: forbidden machine registry/CloudStore/default-association'; Edit = { param($d) $d.resources[0].properties | Add-Member keyPath 'HKCU\Software\UserChoice' } },
      @{ Name = 'feature script'; Finding = 'script .+: feature/service ownership is forbidden'; Edit = { param($d) $d.resources[0].properties.setScript += "`nAdd-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'" } },
      @{ Name = 'HKLM script'; Finding = 'script .+: document-owned HKLM path'; Edit = { param($d) $d.resources[0].properties.setScript += "`nNew-Item -Path 'HKLM:\Software\Fixture'" } },
      @{ Name = 'Administrator profile confusion'; Finding = 'script .+: hard-coded user/Administrator profile confusion'; Edit = { param($d) $d.resources[0].properties.setScript += "`n`$path = 'C:\Users\Administrator\profile.txt'" } },
      @{ Name = 'CloudStore claim'; Finding = 'resource .+: forbidden CloudStore/default-association/taskbar-pinning claim'; Edit = { param($d) $d.resources[0].metadata.description = 'Manage CloudStore taskbar pins' } },
      @{ Name = 'relay profile writer'; Finding = 'resource .+: relay/communication startup or profile ownership is forbidden'; Edit = { param($d) ($d.resources | Where-Object name -eq 'windows dark appearance').properties.setScript += "`n`$profile = 'BraveSoftware\Brave-Browser\User Data'" } },
      @{ Name = 'relay installer startup writer'; Finding = 'script .+: relay/communication startup or profile ownership is forbidden'; Edit = { param($d) ($d.resources | Where-Object { $_.metadata.application.id -eq 'Brave.Brave' }).properties.setScript += "`nNew-Item -Path 'BraveSoftware\Brave-Browser\User Data'" } },
      @{ Name = 'Neo ordering'; Finding = 'script german input methods .+: German QWERTZ must precede native Neo'; Edit = { param($d) $r = $d.resources | Where-Object name -eq 'german input methods'; $r.properties.testScript = $r.properties.testScript.Replace("@('0407:00000407', '0407:b0000407')", "@('0407:b0000407', '0407:00000407')") } },
      @{ Name = 'Neo default'; Finding = 'script german input methods .+: native Neo must not be the default'; Edit = { param($d) $r = $d.resources | Where-Object name -eq 'german input methods'; $r.properties.testScript = $r.properties.testScript.Replace("`$default = '0407:00000407'", "`$default = '0407:b0000407'") } },
      @{ Name = 'dark theme path'; Finding = 'resource windows dark appearance: dark acceptance'; Edit = { param($d) $r = $d.resources | Where-Object name -eq 'windows dark appearance'; $r.properties.testScript += "`n`$theme = 'Custom.theme'" } },
      @{ Name = 'inline syntax'; Finding = 'script german input methods testScript: .+at'; Edit = { param($d) ($d.resources | Where-Object name -eq 'german input methods').properties.testScript = 'if (' } },
      @{ Name = 'installer scope execution'; Finding = 'resource .+: installer must enforce'; Edit = { param($d) $r = $d.resources | Where-Object { $_.metadata.application.id -eq 'twpayne.chezmoi' }; $r.properties.setScript = $r.properties.setScript.Replace("'--scope', 'user'", "'--scope', 'machine'") } },
      @{ Name = 'installer metadata version'; Finding = 'resource .+: installer version differs'; Edit = { param($d) ($d.resources | Where-Object { $_.metadata.application.id -eq 'twpayne.chezmoi' }).metadata.application.version = '0.0.1' } },
      @{ Name = 'npm integrity mismatch'; Finding = 'resource .+: npm metadata/lock selector differs'; Edit = { param($d) ($d.resources | Where-Object { $_.metadata.application.source -eq 'npm' }).metadata.npmPackages.pyright.integrity = 'sha512-Zml4dHVyZQ==' } },
      @{ Name = 'launcher syntax'; Finding = 'embedded start-reneo-elevated.ps1'; Edit = { param($d) $r = $d.resources | Where-Object name -eq 'reneo elevation launcher'; $r.properties.testScript = "`$desired = @'`nReNeo`nif (`n'@" } }
    )
    foreach ($case in $cases) {
      $changed = Copy-FixtureObject $Document
      $null = & $case.Edit $changed
      Assert-FixtureRejection $case.Name { Test-WindowsDocument $changed $Managed } $case.Finding
    }
    Assert-FixtureRejection 'automatic fixed Administrator invocation' { Test-ApprovedScriptRole (Get-ScriptRecord 'rendered user apply.ps1' "& '.\apply-kbdneo.ps1'") } 'fixed Administrator scripts must not run automatically'
    foreach ($name in @('apply-kbdneo.ps1', 'apply-zen-policies.ps1')) {
      $source = [IO.File]::ReadAllText((Join-Path $WindowsRoot $name))
      Test-AdministratorScript (Get-ScriptRecord $name $source) $name
      Assert-FixtureRejection "$name copied Administrator program" { Test-ApprovedScriptRole (Get-ScriptRecord 'other-admin.ps1' $source) } 'script other-admin.ps1: unapproved Administrator program'
      # Rename the principal and file destinations and reflow commands; no source-text boundary coupling.
      $refactored = $source.Replace('$principal', '$administratorIdentity').Replace('$path', '$ownedDestination').Replace('$registryPath', '$ownedRegistration').Replace('Join-Path ', 'Join-Path  ')
      Test-AdministratorScript (Get-ScriptRecord $name $refactored) $name
      Write-Output "fixture passed: $name AST refactor"
      & {
        $record = Get-ScriptRecord $name $source
        $guard = @($record.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.IfStatementAst] }, $true) | Where-Object {
          @($_.Clauses[0].Item1.FindAll({ param($n) $n -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and $n.Member.Value -eq 'IsInRole' }, $true)).Count -gt 0
        })[0]
        $principalName = @($guard.Clauses[0].Item1.FindAll({ param($n) $n -is [System.Management.Automation.Language.VariableExpressionAst] }, $true))[0].VariablePath.UserPath
        $principalDouble = [PSCustomObject]@{}
        $principalDouble | Add-Member ScriptMethod IsInRole { param($Role) return $false }
        Set-Variable -Name $principalName -Value $principalDouble
        Assert-FixtureRejection "$name unelevated guard" { & ([scriptblock]::Create($guard.Extent.Text)) } 'Administrator PowerShell session'
      }
      foreach ($suffix in @('`$env:USERPROFILE', '`$env:LOCALAPPDATA', '`$HOME', '`$PROFILE')) {
        $bad = $source + "`n" + $suffix.Replace('`$', '$')
        Assert-FixtureRejection "$name profile variable" { Test-AdministratorScript (Get-ScriptRecord $name $bad) $name } 'script .+: forbidden profile variable'
      }
      foreach ($path in @('HKCU:\Software\Fixture', 'C:\Windows\outside-owned.txt', 'HKLM:\Software\Fixture')) {
        $bad = $source + "`n`$fixture = '$path'"
        Assert-FixtureRejection "$name path $path" { Test-AdministratorScript (Get-ScriptRecord $name $bad) $name } 'script .+: (forbidden profile/registry|machine path|machine registry)'
      }
      $bad = $source + "`nNew-NetFirewallRule -Name fixture"
      Assert-FixtureRejection "$name service expansion" { Test-AdministratorScript (Get-ScriptRecord $name $bad) $name } 'script .+: command outside fixed ownership'
      $bad = $source.Replace('IsInRole', 'Equals')
      Assert-FixtureRejection "$name no elevation guard" { Test-AdministratorScript (Get-ScriptRecord $name $bad) $name } 'script .+: (member outside fixed ownership|missing unelevated-write rejection)'
      $bad = $source + "`n[IO.File]::WriteAllText('outside-owned.txt', 'fixture')"
      Assert-FixtureRejection "$name relative write expansion" { Test-AdministratorScript (Get-ScriptRecord $name $bad) $name } 'script .+: resolved path outside fixed ownership'
      $bad = $source + "`nNew-Item 'outside-owned.txt' -Force"
      Assert-FixtureRejection "$name positional write expansion" { Test-AdministratorScript (Get-ScriptRecord $name $bad) $name } 'script .+: resolved path outside fixed ownership'
      $bad = $source.Replace("`$ErrorActionPreference = 'Stop'", "`$ErrorActionPreference = 'Stop'`nNew-Item -Path 'fixture-write-before-guard'")
      Assert-FixtureRejection "$name write before guard" { Test-AdministratorScript (Get-ScriptRecord $name $bad) $name } 'script .+: write precedes Administrator guard'
      if ($name -eq 'apply-zen-policies.ps1') {
        $bad = $source.Replace('Zen Browser\distribution\policies.json', 'Other App\distribution\policies.json')
        Assert-FixtureRejection "$name Program Files expansion" { Test-AdministratorScript (Get-ScriptRecord $name $bad) $name } 'script .+: joined path outside fixed ownership'
      } else {
        $bad = $source.Replace('"layoutId":"b0000407"', '"layoutId":"a0000407"')
        Assert-FixtureRejection "$name registration expansion" { Test-AdministratorScript (Get-ScriptRecord $name $bad) $name } 'script .+: ownership must remain b0000407/kbdneo2.dll'
      }
      Assert-FixtureRejection "$name syntax error" { Get-ScriptRecord $name ($source + "`nif (") } 'script .+: .+at'
    }
    # Exercise the shipped dark test against Custom.theme-compatible desired values, not theme identity.
    & {
      function Get-ItemProperty {
        param($Path, $ErrorAction)
        $appearance
      }
      $previous = $env:WINDIR
      $env:WINDIR = $root
      $appearance = [PSCustomObject]@{ AppsUseLightTheme = 0; SystemUsesLightTheme = 0; EnableTransparency = 0; WallPaper = (Join-Path $env:WINDIR 'Web\Wallpaper\Windows\img19.jpg'); CurrentTheme = 'Custom.theme' }
      try {
        $resource = $Document.resources | Where-Object name -eq 'windows dark appearance'
        Assert-Contract ((& ([scriptblock]::Create($resource.properties.testScript))) -eq $true) 'resource windows dark appearance: Custom.theme desired-state fixture failed'
        foreach ($property in @('AppsUseLightTheme', 'SystemUsesLightTheme', 'EnableTransparency', 'WallPaper')) {
          $desiredValue = $appearance.$property
          $appearance.$property = if ($property -eq 'WallPaper') { 'wrong wallpaper' } else { 1 }
          Assert-Contract ((& ([scriptblock]::Create($resource.properties.testScript))) -eq $false) "resource windows dark appearance: drift fixture $property was accepted"
          $appearance.$property = $desiredValue
        }
      } finally { $env:WINDIR = $previous }
    }
    Write-Output 'fixture passed: dark appearance accepts Custom.theme'
    . (Join-Path $WindowsRoot 'tests/installer-doubles.ps1')
    foreach ($resource in @($Document.resources | Where-Object { $_.type -eq 'Microsoft.DSC.Transitional/WindowsPowerShellScript' -and $_.metadata.application.source -eq 'winget' })) {
      $spec = @(Get-EmbeddedJson (Get-ScriptRecord $resource.name $resource.properties.setScript))[0]
      foreach ($scenario in @('desired', 'missing', 'missing-row', 'drift', 'newer', 'list-failure', 'install-failure')) { Invoke-InstallerFixture $resource $scenario $root }
      if (-not $spec.registrationOnly) { Invoke-InstallerFixture $resource 'native-failure' $root }
      if ($spec.requiresVCRuntime) { Invoke-InstallerFixture $resource 'runtime-missing' $root }
      if ($spec.policy -eq 'self-updating') { Invoke-InstallerFixture $resource 'upgrade' $root }
    }
    foreach ($resource in @($Document.resources | Where-Object { $_.metadata.application.source -eq 'official-zip' })) {
      foreach ($scenario in @('desired', 'missing', 'drift', 'newer', 'hash-failure', 'native-failure', 'candidate-version-mismatch', 'candidate-native-failure')) { Invoke-InstallerFixture $resource $scenario $root }
    }
    foreach ($resource in @($Document.resources | Where-Object { $_.metadata.application.source -eq 'npm' })) {
      foreach ($scenario in @('desired', 'missing', 'newer', 'native-failure', 'install-failure', 'npm-version-drift', 'npm-wrapper-missing', 'npm-lock-drift', 'npm-native-version-drift', 'node-machine')) { Invoke-InstallerFixture $resource $scenario $root }
    }
    # The public entrypoint must return nonzero and preserve names, independently of helper throws.
    $engine = (Get-Process -Id $PID).Path
    $fixturePath = Join-Path $root 'invalid document.winget'
    $invalid = Copy-FixtureObject $Document
    $invalid.resources[0] | Add-Member dependsOn @('missing-resource') -Force
    [IO.File]::WriteAllText($fixturePath, ($invalid | ConvertTo-Json -Depth 100))
    $ErrorActionPreference = 'Continue'
    $output = & $engine -NoProfile -NonInteractive -File (Join-Path $WindowsRoot 'check.ps1') -DocumentPath $fixturePath -SkipFixtures 2>&1
    $ErrorActionPreference = 'Stop'
    Assert-Contract ($LASTEXITCODE -ne 0 -and ($output -join "`n") -match 'resource .+: undeclared/self dependency missing-resource') 'fixture entrypoint: invalid document did not return named nonzero failure'
    $scriptPath = Join-Path $root 'broken rendered script.ps1'
    [IO.File]::WriteAllText($scriptPath, 'if (')
    $documentPath = Join-Path $root 'valid document.winget'
    [IO.File]::WriteAllText($documentPath, ($Document | ConvertTo-Json -Depth 100))
    $firstRendered = Join-Path $root 'first rendered.ps1'
    $secondRendered = Join-Path $root 'second rendered.ps1'
    [IO.File]::WriteAllText($firstRendered, 'param(); $value = @{ desired = $true }')
    [IO.File]::WriteAllText($secondRendered, 'function Test-Rendered { return $true }')
    $wrapper = Join-Path $root 'rendered array invocation.ps1'
    $checkPath = (Join-Path $WindowsRoot 'check.ps1').Replace("'", "''")
    $quotedDocument = $documentPath.Replace("'", "''")
    $quotedFirst = $firstRendered.Replace("'", "''")
    $quotedSecond = $secondRendered.Replace("'", "''")
    [IO.File]::WriteAllText($wrapper, "& '$checkPath' -DocumentPath '$quotedDocument' -AdditionalScriptPath @('$quotedFirst', '$quotedSecond') -SkipFixtures")
    $ErrorActionPreference = 'Continue'
    $output = & $engine -NoProfile -NonInteractive -File $wrapper 2>&1
    $ErrorActionPreference = 'Stop'
    Assert-Contract ($LASTEXITCODE -eq 0) "fixture entrypoint: valid rendered-script array failed: $($output -join '; ')"
    Write-Output 'fixture passed: AdditionalScriptPath array and paths with spaces'
    $ErrorActionPreference = 'Continue'
    $output = & $engine -NoProfile -NonInteractive -File (Join-Path $WindowsRoot 'check.ps1') -DocumentPath $documentPath -AdditionalScriptPath $scriptPath -SkipFixtures 2>&1
    $ErrorActionPreference = 'Stop'
    Assert-Contract ($LASTEXITCODE -ne 0 -and ($output -join "`n") -match 'broken rendered script.ps1:') 'fixture entrypoint: rendered syntax error did not return named nonzero failure'
    Write-Output 'fixture passed: public entrypoint nonzero document/rendered syntax failures'
  } finally {
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
    Remove-Item -LiteralPath $root -Recurse -Force
  }
}
