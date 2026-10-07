# Shared by the entrypoint and isolated fixtures. Compatible with Windows PowerShell 5.1.
function Assert-Contract {
  param([bool]$Condition, [string]$Finding)
  if (-not $Condition) { throw $Finding }
}

function Get-ScriptRecord {
  param([string]$Name, [string]$Source)
  $tokens = $null
  $errors = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput($Source, [ref]$tokens, [ref]$errors)
  Assert-Contract ($errors.Count -eq 0) "script ${Name}: $(@($errors | ForEach-Object { "$($_.ErrorId) at $($_.Extent.StartLineNumber): $($_.Message)" }) -join '; ')"
  $strings = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -or $n -is [System.Management.Automation.Language.ExpandableStringExpressionAst] }, $true))
  $variables = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.VariableExpressionAst] }, $true))
  $commands = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true))
  $members = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.InvokeMemberExpressionAst] }, $true))
  [PSCustomObject]@{ Name = $Name; Ast = $ast; Strings = $strings; Variables = $variables; Commands = $commands; Members = $members }
}

function ConvertFrom-NpmLockJson {
  param([string]$Text)
  if ($PSVersionTable.PSVersion.Major -ge 6) { return (ConvertFrom-Json -InputObject $Text -AsHashtable) }
  Add-Type -AssemblyName System.Web.Extensions
  $serializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
  return $serializer.DeserializeObject($Text)
}

function Get-EmbeddedJson {
  param($Record)
  foreach ($node in $Record.Strings) {
    if ($node.Value.TrimStart().StartsWith('{')) {
      try { $node.Value | ConvertFrom-Json } catch { continue }
    }
  }
}

function Test-ApprovedScriptRole {
  param($Record, [bool]$AllowedAdministrator = $false)
  $guards = @($Record.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.IfStatementAst] }, $true) | Where-Object {
    $condition = $_.Clauses[0].Item1
    @($condition.FindAll({ param($n) $n -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and $n.Member.Value -eq 'IsInRole' }, $true)).Count -gt 0 -and
      @($condition.FindAll({ param($n) $n -is [System.Management.Automation.Language.UnaryExpressionAst] -and $n.TokenKind -eq 'Not' }, $true)).Count -gt 0 -and
      @($_.Clauses[0].Item2.FindAll({ param($n) $n -is [System.Management.Automation.Language.ThrowStatementAst] }, $true)).Count -gt 0
  })
  Assert-Contract ($AllowedAdministrator -or $guards.Count -eq 0) "script $($Record.Name): unapproved Administrator program"
  if (-not $AllowedAdministrator) {
    foreach ($command in $Record.Commands) {
      $targets = @($command.CommandElements[0].FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -or $n -is [System.Management.Automation.Language.ExpandableStringExpressionAst] }, $true))
      Assert-Contract (@($targets | Where-Object { $_.Value -match 'apply-(kbdneo|zen-policies)\.ps1$' }).Count -eq 0) "script $($Record.Name): fixed Administrator scripts must not run automatically"
    }
  }
}


