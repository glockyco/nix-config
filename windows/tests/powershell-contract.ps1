#Requires -Version 7.4
# Parse source and enforce fixed Administrator ownership without executing scripts.
function Assert-Contract {
  param([bool]$Condition, [string]$Finding)
  if (-not $Condition) { throw $Finding }
}

# Exact source shares AST nodes. Named role policies cache only successful checks.
$script:ScriptParseCache = [System.Collections.Generic.Dictionary[string,object]]::new([StringComparer]::Ordinal)

function Get-ScriptRecord {
  param([string]$Name, [string]$Source)
  $parsed = $null
  if (-not $script:ScriptParseCache.TryGetValue($Source, [ref]$parsed)) {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($Source, [ref]$tokens, [ref]$errors)
    Assert-Contract ($errors.Count -eq 0) "script ${Name}: $(@($errors | ForEach-Object { "$($_.ErrorId) at $($_.Extent.StartLineNumber): $($_.Message)" }) -join '; ')"
    $strings = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.StringConstantExpressionAst] -or $n -is [System.Management.Automation.Language.ExpandableStringExpressionAst] }, $true))
    $variables = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.VariableExpressionAst] }, $true))
    $commands = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.CommandAst] }, $true))
    $members = @($ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.InvokeMemberExpressionAst] }, $true))
    $checks = [System.Collections.Generic.Dictionary[string,bool]]::new([StringComparer]::Ordinal)
    $parsed = [PSCustomObject]@{ Ast = $ast; Strings = $strings; Variables = $variables; Commands = $commands; Members = $members; Checks = $checks }
    $script:ScriptParseCache.Add($Source, $parsed)
  }
  [PSCustomObject]@{ Name = $Name; Ast = $parsed.Ast; Strings = $parsed.Strings; Variables = $parsed.Variables; Commands = $parsed.Commands; Members = $parsed.Members; Checks = $parsed.Checks }
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
  # Failures recompute the current caller's diagnostic.
  $cacheKey = "administrator-role:$AllowedAdministrator|$($Record.Name)"
  if ($Record.Checks.ContainsKey($cacheKey)) { return }
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
  $Record.Checks[$cacheKey] = $true
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
