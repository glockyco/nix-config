function Invoke-SchemaFixtures {
  param($Document, [string]$WindowsRoot, [string]$FixtureRoot)
  $schema = @'
{"$schema":"https://json-schema.org/draft/2020-12/schema","$id":"https://example.invalid/schema","$comment":"annotation","title":"fixture","description":"schema vocabulary fixture","type":"object","required":["label","count","items","uri"],"properties":{"label":{"type":"string","minLength":2,"pattern":"^[A-Z]","enum":["OK"],"const":"OK"},"count":{"type":"integer","minimum":0},"items":{"type":"array","minItems":2,"uniqueItems":true,"items":{"type":["string","null"]}},"uri":{"type":"string","format":"uri"}},"additionalProperties":false,"allOf":[{"if":{"properties":{"count":{"const":2}}},"then":{"properties":{"label":{"const":"OK"}}}}],"oneOf":[{"properties":{"count":{"const":2}}},{"properties":{"count":{"const":3}}}]}
'@ | ConvertFrom-Json
  $value = '{"label":"OK","count":2,"items":["a","b"],"uri":"https://example.invalid/"}' | ConvertFrom-Json
  Assert-SchemaVocabulary $schema
  Assert-Contract (@(Get-SchemaFindings $schema $value).Count -eq 0) 'schema fixture: valid reviewed vocabulary rejected'
  $cases = @(
    @{ Name = 'required'; Edit = { param($v) $v.PSObject.Properties.Remove('label') }; Finding = 'missing required property label' },
    @{ Name = 'additionalProperties'; Edit = { param($v) $v | Add-Member outside $true }; Finding = 'outside is forbidden' },
    @{ Name = 'type integer'; Edit = { param($v) $v.count = 2.5 }; Finding = 'count must have type integer' },
    @{ Name = 'minimum'; Edit = { param($v) $v.count = -1 }; Finding = 'count is below minimum' },
    @{ Name = 'minItems'; Edit = { param($v) $v.items = @('a') }; Finding = 'fewer than minItems' },
    @{ Name = 'items type'; Edit = { param($v) $v.items = @('a', 1) }; Finding = 'items/1 must have type string,null' },
    @{ Name = 'uniqueItems'; Edit = { param($v) $v.items = @('a', 'a') }; Finding = 'duplicates an item' },
    @{ Name = 'minLength'; Edit = { param($v) $v.label = 'O' }; Finding = 'shorter than minLength' },
    @{ Name = 'case-sensitive pattern'; Edit = { param($v) $v.label = 'ok' }; Finding = 'does not match pattern' },
    @{ Name = 'enum and const'; Edit = { param($v) $v.label = 'NO' }; Finding = 'outside enum' },
    @{ Name = 'format uri'; Edit = { param($v) $v.uri = 'relative/path' }; Finding = 'not an absolute URI' },
    @{ Name = 'oneOf'; Edit = { param($v) $v.count = 4 }; Finding = 'exactly one oneOf branch' }
  )
  foreach ($case in $cases) {
    $changed = Copy-FixtureObject $value
    $null = & $case.Edit $changed
    $findings = @(Get-SchemaFindings $schema $changed)
    Assert-Contract (@($findings | Where-Object { $_ -match $case.Finding }).Count -gt 0) "schema fixture $($case.Name): negative instance accepted"
    Write-Output "fixture passed: JSON Schema $($case.Name)"
  }
  $conditional = '{"if":{"type":"string"},"then":{"const":"OK"}}' | ConvertFrom-Json
  Assert-Contract (@(Get-SchemaFindings $conditional 'NO').Count -gt 0 -and @(Get-SchemaFindings $conditional 1).Count -eq 0) 'schema fixture: conditional then selection differs'
  $overlap = '{"oneOf":[{"type":"string"},{"type":"string"}]}' | ConvertFrom-Json
  Assert-Contract (@(Get-SchemaFindings $overlap 'OK').Count -gt 0) 'schema fixture: overlapping oneOf accepted'
  $nullSchema = '{"type":"null","const":null}' | ConvertFrom-Json
  Assert-Contract (@(Get-SchemaFindings $nullSchema $null).Count -eq 0) 'schema fixture: null semantics differ'
  $objectSchema = '{"type":"object","additionalProperties":{"type":"number"}}' | ConvertFrom-Json
  Assert-Contract (@(Get-SchemaFindings $objectSchema ('{"x":1.5}' | ConvertFrom-Json)).Count -eq 0) 'schema fixture: schema-valued additionalProperties rejected'
  Assert-FixtureRejection 'unsupported schema keyword' { Assert-SchemaVocabulary ('{"if":{"type":"null"},"then":{"futureValidation":true}}' | ConvertFrom-Json) } 'unsupported validation keyword futureValidation'
  $invalid = Copy-FixtureObject $Document
  $invalid.resources[0].name = 'schema-invalid-name'
  $path = Join-Path $FixtureRoot 'invalid official schema.winget'
  [IO.File]::WriteAllText($path, ($invalid | ConvertTo-Json -Depth 100))
  Assert-FixtureRejection 'official schema resource name' { Invoke-DocumentSchemaCheck $path $WindowsRoot } 'resource schema-invalid-name: official DSC document JSON Schema validation failed'
  Write-Output 'fixture passed: official schema named resource rejection and supported vocabulary'
}
