[CmdletBinding()]
param([string]$DocumentPath, [string]$WindowsRoot)

# Deliberately limited to the reviewed DSC schema vocabulary. Unknown keywords fail
# before instance evaluation, even when they occur in an unselected conditional.
function Assert-SchemaVocabulary {
  param($Schema, [string]$Path = '$')
  if ($Schema -is [bool]) { return }
  if ($Schema -isnot [PSCustomObject]) { throw "schema ${Path}: expected object or boolean schema" }
  $supported = @('$schema', '$id', '$comment', 'title', 'description', 'type', 'required', 'properties', 'additionalProperties', 'items', 'minItems', 'minLength', 'pattern', 'enum', 'const', 'allOf', 'oneOf', 'if', 'then', 'format', 'minimum', 'uniqueItems')
  foreach ($property in $Schema.PSObject.Properties) {
    if ($property.Name -cnotin $supported) { throw "schema ${Path}: unsupported validation keyword $($property.Name)" }
    if ($property.Name -ceq 'format' -and $property.Value -cne 'uri') { throw "schema ${Path}: unsupported format $($property.Value)" }
    if ($property.Name -ceq 'type') {
      foreach ($type in @($property.Value)) {
        if ($type -cnotin @('object', 'array', 'string', 'integer', 'number', 'boolean', 'null')) { throw "schema ${Path}: unsupported type $type" }
      }
    }
    if ($property.Name -ceq 'properties') {
      foreach ($child in $property.Value.PSObject.Properties) { Assert-SchemaVocabulary $child.Value "$Path/properties/$($child.Name)" }
    }
    if ($property.Name -cin @('additionalProperties', 'items', 'if', 'then')) { Assert-SchemaVocabulary $property.Value "$Path/$($property.Name)" }
    if ($property.Name -cin @('allOf', 'oneOf')) {
      foreach ($child in $property.Value) { Assert-SchemaVocabulary $child "$Path/$($property.Name)" }
    }
  }
}

function Get-ExactJsonProperty {
  param($Object, [string]$Name)
  $Object.PSObject.Properties | Where-Object { $_.Name -ceq $Name } | Select-Object -First 1
}

function Test-JsonValueEqual {
  param($Left, $Right)
  if ($null -eq $Left -or $null -eq $Right) { return ($null -eq $Left -and $null -eq $Right) }
  if ($Left -is [array] -or $Right -is [array]) {
    if ($Left -isnot [array] -or $Right -isnot [array] -or $Left.Count -ne $Right.Count) { return $false }
    for ($i = 0; $i -lt $Left.Count; $i++) { if (-not (Test-JsonValueEqual $Left[$i] $Right[$i])) { return $false } }
    return $true
  }
  if ($Left -is [PSCustomObject] -or $Right -is [PSCustomObject]) {
    if ($Left -isnot [PSCustomObject] -or $Right -isnot [PSCustomObject]) { return $false }
    if (@($Left.PSObject.Properties).Count -ne @($Right.PSObject.Properties).Count) { return $false }
    foreach ($property in $Left.PSObject.Properties) {
      $other = Get-ExactJsonProperty $Right $property.Name
      if (-not $other -or -not (Test-JsonValueEqual $property.Value $other.Value)) { return $false }
    }
    return $true
  }
  if (($Left -is [string]) -ne ($Right -is [string]) -or ($Left -is [bool]) -ne ($Right -is [bool])) { return $false }
  return ($Left -ceq $Right)
}

