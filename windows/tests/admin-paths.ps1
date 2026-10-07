# Resolve only side-effect-free AST path expressions; never evaluate admin source.
function Resolve-AdministratorPath {
  param($Expression, $Record, [string[]]$Seen = @())
  $label = "script $($Record.Name)"
  Assert-Contract ($null -ne $Expression) "${label}: missing owned path expression"
  if ($Expression -is [System.Management.Automation.Language.StatementBlockAst]) {
    Assert-Contract ($Expression.Statements.Count -eq 1) "${label}: ambiguous owned path assignment"
    return (Resolve-AdministratorPath $Expression.Statements[0] $Record $Seen)
  }
  if ($Expression -is [System.Management.Automation.Language.PipelineAst]) {
    Assert-Contract ($Expression.PipelineElements.Count -eq 1) "${label}: owned path uses an unsupported pipeline"
    return (Resolve-AdministratorPath $Expression.PipelineElements[0] $Record $Seen)
  }
  if ($Expression -is [System.Management.Automation.Language.CommandExpressionAst]) { return (Resolve-AdministratorPath $Expression.Expression $Record $Seen) }
  if ($Expression -is [System.Management.Automation.Language.ParenExpressionAst]) { return (Resolve-AdministratorPath $Expression.Pipeline $Record $Seen) }
  if ($Expression -is [System.Management.Automation.Language.ConvertExpressionAst]) { return (Resolve-AdministratorPath $Expression.Child $Record $Seen) }
  if ($Expression -is [System.Management.Automation.Language.VariableExpressionAst]) {
    $name = $Expression.VariablePath.UserPath
    $roots = @{ 'env:SystemRoot' = '%SystemRoot%'; 'env:ProgramFiles' = '%ProgramFiles%'; 'env:TEMP' = '%TEMP%' }
    if ($roots.ContainsKey($name)) { return $roots[$name] }
    Assert-Contract ($name -notin $Seen) "${label}: cyclic owned path variable $name"
    $assignments = @($Record.Ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.AssignmentStatementAst] }, $true) | Where-Object {
      $_.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and $_.Left.VariablePath.UserPath -eq $name
    })
    Assert-Contract ($assignments.Count -eq 1) "${label}: unknown/ambiguous owned path variable $name"
    return (Resolve-AdministratorPath $assignments[0].Right $Record ($Seen + $name))
  }
  if ($Expression -is [System.Management.Automation.Language.StringConstantExpressionAst] -or $Expression -is [System.Management.Automation.Language.ExpandableStringExpressionAst]) {
    $value = $Expression.Value
    # The independently validated specification fixes these identities, not its variable name.
    $value = [regex]::Replace($value, '\$\([^)]*\.layoutFile\)', 'kbdneo2.dll')
    $value = [regex]::Replace($value, '\$\([^)]*\.layoutId\)', 'b0000407')
    return $value
  }
  if ($Expression -is [System.Management.Automation.Language.CommandAst]) {
    $operands = @($Expression.CommandElements | Select-Object -Skip 1 | Where-Object { $_ -isnot [System.Management.Automation.Language.CommandParameterAst] })
    if ($Expression.GetCommandName() -eq 'Join-Path' -and $operands.Count -eq 2) {
      return ((Resolve-AdministratorPath $operands[0] $Record $Seen).TrimEnd('\') + '\' + (Resolve-AdministratorPath $operands[1] $Record $Seen))
    }
    if ($Expression.GetCommandName() -eq 'Split-Path' -and $operands.Count -eq 1) {
      $value = Resolve-AdministratorPath $operands[0] $Record $Seen
      Assert-Contract ($value.LastIndexOf('\') -gt 0) "${label}: owned path has no parent"
      return $value.Substring(0, $value.LastIndexOf('\'))
    }
  }
  throw "${label}: unresolved owned path expression $($Expression.GetType().Name)"
}

function Test-AdministratorPaths {
  param($Record, [string]$Name)
  $paths = @()
  foreach ($command in $Record.Commands) {
    $kind = $command.GetCommandName()
    if ($kind -notin @('Get-ItemProperty', 'Test-Path', 'Get-FileHash', 'Copy-Item', 'New-Item', 'New-ItemProperty', 'Remove-Item', 'Invoke-WebRequest')) { continue }
    for ($i = 1; $i -lt $command.CommandElements.Count; $i++) {
      $element = $command.CommandElements[$i]
      if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and $element.ParameterName -in @('Path', 'LiteralPath', 'Destination', 'OutFile')) {
        $argument = if ($element.Argument) { $element.Argument } else { $command.CommandElements[$i + 1] }
        $paths += Resolve-AdministratorPath $argument $Record
      }
    }
    if ($kind -ne 'Invoke-WebRequest' -and $command.CommandElements.Count -gt 1 -and $command.CommandElements[1] -isnot [System.Management.Automation.Language.CommandParameterAst]) {
      $paths += Resolve-AdministratorPath $command.CommandElements[1] $Record
      if ($kind -eq 'Copy-Item' -and $command.CommandElements.Count -gt 2 -and $command.CommandElements[2] -isnot [System.Management.Automation.Language.CommandParameterAst]) {
        $paths += Resolve-AdministratorPath $command.CommandElements[2] $Record
      }
    }
  }
  foreach ($member in $Record.Members) {
    if ($member.Member.Value -in @('ReadAllText', 'WriteAllText')) { $paths += Resolve-AdministratorPath $member.Arguments[0] $Record }
    if ($member.Member.Value -eq 'ExtractToDirectory') {
      foreach ($argument in $member.Arguments) { $paths += Resolve-AdministratorPath $argument $Record }
    }
  }
  foreach ($path in $paths) {
    $allowed = if ($Name -eq 'apply-zen-policies.ps1') {
      $path -match '^%ProgramFiles%\\Zen Browser\\(zen\.exe|distribution(\\policies\.json)?)$'
    } else {
      $path -match '^%SystemRoot%\\(System32|SysWOW64)\\kbdneo2\.dll$' -or
      $path -eq 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\b0000407' -or
      $path -match '^%TEMP%\\(kbdneo64\.zip|kbdneo64(\\kbdneo64\\(System32|SysWOW64)\\kbdneo2\.dll)?)$'
    }
    Assert-Contract $allowed "script ${Name}: resolved path outside fixed ownership $path"
  }
}