function Test-AdministratorScript {
  param($Record, [string]$Name)
  $label = "script $Name"
  Assert-Contract ($Name -in @('apply-kbdneo.ps1', 'apply-zen-policies.ps1')) "${label}: unapproved Administrator script"
  foreach ($variable in $Record.Variables) {
    $value = $variable.VariablePath.UserPath
    Assert-Contract ($value -notmatch '^(env:)?(APPDATA|LOCALAPPDATA|USERPROFILE|HOMEPATH|HOMEDRIVE|HOME|PROFILE)$') "${label}: forbidden profile variable $value"
    if ($value -like 'env:*') {
      $allowed = if ($Name -eq 'apply-kbdneo.ps1') { @('env:SystemRoot', 'env:TEMP') } else { @('env:ProgramFiles') }
      Assert-Contract ($value -in $allowed) "${label}: environment path outside ownership $value"
    }
  }
  foreach ($node in $Record.Strings) {
    $value = $node.Value
    Assert-Contract ($value -notmatch '(?i)(HKCU|HKEY_CURRENT_USER|CloudStore|[\\/]Users[\\/]|%USERPROFILE%|%APPDATA%|%LOCALAPPDATA%)') "${label}: forbidden profile/registry string $value"
    Assert-Contract ($value -notmatch '^[A-Za-z]:[\\/]|^\\\\|(^|[\\/])\.\.([\\/]|$)') "${label}: machine path outside ownership $value"
    if ($value -match '(?i)HKLM|HKEY_LOCAL_MACHINE') {
      Assert-Contract ($Name -eq 'apply-kbdneo.ps1' -and $value -like 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\*' -and ($value.EndsWith('b0000407') -or $node -is [System.Management.Automation.Language.ExpandableStringExpressionAst])) "${label}: machine registry outside Neo ownership $value"
    }
    if ($value -match '^(?i)(System32|SysWOW64)[\\/]') {
      Assert-Contract ($Name -eq 'apply-kbdneo.ps1' -and ($value -match '^((System32|SysWOW64)\\)(kbdneo2\.dll|\$\(.+\.layoutFile\))$')) "${label}: DLL path outside Neo ownership $value"
    }
    if ($value -match '^(?i)Zen Browser[\\/]') {
      Assert-Contract ($Name -eq 'apply-zen-policies.ps1' -and $value -in @('Zen Browser\zen.exe', 'Zen Browser\distribution\policies.json')) "${label}: Program Files path outside Zen ownership $value"
    }
  }
  $allowedCommands = @('Join-Path', 'Get-ItemProperty', 'Test-Path', 'Get-FileHash', 'Write-Output', 'ConvertFrom-Json', 'Invoke-WebRequest', 'Remove-Item', 'Add-Type', 'Copy-Item', 'New-Item', 'New-ItemProperty', 'Out-Null', 'Split-Path')
  foreach ($command in $Record.Commands) {
    Assert-Contract ($command.GetCommandName() -in $allowedCommands) "${label}: command outside fixed ownership $($command.GetCommandName())"
    if ($command.GetCommandName() -eq 'Join-Path') {
      $children = @($command.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] -or $_ -is [System.Management.Automation.Language.ExpandableStringExpressionAst] } | Select-Object -Skip 1)
      foreach ($child in $children) {
        $allowedChild = if ($Name -eq 'apply-zen-policies.ps1') {
          $child.Value -in @('Zen Browser\zen.exe', 'Zen Browser\distribution\policies.json')
        } else {
          $child.Value -in @('kbdneo64.zip', 'kbdneo64') -or $child.Value -match '^(System32|SysWOW64)\\(kbdneo2\.dll|\$\(.+\.layoutFile\))$'
        }
        Assert-Contract $allowedChild "${label}: joined path outside fixed ownership $($child.Value)"
      }
    }
  }
  foreach ($member in $Record.Members) {
    Assert-Contract ($member.Member.Value -in @('GetCurrent', 'IsInRole', 'ToLowerInvariant', 'ExtractToDirectory', 'ReadAllText', 'WriteAllText', 'new')) "${label}: member outside fixed ownership $($member.Member.Value)"
  }
  # Discover guards semantically, not by variable name or source formatting.
  $guards = @($Record.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.IfStatementAst] }, $true) | Where-Object {
    $calls = @($_.Clauses[0].Item1.FindAll({ param($n) $n -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and $n.Member.Value -eq 'IsInRole' }, $true))
    $throws = @($_.Clauses[0].Item2.FindAll({ param($n) $n -is [System.Management.Automation.Language.ThrowStatementAst] }, $true))
    $administrator = @($_.Clauses[0].Item1.FindAll({ param($n) $n -is [System.Management.Automation.Language.MemberExpressionAst] -and $n.Member.Value -eq 'Administrator' }, $true))
    $calls.Count -gt 0 -and $administrator.Count -gt 0 -and $throws.Count -gt 0 -and @($_.Clauses[0].Item1.FindAll({ param($n) $n -is [System.Management.Automation.Language.UnaryExpressionAst] -and $n.TokenKind -eq 'Not' }, $true)).Count -gt 0
  })
  Assert-Contract ($guards.Count -gt 0) "${label}: missing unelevated-write rejection"
  $writes = @($Record.Commands | Where-Object { $_.GetCommandName() -in @('Invoke-WebRequest', 'Remove-Item', 'Copy-Item', 'New-Item', 'New-ItemProperty') }) + @($Record.Members | Where-Object { $_.Member.Value -in @('WriteAllText', 'ExtractToDirectory') })
  foreach ($write in $writes) {
    Assert-Contract ($guards[0].Extent.EndOffset -lt $write.Extent.StartOffset) "${label}: write precedes Administrator guard"
  }
  if ($Name -eq 'apply-kbdneo.ps1') {
    $specs = @(Get-EmbeddedJson $Record | Where-Object { $_.PSObject.Properties['layoutId'] })
    Assert-Contract ($specs.Count -eq 1 -and $specs[0].layoutId -eq 'b0000407' -and $specs[0].layoutFile -eq 'kbdneo2.dll') "${label}: ownership must remain b0000407/kbdneo2.dll"
    foreach ($key in @('archiveSha256', 'system32Sha256', 'sysWow64Sha256')) {
      Assert-Contract ($specs[0].$key -match '^[a-fA-F0-9]{64}$') "${label}: missing pinned $key"
    }
    $bits = @($Record.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.IfStatementAst] }, $true) | Where-Object {
      @($_.Clauses[0].Item1.FindAll({ param($n) $n -is [System.Management.Automation.Language.MemberExpressionAst] -and $n.Member.Value -eq 'Is64BitProcess' }, $true)).Count -gt 0 -and
        @($_.Clauses[0].Item1.FindAll({ param($n) $n -is [System.Management.Automation.Language.UnaryExpressionAst] -and $n.TokenKind -eq 'Not' }, $true)).Count -gt 0 -and
        @($_.Clauses[0].Item2.FindAll({ param($n) $n -is [System.Management.Automation.Language.ThrowStatementAst] }, $true)).Count -gt 0
    })
    Assert-Contract ($bits.Count -gt 0) "${label}: missing 64-bit process prerequisite"
    foreach ($write in $writes) { Assert-Contract ($bits[0].Extent.EndOffset -lt $write.Extent.StartOffset) "${label}: write precedes 64-bit process guard" }
  }
  Test-AdministratorPaths $Record $Name
}

