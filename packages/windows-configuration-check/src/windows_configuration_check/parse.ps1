$ErrorActionPreference = 'Stop'
$scripts = [Console]::In.ReadToEnd() | ConvertFrom-Json -AsHashtable
$results = foreach ($name in $scripts.Keys) {
  $tokens = $null
  $errors = $null
  $ast = [System.Management.Automation.Language.Parser]::ParseInput(
    $scripts[$name], [ref]$tokens, [ref]$errors
  )
  $variables = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.VariableExpressionAst] }, $true) |
    ForEach-Object { $_.VariablePath.UserPath })
  $strings = @($ast.FindAll({ param($node) $node -is [System.Management.Automation.Language.StringConstantExpressionAst] -or
    $node -is [System.Management.Automation.Language.ExpandableStringExpressionAst] }, $true) |
    ForEach-Object { $_.Value })
  @{
    name = $name
    errors = @($errors | ForEach-Object { $_.Message })
    variables = $variables
    strings = $strings
  }
}
ConvertTo-Json -InputObject @($results) -Depth 10 -Compress