function Get-SchemaFindings {
  param($Schema, $Value, [string]$Path = '$')
  if ($Schema -is [bool]) { if (-not $Schema) { "$Path is forbidden" }; return }
  $isObject = $Value -is [PSCustomObject]
  $isArray = $Value -is [array]
  $numeric = $null -ne $Value -and [Type]::GetTypeCode($Value.GetType()) -in @([TypeCode]::Byte, [TypeCode]::SByte, [TypeCode]::Int16, [TypeCode]::UInt16, [TypeCode]::Int32, [TypeCode]::UInt32, [TypeCode]::Int64, [TypeCode]::UInt64, [TypeCode]::Single, [TypeCode]::Double, [TypeCode]::Decimal)
  if (Get-ExactJsonProperty $Schema 'type') {
    $validType = $false
    foreach ($type in @($Schema.type)) {
      $validType = $validType -or $(switch -CaseSensitive ($type) {
        'object' { $isObject }; 'array' { $isArray }; 'string' { $Value -is [string] }; 'boolean' { $Value -is [bool] }; 'null' { $null -eq $Value }
        'number' { $numeric }; 'integer' { $numeric -and [math]::Truncate([double]$Value) -eq [double]$Value }
      })
    }
    if (-not $validType) { "$Path must have type $($Schema.type -join ',')"; return }
  }
  if (Get-ExactJsonProperty $Schema 'const') { if (-not (Test-JsonValueEqual $Value $Schema.const)) { "$Path differs from const" } }
  if (Get-ExactJsonProperty $Schema 'enum') {
    $matches = 0
    foreach ($candidate in $Schema.enum) { if (Test-JsonValueEqual $Value $candidate) { $matches++ } }
    if ($matches -eq 0) { "$Path is outside enum" }
  }
  foreach ($subschema in $Schema.allOf) { Get-SchemaFindings $subschema $Value $Path }
  if (Get-ExactJsonProperty $Schema 'oneOf') {
    $matches = 0
    foreach ($subschema in $Schema.oneOf) { if (@(Get-SchemaFindings $subschema $Value $Path).Count -eq 0) { $matches++ } }
    if ($matches -ne 1) { "$Path must match exactly one oneOf branch (matched $matches)" }
  }
  if ((Get-ExactJsonProperty $Schema 'if') -and @(Get-SchemaFindings $Schema.if $Value $Path).Count -eq 0 -and (Get-ExactJsonProperty $Schema 'then')) { Get-SchemaFindings $Schema.then $Value $Path }
  if ($isObject) {
    foreach ($required in $Schema.required) { if (-not (Get-ExactJsonProperty $Value $required)) { "$Path is missing required property $required" } }
    foreach ($property in $Value.PSObject.Properties) {
      $declared = Get-ExactJsonProperty $Schema.properties $property.Name
      if ($declared) { Get-SchemaFindings $declared.Value $property.Value "$Path/$($property.Name)" }
      elseif (Get-ExactJsonProperty $Schema 'additionalProperties') { Get-SchemaFindings $Schema.additionalProperties $property.Value "$Path/$($property.Name)" }
    }
  }
  if ($isArray) {
    if ((Get-ExactJsonProperty $Schema 'minItems') -and $Value.Count -lt $Schema.minItems) { "$Path has fewer than minItems $($Schema.minItems)" }
    for ($i = 0; $i -lt $Value.Count; $i++) {
      if (Get-ExactJsonProperty $Schema 'items') { Get-SchemaFindings $Schema.items $Value[$i] "$Path/$i" }
      if ($Schema.uniqueItems -eq $true) { for ($j = 0; $j -lt $i; $j++) { if (Test-JsonValueEqual $Value[$i] $Value[$j]) { "$Path/$i duplicates an item" } } }
    }
  }
  if ($Value -is [string]) {
    $codePoints = $Value.Length - [regex]::Matches($Value, '[\uDC00-\uDFFF]').Count
    if ((Get-ExactJsonProperty $Schema 'minLength') -and $codePoints -lt $Schema.minLength) { "$Path is shorter than minLength $($Schema.minLength)" }
    if ((Get-ExactJsonProperty $Schema 'pattern') -and -not [regex]::IsMatch($Value, $Schema.pattern)) { "$Path does not match pattern $($Schema.pattern)" }
    if ($Schema.format -ceq 'uri') {
      $uri = $null
      if (-not [Uri]::TryCreate($Value, [UriKind]::Absolute, [ref]$uri)) { "$Path is not an absolute URI" }
    }
  }
  if ($numeric -and (Get-ExactJsonProperty $Schema 'minimum') -and $Value -lt $Schema.minimum) { "$Path is below minimum $($Schema.minimum)" }
}

function Invoke-DocumentSchemaCheck {
  param([string]$DocumentPath, [string]$WindowsRoot)
  $schemaRoot = Join-Path $WindowsRoot 'schemas'
  $provenance = Get-Content -LiteralPath (Join-Path $schemaRoot 'provenance.json') -Raw -Encoding UTF8 | ConvertFrom-Json
  $schemaPath = Join-Path $schemaRoot $provenance.validationSchema
  if ((Get-FileHash -LiteralPath $schemaPath -Algorithm SHA256).Hash -ine $provenance.validationSha256) { throw 'schema document.schema.json: vendored validation digest differs from provenance' }
  foreach ($source in $provenance.sources) {
    if ((Get-FileHash -LiteralPath (Join-Path $schemaRoot $source.path) -Algorithm SHA256).Hash -ine $source.sha256) { throw "schema $($source.path): upstream digest differs from provenance" }
  }
  $document = Get-Content -LiteralPath $DocumentPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($document.'$schema' -ne $provenance.declaredSchema) { throw 'configuration.winget $schema: declaration differs from official DSC provenance' }
  foreach ($resource in $document.resources) {
    if (-not $provenance.resources.PSObject.Properties[$resource.type]) { throw "resource $($resource.name): resource type $($resource.type) is not an approved discoverable WinGet resource" }
  }
  $schema = Get-Content -LiteralPath $schemaPath -Raw -Encoding UTF8 | ConvertFrom-Json
  Assert-SchemaVocabulary $schema
  $findings = @(Get-SchemaFindings $schema $document)
  if ($findings.Count -gt 0) {
    $label = 'configuration.winget'
    $match = [regex]::Match($findings[0], '\$/resources/(\d+)')
    if ($match.Success) { $label = 'resource ' + $document.resources[[int]$match.Groups[1].Value].name }
    throw "${label}: official DSC document JSON Schema validation failed: $($findings -join '; ')"
  }
}

if ($MyInvocation.InvocationName -ne '.') {
  $ErrorActionPreference = 'Stop'
  try { Invoke-DocumentSchemaCheck $DocumentPath $WindowsRoot }
  catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
}