function Test-DocumentScriptBoundary {
  param($Record, $Application)
  Test-ApprovedScriptRole $Record
  $label = "script $($Record.Name)"
  if ($Application.id -in @('Brave.Brave', 'Ferdium.Ferdium')) {
    $writers = @($Record.Commands | Where-Object { $_.GetCommandName() -in @('New-Item', 'New-ItemProperty', 'Set-ItemProperty', 'Remove-ItemProperty', 'Set-Content', 'Add-Content', 'Copy-Item', 'Move-Item', 'Remove-Item', 'Start-Process', 'Register-ScheduledTask') })
    $writers += @($Record.Members | Where-Object { $_.Member.Value -in @('WriteAllText', 'WriteAllBytes', 'SetValue') })
    Assert-Contract ($writers.Count -eq 0) "${label}: relay/communication startup or profile ownership is forbidden"
  }
  foreach ($node in $Record.Strings) {
    $value = $node.Value
    Assert-Contract ($value -notmatch '(?i)CloudStore|DefaultAssociations|UserChoice|SetUserFTA|DISM.+DefaultApp') "${label}: forbidden CloudStore/default-association claim $value"
    Assert-Contract ($value -notmatch '(?i)[\\/]Users[\\/][^\\/]') "${label}: hard-coded user/Administrator profile confusion"
  }
  foreach ($command in $Record.Commands) {
    Assert-Contract ($command.GetCommandName() -notin @('Enable-WindowsOptionalFeature', 'Add-WindowsCapability', 'Install-WindowsFeature', 'New-NetFirewallRule', 'Set-Service', 'Start-Service')) "${label}: feature/service ownership is forbidden"
  }
  # HKLM is allowed only as a Neo prerequisite read. User scripts must not own machine paths.
  $machine = @($Record.Strings | Where-Object { $_.Value -match '(?i)^(Registry::)?(HKLM|HKEY_LOCAL_MACHINE)' })
  foreach ($node in $machine) {
    $neoRead = $node.Value -eq 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\b0000407' -and $node.Parent -is [System.Management.Automation.Language.CommandAst] -and $node.Parent.GetCommandName() -eq 'Test-Path'
    $runtimeRead = $node.Value -eq 'HKLM:\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64' -and $node.Parent -is [System.Management.Automation.Language.CommandAst] -and $node.Parent.GetCommandName() -eq 'Get-ItemProperty'
    Assert-Contract ($neoRead -or $runtimeRead) "${label}: document-owned HKLM path $($node.Value)"
  }
}

