{ lib }:

let
  withoutFinalNewline = lib.removeSuffix "\n";
  sha256Of = path: "(Get-FileHash -LiteralPath ${path} -Algorithm SHA256).Hash.ToLowerInvariant()";
in
{
  psJson = value: "'${builtins.replaceStrings [ "'" ] [ "''" ] (builtins.toJSON value)}'";

  psHereString =
    text:
    assert !(builtins.elem "'@" (builtins.split "\n" text));
    "@'\n${text}\n'@";

  inherit sha256Of;

  testSubsetFunction = withoutFinalNewline ''
    function Test-Subset($actual, $desired) {
      foreach ($property in $desired.PSObject.Properties) {
        $actualProperty = $actual.PSObject.Properties[$property.Name]
        if ($null -eq $actualProperty) { return $false }
        if ($property.Value -is [PSCustomObject]) {
          if (-not ($actualProperty.Value -is [PSCustomObject])) { return $false }
          if (-not (Test-Subset $actualProperty.Value $property.Value)) { return $false }
        } elseif (($property.Value | ConvertTo-Json -Depth 100 -Compress) -ne ($actualProperty.Value | ConvertTo-Json -Depth 100 -Compress)) {
          return $false
        }
      }
      return $true
    }
  '';

  mergeObjectFunction = withoutFinalNewline ''
    function Merge-Object($actual, $desired) {
      foreach ($property in $desired.PSObject.Properties) {
        $actualProperty = $actual.PSObject.Properties[$property.Name]
        if ($property.Value -is [PSCustomObject] -and $null -ne $actualProperty -and $actualProperty.Value -is [PSCustomObject]) {
          Merge-Object $actualProperty.Value $property.Value
        } elseif ($null -eq $actualProperty) {
          $actual | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value
        } else {
          $actualProperty.Value = $property.Value
        }
      }
    }
  '';

  expandArchive =
    { variable, label }:
    lib.concatStringsSep "\n" (
      lib.imap0 (index: line: if index == 0 then line else "  ${line}") (
        lib.splitString "\n" (withoutFinalNewline ''
          Invoke-WebRequest -Uri ${variable}.url -OutFile $archive -UseBasicParsing
          if (${sha256Of "$archive"} -ne ${variable}.archiveSha256) { throw '${label} archive checksum mismatch' }
          Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
          Add-Type -AssemblyName System.IO.Compression.FileSystem
          [IO.Compression.ZipFile]::ExtractToDirectory($archive, $expanded)
        '')
      )
    );

  requireAdministrator =
    operation:
    withoutFinalNewline ''
      $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
      if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw 'The ${operation} apply requires an Administrator PowerShell session'
      }
    '';
}
