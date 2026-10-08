# Offset-preserving JSONC edits: retain comments and every undeclared source byte.
function Get-AppJsoncTokens {
  param([string]$Clean)
  $lexer = [regex]::new('\G\s*(?<token>"(?:\\(?:["\\/bfnrt]|u[0-9a-fA-F]{4})|[^"\\\x00-\x1f])*"|[{}\[\]:,]|-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?|true|false|null)')
  $offset = 0
  while ($offset -lt $Clean.Length) {
    if ([string]::IsNullOrWhiteSpace($Clean.Substring($offset))) { break }
    $match = $lexer.Match($Clean, $offset)
    if (-not $match.Success) { throw "Malformed JSONC token/string at offset $offset; existing file was not overwritten" }
    $match.Groups['token']
    $offset = $match.Index + $match.Length
  }
}

function Read-AppJsoncNode {
  param($Tokens, [ref]$Index)
  if ($Index.Value -ge $Tokens.Count) { throw 'Malformed JSONC: unexpected end of value' }
  $token = $Tokens[$Index.Value]; $Index.Value++
  $node = [PSCustomObject]@{ Start = $token.Index; End = $token.Index + $token.Length; Kind = 'value'; Close = -1; Properties = @() }
  if ($token.Value -eq '{') {
    $node.Kind = 'object'
    while ($true) {
      if ($Index.Value -ge $Tokens.Count) { throw 'Malformed JSONC: unterminated object' }
      if ($Tokens[$Index.Value].Value -eq '}') { break }
      $nameToken = $Tokens[$Index.Value]
      if (-not $nameToken.Value.StartsWith('"')) { throw 'Malformed JSONC: expected quoted property name' }
      $Index.Value++
      if ($Index.Value -ge $Tokens.Count -or $Tokens[$Index.Value].Value -ne ':') { throw 'Malformed JSONC: expected property colon' }
      $Index.Value++
      $value = Read-AppJsoncNode $Tokens $Index
      $property = [PSCustomObject]@{ Name = ($nameToken.Value | ConvertFrom-Json); Start = $nameToken.Index; End = $value.End; Value = $value; Comma = -1 }
      if ($Index.Value -ge $Tokens.Count) { throw 'Malformed JSONC: unterminated object' }
      if ($Tokens[$Index.Value].Value -eq ',') { $property.Comma = $Tokens[$Index.Value].Index; $Index.Value++ }
      elseif ($Tokens[$Index.Value].Value -ne '}') { throw 'Malformed JSONC: expected property comma' }
      $node.Properties += $property
    }
    $node.Close = $Tokens[$Index.Value].Index
    $node.End = $node.Close + 1; $Index.Value++
  } elseif ($token.Value -eq '[') {
    while ($true) {
      if ($Index.Value -ge $Tokens.Count) { throw 'Malformed JSONC: unterminated array' }
      if ($Tokens[$Index.Value].Value -eq ']') { break }
      $null = Read-AppJsoncNode $Tokens $Index
      if ($Index.Value -ge $Tokens.Count) { throw 'Malformed JSONC: unterminated array' }
      if ($Tokens[$Index.Value].Value -eq ',') { $Index.Value++ }
      elseif ($Tokens[$Index.Value].Value -ne ']') { throw 'Malformed JSONC: expected array comma' }
    }
    $node.End = $Tokens[$Index.Value].Index + 1; $Index.Value++
  } elseif ($token.Value -in @('}', ']', ':', ',')) { throw 'Malformed JSONC: expected value' }
  return $node
}