function Test-ScriptInstaller {
  param($Resource, $TestRecord, $SetRecord)
  $app = $Resource.metadata.application
  $label = "resource $($Resource.name)"
  $specs = @(Get-EmbeddedJson $SetRecord | Where-Object { $_.id -eq $app.id })
  if ($app.source -eq 'winget') {
    Assert-Contract ($specs.Count -eq 1) "${label}: installer specification missing or ambiguous"
    $spec = $specs[0]
    Assert-Contract ($spec.scope -eq $app.scope -and $spec.source -eq $app.source) "${label}: installer scope/source differs from metadata"
    Assert-Contract ($spec.policy -eq $app.versionPolicy) "${label}: installer version policy differs from metadata"
    if ($app.versionPolicy -eq 'self-updating') { Assert-Contract (-not $spec.PSObject.Properties['version']) "${label}: self-updating installer must not carry a version pin" }
    if ($app.versionPolicy -eq 'exact') { Assert-Contract ($spec.version -eq $app.version) "${label}: installer version differs from metadata" }
    $arrays = @($SetRecord.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ArrayExpressionAst] }, $true) | Where-Object {
      @($_.FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $n.Value -eq 'install' }, $true)).Count -gt 0
    })
    $direct = @($SetRecord.Commands | Where-Object {
      $_.GetCommandName() -eq 'winget' -and @($_.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.StringConstantExpressionAst] -and $_.Value -eq 'install' }).Count -gt 0
    })
    Assert-Contract ($arrays.Count + $direct.Count -eq 1) "${label}: expected one explicit WinGet installer argument declaration"
    $selector = if ($arrays.Count -eq 1) { $arrays[0] } else { $direct[0] }
    $args = if ($arrays.Count -eq 1) {
      @($arrays[0].FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true) | ForEach-Object { $_.Value })
    } else {
      @($direct[0].CommandElements | ForEach-Object {
        if ($_ -is [System.Management.Automation.Language.CommandParameterAst]) { $_.Extent.Text }
        elseif ($_ -is [System.Management.Automation.Language.StringConstantExpressionAst]) { $_.Value }
        else { '' }
      })
    }
    $scopeIndex = [Array]::IndexOf($args, '--scope')
    Assert-Contract ($scopeIndex -ge 0 -and $args[$scopeIndex + 1] -eq $app.scope -and '--exact' -in $args -and '--source' -in $args -and '--id' -in $args) "${label}: installer must enforce exact ID/source and --scope $($app.scope)"
    $selectorMembers = @($selector.FindAll({ param($n) $n -is [System.Management.Automation.Language.MemberExpressionAst] }, $true) | ForEach-Object { $_.Member.Value })
    Assert-Contract ('id' -in $selectorMembers) "${label}: installer ID does not derive from specification"
    if ($app.versionPolicy -eq 'exact') {
      $versionFlag = '--version' -in $args -or @($SetRecord.Strings | Where-Object { $_.Value -eq '--version' }).Count -gt 0
      Assert-Contract $versionFlag "${label}: exact installer version selector is missing"
    }
    Assert-Contract (@($SetRecord.Variables | Where-Object { $_.VariablePath.UserPath -eq 'LASTEXITCODE' }).Count -gt 0 -and @($SetRecord.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.ExitStatementAst] -or $n -is [System.Management.Automation.Language.ThrowStatementAst] }, $true)).Count -gt 0) "${label}: installer native failure is not propagated"
    $testSpecs = @(Get-EmbeddedJson $TestRecord | Where-Object { $_.id -eq $app.id })
    Assert-Contract ($testSpecs.Count -eq 1 -and $testSpecs[0].scope -eq $app.scope -and $testSpecs[0].version -eq $spec.version) "${label}: test/install specification differs"
    $distribution = $Resource.metadata.distribution
    $reviewed = $distribution.url -match '^https://' -and $distribution.sha256 -match '^[a-fA-F0-9]{64}$' -and $distribution.installerType
    $retained = $distribution.registrationOnly -eq $true -and $spec.registrationOnly -eq $true -and
      ($distribution.manifest -match '^https://' -or ($app.versionPolicy -eq 'self-updating' -and $distribution.installerType -eq ('catalog-' + $app.scope)))
    Assert-Contract ($reviewed -or $retained) "${label}: reviewed installer URL/digest/type or retained registration-only manifest is missing"
  }
  if ($app.source -eq 'official-zip') {
    $distribution = $Resource.metadata.distribution
    Assert-Contract ($distribution.url -match '^https://' -and $distribution.sha256 -match '^[a-fA-F0-9]{64}$') "${label}: official ZIP URL/digest is missing"
    Assert-Contract ($specs.Count -eq 1 -and $specs[0].version -eq $app.version -and $specs[0].url -eq $distribution.url -and $specs[0].sha256 -eq $distribution.sha256 -and $specs[0].directory -eq $distribution.directory) "${label}: official ZIP selectors differ from metadata"
    $testSpecs = @(Get-EmbeddedJson $TestRecord | Where-Object { $_.id -eq $app.id })
    Assert-Contract ($testSpecs.Count -eq 1 -and $testSpecs[0].version -eq $app.version -and $testSpecs[0].sha256 -eq $distribution.sha256 -and $testSpecs[0].directory -eq $distribution.directory -and $testSpecs[0].executable -eq $specs[0].executable) "${label}: official ZIP test selectors differ"
    Assert-Contract ($distribution.directory -is [string] -and $distribution.directory -notmatch '^[A-Za-z]:|^[\\/]|(^|[\\/])\.\.([\\/]|$)') "${label}: official ZIP destination escapes user ownership"
    Assert-Contract (@($SetRecord.Commands | Where-Object { $_.GetCommandName() -eq 'Get-FileHash' }).Count -gt 0) "${label}: ZIP extraction lacks digest verification"
    if ($app.id -eq 'PowerShell.PowerShell') { Assert-Contract ($specs[0].directory -eq 'Programs\PowerShell\7') "${label}: unstable PowerShell user destination" }
  }
  if ($app.source -in @('github-release', 'nerd-fonts-release')) {
    $releases = @(Get-EmbeddedJson $SetRecord | Where-Object { $_.url -and $_.archiveSha256 })
    $tests = @(Get-EmbeddedJson $TestRecord | Where-Object { $_.url -and $_.archiveSha256 })
    Assert-Contract ($releases.Count -eq 1 -and $tests.Count -eq 1) "${label}: custom release selectors are missing or ambiguous"
    $release = $releases[0]
    Assert-Contract ($release.url -match '^https://' -and $release.archiveSha256 -match '^[a-fA-F0-9]{64}$' -and $release.url -eq $tests[0].url -and $release.archiveSha256 -eq $tests[0].archiveSha256) "${label}: custom release URL/digest test selectors differ"
    if ($app.source -eq 'github-release') {
      Assert-Contract ($release.version -eq $app.version -and $tests[0].version -eq $app.version) "${label}: custom release version selector differs"
      foreach ($key in @('executableSha256', 'hooksSha256')) {
        Assert-Contract ($release.$key -match '^[a-fA-F0-9]{64}$' -and $release.$key -eq $tests[0].$key) "${label}: custom release $key differs"
      }
    } else {
      Assert-Contract ($release.url -like "*/v$($app.version)/JetBrainsMono.zip") "${label}: font release version selector differs"
      Assert-Contract (@($release.fonts.PSObject.Properties).Count -gt 0) "${label}: font face selectors are missing"
      foreach ($font in $release.fonts.PSObject.Properties) {
        Assert-Contract ($font.Value.sha256 -match '^[a-fA-F0-9]{64}$' -and $font.Value.registryName -and $font.Value.sha256 -eq $tests[0].fonts.($font.Name).sha256) "${label}: font checksum/registration selector differs for $($font.Name)"
      }
    }
  }
  if ($app.source -eq 'npm') {
    $packages = @($Resource.metadata.npmPackages.PSObject.Properties)
    Assert-Contract ($packages.Count -gt 0) "${label}: npm package selectors are missing"
    $bundles = @(Get-EmbeddedJson $SetRecord | Where-Object { $_.PSObject.Properties['packages'] -and $_.PSObject.Properties['lock'] })
    Assert-Contract ($bundles.Count -eq 1) "${label}: embedded npm specification/lock is missing"
    $testBundles = @(Get-EmbeddedJson $TestRecord | Where-Object { $_.PSObject.Properties['packages'] -and $_.PSObject.Properties['lock'] })
    Assert-Contract ($testBundles.Count -eq 1 -and $bundles[0].directory -eq 'Programs\npm' -and $testBundles[0].directory -eq $bundles[0].directory) "${label}: npm test/install user-prefix differs"
    $lock = ConvertFrom-NpmLockJson $bundles[0].lock
    foreach ($name in @('pyright', 'typescript', 'typescript-language-server', 'svelte-language-server', '@fission-ai/openspec')) {
      Assert-Contract ($null -ne $Resource.metadata.npmPackages.PSObject.Properties[$name]) "${label}: required upstream npm identity $name is missing"
    }
    Assert-Contract ($app.version -eq $Resource.metadata.npmPackages.($app.id).version) "${label}: npm application version selector differs"
    foreach ($package in $packages) {
      $name = $package.Name
      $selected = $package.Value
      $embedded = $bundles[0].packages.$name
      $locked = $lock.packages["node_modules/$name"]
      Assert-Contract ($selected.version -and $selected.integrity -match '^sha512-[A-Za-z0-9+/]+={0,2}$' -and $selected.tarball -match '^https://') "${label}: npm exact version/integrity missing for $name"
      Assert-Contract ($selected.version -eq $embedded.version -and $selected.integrity -eq $embedded.integrity -and $selected.version -eq $locked.version -and $selected.integrity -eq $locked.integrity -and $selected.tarball -eq $locked.resolved) "${label}: npm metadata/lock selector differs for $name"
      Assert-Contract ($bundles[0].manifest.dependencies.$name -eq $selected.version -and @($selected.bin).Count -gt 0) "${label}: npm manifest/native wrapper missing for $name"
      Assert-Contract ($testBundles[0].packages.$name.version -eq $selected.version -and $testBundles[0].packages.$name.integrity -eq $selected.integrity) "${label}: npm test selector differs for $name"
    }
    Assert-Contract (@($Resource.dependsOn).Count -gt 0) "${label}: npm runtime dependency is missing"
  }
}