function Add-AppJsoncMergeEdits {
  param([string]$Text, $Node, $Desired, $Edits)
  $missing = @()
  foreach ($setting in $Desired.PSObject.Properties) {
    $property = @($Node.Properties | Where-Object { $_.Name -ceq $setting.Name })
    if ($property.Count -gt 1) { throw "Duplicate JSONC property $($setting.Name); existing file was not overwritten" }
    if ($property.Count -eq 0) {
      $missing += ($setting.Name | ConvertTo-Json -Compress) + ': ' + (ConvertTo-Json -InputObject $setting.Value -Depth 100 -Compress)
      continue
    }
    $valueNode = $property[0].Value
    if ($setting.Value -is [PSCustomObject] -and $valueNode.Kind -eq 'object') {
      Add-AppJsoncMergeEdits $Text $valueNode $setting.Value $Edits
    } else {
      $original = $Text.Substring($valueNode.Start, $valueNode.End - $valueNode.Start)
      # A container property retains empty/single-element arrays under PS5.1.
      $container = ConvertFrom-AppJsonc ('{"value":' + $original + '}')
      $actual = $container.value
      $expected = ConvertTo-Json -InputObject $setting.Value -Depth 100 -Compress
      if ((ConvertTo-Json -InputObject $actual -Depth 100 -Compress) -cne $expected) {
        $Edits.Add([PSCustomObject]@{ Start = $valueNode.Start; End = $valueNode.End; Text = $expected })
      }
    }
  }
  if ($missing.Count -gt 0) {
    $comma = if ($Node.Properties.Count -gt 0 -and $Node.Properties[-1].Comma -lt 0) { ',' } else { '' }
    $Edits.Add([PSCustomObject]@{ Start = $Node.Close; End = $Node.Close; Text = $comma + "`n  " + ($missing -join ",`n  ") + "`n" })
  }
}

function Add-AppJsoncRemovalEdits {
  param($Node, [string[]]$Names, $Edits)
  if ($null -eq $Node -or $Node.Kind -ne 'object') { return }
  for ($i = 0; $i -lt $Node.Properties.Count; $i++) {
    $property = $Node.Properties[$i]
    if ($property.Name -cnotin $Names) { continue }
    $start = $property.Start; $end = $property.End
    if ($property.Comma -ge 0) { $end = $property.Comma + 1 }
    elseif ($i -gt 0) { $start = $Node.Properties[$i - 1].Comma }
    $Edits.Add([PSCustomObject]@{ Start = $start; End = $end; Text = '' })
  }
}

function Edit-AppJsonc {
  param([string]$Text, $Desired, [string]$Kind)
  $Text = $Text.TrimStart([char]0xfeff)
  # Parse first so malformed input can never produce a partial destination write.
  $null = ConvertFrom-AppJsonc $Text
  if ([string]::IsNullOrWhiteSpace($Text)) { $Text = '{}' }
  $clean = Get-AppJsoncCleanText $Text -KeepTrailingCommas
  $tokens = @(Get-AppJsoncTokens $clean)
  $index = 0
  $node = Read-AppJsoncNode $tokens ([ref]$index)
  if ($node.Kind -ne 'object') { throw 'App settings must be a JSON object; existing file was not overwritten' }
  if ($index -ne $tokens.Count) { throw 'Malformed JSONC: trailing value after root object' }
  $edits = [Collections.Generic.List[object]]::new()
  if ($Kind -eq 'zed') {
    foreach ($owner in @('lsp', 'agent_servers')) {
      $parent = @($node.Properties | Where-Object { $_.Name -ceq $owner })
      if ($parent.Count -gt 1) { throw "Duplicate JSONC property $owner; existing file was not overwritten" }
      if ($parent.Count -eq 1) {
        $names = if ($owner -eq 'lsp') { @('nixd', 'texlab') } else { @('omp') }
        Add-AppJsoncRemovalEdits $parent[0].Value $names $edits
      }
    }
  }
  if ($edits.Count -eq 0) { Add-AppJsoncMergeEdits $Text $node $Desired $edits }
  # Adjacent deleted properties can share their separating comma; union only
  # overlapping deletion spans, never text replacements or insertions.
  $deletions = @($edits | Where-Object { $_.Text -eq '' } | Sort-Object Start)
  $normalized = [Collections.Generic.List[object]]::new()
  foreach ($edit in $deletions) {
    if ($normalized.Count -gt 0 -and $edit.Start -le $normalized[-1].End) { $normalized[-1].End = [Math]::Max($normalized[-1].End, $edit.End) }
    else { $normalized.Add($edit) }
  }
  foreach ($edit in $edits | Where-Object { $_.Text -ne '' }) { $normalized.Add($edit) }
  foreach ($edit in $normalized | Sort-Object Start -Descending) { $Text = $Text.Remove($edit.Start, $edit.End - $edit.Start).Insert($edit.Start, $edit.Text) }
  $null = ConvertFrom-AppJsonc $Text
  if ($deletions.Count -gt 0) { return Edit-AppJsonc $Text $Desired '' }
  return $Text
}