function Test-WindowsDocument {
  param($Document, $Managed)
  Assert-Contract ($Document.'$schema' -eq 'https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2023/08/config/document.json') 'configuration.winget $schema: unexpected document schema'
  Assert-Contract ($Document.metadata.winget.processor.identifier -eq 'dscv3') 'configuration.winget metadata: expected dscv3 processor'
  Assert-Contract (@($Document.resources).Count -gt 0) 'configuration.winget resources: empty document'
  Assert-Contract ($Managed.auditedOn -match '^\d{4}-\d{2}-\d{2}$' -and $Managed.revisedOn -match '^\d{4}-\d{2}-\d{2}$') 'managed-applications.json: missing dated audit'
  Assert-Contract (@($Managed.identifiers | Where-Object { $_ -isnot [string] -or $_ -notmatch '\S' }).Count -eq 0 -and @($Managed.identifiers | Select-Object -Unique).Count -eq @($Managed.identifiers).Count) 'managed-applications.json: exclusion identifiers must be unique nonempty strings'
  Assert-Contract ('Git.Git' -notin $Managed.identifiers -and 'Docker.DockerDesktop' -in $Managed.identifiers) 'managed-applications.json: per-user Git/Docker exclusion boundary differs'
  $names = @{}
  foreach ($resource in $Document.resources) {
    $label = "resource $($resource.name)"
    Assert-Contract ($resource.name -is [string] -and $resource.name -match '\S' -and $resource.type -match '^[^/]+/[^/]+$' -and $null -ne $resource.properties) "${label}: missing name/type/properties"
    Assert-Contract ($resource.name -notin @('fork wslgit', 'zed catppuccin theme', 'zen catppuccin theme', 'reneo elevation launcher', 'zed keymap', 'zed settings', 'reneo settings', 'power toys settings')) "${label}: migrated user files belong only to chezmoi"
    if ($resource.name -eq 'package window tool') {
      Assert-Contract ($resource.properties.testScript -notmatch '(?i)AltSnap\.ini' -and $resource.properties.setScript -notmatch '(?i)WritePrivateProfileString|AeroHoffset|AeroVoffset') "${label}: AltSnap INI belongs only to chezmoi"
    }
    Assert-Contract (-not $names.ContainsKey($resource.name)) "${label}: duplicate name"
    $names[$resource.name] = $resource.type
  }
  $roles = @{}
  $ids = @{}
  $fixed = @{
    browser = 'Zen-Team.Zen-Browser'; editor = 'ZedIndustries.Zed'; 'browser-relay' = 'Brave.Brave'; 'communication-client' = 'Ferdium.Ferdium'; 'native-git' = 'Git.Git'
    'git-client' = 'Fork.Fork'; launcher = 'Microsoft.PowerToys'; 'keyboard-layout' = 'Rojetto.ReNeo.neo2'; 'terminal-font' = 'ryanoasis.nerd-fonts.JetBrainsMono'; 'window-tool' = 'AltSnap.AltSnap'
    'source-manager' = 'twpayne.chezmoi'; tailnet = 'Tailscale.Tailscale'; 'javascript-runtime' = 'OpenJS.NodeJS.LTS'; 'bun-runtime' = 'Oven-sh.Bun'; 'python-runtime' = 'Python.Python.3.13'; 'python-tooling' = 'astral-sh.uv'
    'repository-manager' = 'x-motemen.ghq'; search = 'BurntSushi.ripgrep.MSVC'; find = 'sharkdp.fd'; picker = 'junegunn.fzf'; pager = 'dandavison.delta'; 'hook-runner' = 'evilmartians.lefthook'
    'markdown-lsp' = 'FelixZeller.markdown-oxide'; 'document-compiler' = 'Typst.Typst'; 'typst-lsp' = 'Myriad-Dreamin.Tinymist'; shell = 'PowerShell.PowerShell'; 'github-cli' = 'GitHub.cli'
    openspec = '@fission-ai/openspec'; 'python-lsp' = '@fission-ai/openspec'; 'typescript-lsp' = '@fission-ai/openspec'; 'svelte-lsp' = '@fission-ai/openspec'
  }
  $selfUpdating = @('Zen-Team.Zen-Browser', 'ZedIndustries.Zed', 'Brave.Brave', 'Ferdium.Ferdium', 'Git.Git')
  $dependencyNames = @{}
  foreach ($resource in $Document.resources) {
    $label = "resource $($resource.name)"
    $dependencies = @($resource.dependsOn | Where-Object { $null -ne $_ })
    $dependencyNames[$resource.name] = @()
    foreach ($dependency in $dependencies) {
      $match = [regex]::Match([string]$dependency, "^\[resourceId\(\s*'([^']+)'\s*,\s*'([^']+)'\s*\)\]$")
      $target = if ($match.Success) { $match.Groups[2].Value } else { [string]$dependency }
      Assert-Contract ($names.ContainsKey($target) -and $target -ne $resource.name) "${label}: undeclared/self dependency $target"
      Assert-Contract ($match.Success -and $names[$target] -ceq $match.Groups[1].Value) "${label}: dependency $target must use resourceId with its declared type $($names[$target])"
      $dependencyNames[$resource.name] += $target
    }
    Assert-Contract (@($dependencies | Select-Object -Unique).Count -eq $dependencies.Count) "${label}: duplicate dependency"
    Assert-Contract ($resource.type -notmatch '(?i)WindowsFeature|OptionalFeature|WindowsCapability') "${label}: Windows feature is forbidden"
    $app = $resource.metadata.application
    $exception = $null -ne $app -and $app.id -in @('Zen-Team.Zen-Browser', 'Tailscale.Tailscale')
    Assert-Contract ($(if ($exception) { $resource.metadata.winget.securityContext -eq 'elevated' } else { $resource.metadata.winget.securityContext -ne 'elevated' })) "${label}: unapproved elevated resource or missing approved machine context"
    $keyPath = [string]$resource.properties.keyPath
    Assert-Contract ($keyPath -notmatch '(?i)^(HKLM|HKEY_LOCAL_MACHINE)|CloudStore|UserChoice|DefaultAssociations') "${label}: forbidden machine registry/CloudStore/default-association path $keyPath"
    Assert-Contract ($resource.metadata.description -notmatch '(?i)CloudStore|default.?association|taskbar.*pin') "${label}: forbidden CloudStore/default-association/taskbar-pinning claim"
    if ($resource.type -eq 'Microsoft.WinGet/Package') { Assert-Contract ($null -ne $app) "${label}: missing application metadata" }
    if ($null -ne $app) {
      Assert-Contract ($app.id -and $app.source -and @($app.roles).Count -ge 1 -and ($app.source -eq 'npm' -or @($app.roles).Count -eq 1)) "${label}: missing identity/source or invalid application roles"
      Assert-Contract (-not $ids.ContainsKey($app.id)) "${label}: duplicate application identifier $($app.id)"
      $ids[$app.id] = $true
      Assert-Contract ($app.id -notin $Managed.identifiers) "${label}: centrally managed identifier $($app.id)"
      $expectedSource = switch ($app.id) {
        'AltSnap.AltSnap' { 'github-release' }
        'ryanoasis.nerd-fonts.JetBrainsMono' { 'nerd-fonts-release' }
        'PowerShell.PowerShell' { 'official-zip' }
        'GitHub.cli' { 'official-zip' }
        '@fission-ai/openspec' { 'npm' }
        default { 'winget' }
      }
      Assert-Contract ($app.source -eq $expectedSource) "${label}: application source differs from reviewed distribution"
      foreach ($role in $app.roles) {
        Assert-Contract ($role -is [string] -and $role -match '\S' -and -not $roles.ContainsKey($role)) "${label}: missing/duplicate role $role"
        $roles[$role] = $app.id
        if ($fixed.ContainsKey($role)) { Assert-Contract ($app.id -eq $fixed[$role]) "${label}: fixed identity differs for $role" }
      }
      Assert-Contract ($app.scope -eq $(if ($exception) { 'machine' } else { 'user' })) "${label}: unapproved application scope $($app.scope)"
      Assert-Contract ($app.versionPolicy -is [string] -and $app.versionPolicy -in @('exact', 'self-updating')) "${label}: missing/ambiguous version policy"
      Assert-Contract (($app.versionPolicy -eq 'self-updating') -eq ($app.id -in $selfUpdating)) "${label}: forbidden version policy for $($app.id)"
      Assert-Contract ($(if ($app.versionPolicy -eq 'exact') { $app.version -is [string] -and $app.version.Length -gt 0 } else { -not $app.PSObject.Properties['version'] })) "${label}: invalid version selector"
      Assert-Contract ($app.id -notin @('Microsoft.WindowsTerminal', 'Tern.Tern', 'MiKTeX.MiKTeX') -and 'terminal' -notin $app.roles -and $app.id -notmatch '(?i)texlab|nixd|roslyn') "${label}: forbidden native package/manual Tern boundary"
      if ($resource.type -eq 'Microsoft.WinGet/Package') {
        Assert-Contract ($resource.properties.id -eq $app.id -and $resource.properties.source -eq $app.source) "${label}: package identity/source selector differs"
        if ($app.versionPolicy -eq 'exact') {
          Assert-Contract ($resource.properties.version -eq $app.version -and $resource.properties.useLatest -eq $false) "${label}: exact version selector differs"
        } else {
          Assert-Contract (-not $resource.properties.PSObject.Properties['version'] -and $resource.properties.useLatest -eq $true) "${label}: self-updating/latest selector differs"
        }
      } else { Assert-Contract ($resource.type -eq 'Microsoft.DSC.Transitional/WindowsPowerShellScript') "${label}: application must use package or script installer" }
    }
    $records = @{}
    foreach ($kind in @('testScript', 'setScript')) {
      $script = $resource.properties.$kind
      if ($resource.type -eq 'Microsoft.DSC.Transitional/WindowsPowerShellScript' -or $null -ne $script) {
        Assert-Contract ($script -is [string] -and $script.Length -gt 0) "${label} ${kind}: missing script"
        $record = Get-ScriptRecord "$($resource.name) $kind" $script
        Test-DocumentScriptBoundary $record $app
        $records[$kind] = $record
        if ($resource.name -eq 'reneo elevation launcher') {
          foreach ($node in @($record.Strings | Where-Object { $_.Value.Contains("`n") -and $_.Value -match 'ReNeo|reneo' })) {
            $null = Get-ScriptRecord "$($resource.name) embedded start-reneo-elevated.ps1 $kind" $node.Value
          }
        }
      }
    }
    if ($null -ne $app -and $records.Count -gt 0) { Test-ScriptInstaller $resource $records.testScript $records.setScript }
    if ($resource.name -eq 'german input methods') {
      foreach ($record in $records.Values) {
        $assignments = @($record.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true))
        $ordered = @($assignments | Where-Object { @($_.Right.FindAll({ param($n) $n -is [System.Management.Automation.Language.ArrayExpressionAst] }, $true)).Count -gt 0 })
        $tips = @($ordered | ForEach-Object { $_.Right.FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true) } | Where-Object { $_.Value -match '^0407:' } | ForEach-Object { $_.Value })
        Assert-Contract ($tips.Count -ge 2 -and $tips[0] -eq '0407:00000407' -and $tips[1] -eq '0407:b0000407') "script $($record.Name): German QWERTZ must precede native Neo"
        $defaults = @($record.Commands | Where-Object { $_.GetCommandName() -eq 'Set-WinDefaultInputMethodOverride' } | ForEach-Object {
          $_.CommandElements | Where-Object { $_ -is [System.Management.Automation.Language.VariableExpressionAst] } | ForEach-Object { $_.VariablePath.UserPath }
        })
        if ($defaults.Count -eq 0) {
          $defaults = @($record.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.BinaryExpressionAst] }, $true) | Where-Object {
            $_.Left -is [System.Management.Automation.Language.MemberExpressionAst] -and $_.Left.Member.Value -eq 'InputMethodTip' -and $_.Right -is [System.Management.Automation.Language.VariableExpressionAst]
          } | ForEach-Object { $_.Right.VariablePath.UserPath })
        }
        foreach ($variable in $defaults) {
          $values = @($assignments | Where-Object { $_.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and $_.Left.VariablePath.UserPath -eq $variable } | ForEach-Object {
            $_.Right.FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] }, $true) | ForEach-Object { $_.Value }
          })
          Assert-Contract ($values.Count -eq 1 -and $values[0] -eq '0407:00000407') "script $($record.Name): native Neo must not be the default input method"
        }
        Assert-Contract ($defaults.Count -gt 0) "script $($record.Name): missing explicit QWERTZ default input method"
      }
    }
    if ($resource.name -eq 'windows dark appearance') {
      $strings = @($records.testScript.Strings | ForEach-Object { $_.Value })
      Assert-Contract (@($strings | Where-Object { $_ -match '(?i)CurrentTheme|Custom\.theme|dark\.theme' }).Count -eq 0) "${label}: dark acceptance must not depend on active theme-file path"
      foreach ($member in @('AppsUseLightTheme', 'SystemUsesLightTheme', 'EnableTransparency', 'WallPaper')) {
        Assert-Contract (@($records.testScript.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.MemberExpressionAst] }, $true) | Where-Object { $_.Member.Value -eq $member }).Count -gt 0) "${label}: missing declared dark state $member"
      }
    }
    if ($null -eq $app) {
      $values = @($resource.name, $keyPath, [string]$resource.properties.valueData)
      Assert-Contract (@($values | Where-Object { $_ -match '(?i)Brave|Ferdium|browser.relay|communication.client' }).Count -eq 0) "${label}: relay/communication startup or profile ownership is forbidden"
      foreach ($record in $records.Values) {
        Assert-Contract (@($record.Strings | Where-Object { $_.Value -match '(?i)Brave|Ferdium' }).Count -eq 0) "${label}: relay/communication startup or profile ownership is forbidden"
      }
    }
  }
  foreach ($role in $fixed.Keys) { Assert-Contract ($roles.ContainsKey($role) -and $roles[$role] -eq $fixed[$role]) "application ${role}: missing required fixed identity $($fixed[$role])" }
  foreach ($name in @('german input methods', 'windows dark appearance')) { Assert-Contract ($names.ContainsKey($name)) "resource ${name}: required settings are missing" }
  $nodeResource = @($Document.resources | Where-Object { $_.metadata.application.id -eq 'OpenJS.NodeJS.LTS' })[0]
  foreach ($resource in @($Document.resources | Where-Object { $_.metadata.application.source -eq 'npm' })) {
    Assert-Contract ($nodeResource.name -in $dependencyNames[$resource.name]) "resource $($resource.name): declared native Node dependency is missing"
  }
  # Detect dependency cycles without requiring declaration order to be execution order.
  $pending = @($Document.resources)
  $resolved = @{}
  while ($pending.Count -gt 0) {
    $ready = @($pending | Where-Object { @($dependencyNames[$_.name] | Where-Object { -not $resolved.ContainsKey($_) }).Count -eq 0 })
    Assert-Contract ($ready.Count -gt 0) "resource $($pending[0].name): dependency cycle"
    foreach ($resource in $ready) { $resolved[$resource.name] = $true }
    $pending = @($pending | Where-Object { -not $resolved.ContainsKey($_.name) })
  }
}
