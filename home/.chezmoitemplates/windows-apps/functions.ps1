# Pure filters are shared by chezmoi modify files and the hold-aware apply hooks.
# Changed declared values use span edits; comments/undeclared bytes survive.
function Get-AppJsoncCleanText {
  param([string]$Text, [switch]$KeepTrailingCommas)
  $Text = $Text.TrimStart([char]0xfeff)
  if ([string]::IsNullOrWhiteSpace($Text)) { return '{}' }
  $chars = $Text.ToCharArray()
  $quoted = $false
  for ($i = 0; $i -lt $chars.Length; $i++) {
    if ($quoted) {
      if ($chars[$i] -eq '\') { $i++; continue }
      if ($chars[$i] -eq '"') { $quoted = $false }
    } elseif ($chars[$i] -eq '"') { $quoted = $true }
    elseif ($chars[$i] -eq '/' -and $i + 1 -lt $chars.Length) {
      if ($chars[$i + 1] -eq '/') {
        while ($i -lt $chars.Length -and $chars[$i] -ne "`n") { $chars[$i] = ' '; $i++ }
      } elseif ($chars[$i + 1] -eq '*') {
        $end = $Text.IndexOf('*/', $i + 2, [StringComparison]::Ordinal)
        if ($end -lt 0) { throw 'Unterminated JSONC comment; existing app settings were not overwritten' }
        for (; $i -lt $end + 2; $i++) { if ($chars[$i] -ne "`n" -and $chars[$i] -ne "`r") { $chars[$i] = ' ' } }
        $i--
      }
    }
  }
  if ($KeepTrailingCommas) { return -join $chars }
  $quoted = $false
  for ($i = 0; $i -lt $chars.Length; $i++) {
    if ($quoted) {
      if ($chars[$i] -eq '\') { $i++; continue }
      if ($chars[$i] -eq '"') { $quoted = $false }
    } elseif ($chars[$i] -eq '"') { $quoted = $true }
    elseif ($chars[$i] -eq ',') {
      $j = $i + 1
      while ($j -lt $chars.Length -and [char]::IsWhiteSpace($chars[$j])) { $j++ }
      if ($j -lt $chars.Length -and $chars[$j] -in @('}', ']')) { $chars[$i] = ' ' }
    }
  }
  return -join $chars
}

function ConvertFrom-AppJsonc {
  param([string]$Text)
  $clean = (Get-AppJsoncCleanText $Text).Trim()
  # PS5.1's PSCustomObject check also accepts wrapped arrays; require an object
  # in the JSON source before invoking that host's permissive converter.
  if (-not $clean.StartsWith('{') -or -not $clean.EndsWith('}')) { throw 'App settings must be a complete JSON object; existing file was not overwritten' }
  try { $value = $clean | ConvertFrom-Json -ErrorAction Stop }
  catch { throw "Malformed JSONC; existing file was not overwritten: $($_.Exception.Message)" }
  if ($null -eq $value -or $value -isnot [PSCustomObject]) { throw 'App settings must be a JSON object; existing file was not overwritten' }
  return $value
}


function Get-AppJson {
  param([string]$Text, $Desired, [string]$Kind)
  return Edit-AppJsonc $Text $Desired $Kind
}

function Get-AppIni {
  param([string]$Text, $Desired)
  $Text = $Text.TrimStart([char]0xfeff)
  $newline = if ($Text.Contains("`r`n")) { "`r`n" } else { "`n" }
  foreach ($section in $Desired.PSObject.Properties) {
    foreach ($setting in $section.Value.PSObject.Properties) {
      $lines = [Collections.Generic.List[string]]::new()
      foreach ($line in [regex]::Split($Text.TrimEnd("`r", "`n"), '\r?\n')) { $lines.Add($line) }
      if ($lines.Count -eq 1 -and $lines[0] -eq '') { $lines.Clear() }
      $start = -1; $end = $lines.Count
      for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\s*\[([^\]]+)\]\s*(?:[;#].*)?$') {
          if ($start -ge 0) { $end = $i; break }
          if ($Matches[1] -ieq $section.Name) { $start = $i }
        }
      }
      if ($start -lt 0) { $lines.Add('[' + $section.Name + ']'); $start = $lines.Count - 1; $end = $lines.Count }
      $found = $false
      for ($i = $end - 1; $i -gt $start; $i--) {
        if ($lines[$i] -match ('^\s*' + [regex]::Escape($setting.Name) + '\s*=')) {
          if (-not $found) { $lines[$i] = $setting.Name + '=' + $setting.Value; $found = $true }
          else { $lines.RemoveAt($i); $end-- }
        }
      }
      if (-not $found) { $lines.Insert($end, $setting.Name + '=' + $setting.Value) }
      $Text = [string]::Join($newline, $lines) + $newline
    }
  }
  return $Text
}

# AltSnap ships UTF-16 LE files. Its modify filter and drift check must use the
# same byte representation rather than the UTF-8 policy for JSON app settings.
function Get-AppIniBytes {
  param([byte[]]$Bytes, $Desired)
  $encoding = [Text.UTF8Encoding]::new($false)
  $offset = 0
  if ($Bytes.Length -ge 4 -and $Bytes[0] -eq 255 -and $Bytes[1] -eq 254 -and $Bytes[2] -eq 0 -and $Bytes[3] -eq 0) {
    $encoding = [Text.UTF32Encoding]::new($false, $true); $offset = 4
  } elseif ($Bytes.Length -ge 4 -and $Bytes[0] -eq 0 -and $Bytes[1] -eq 0 -and $Bytes[2] -eq 254 -and $Bytes[3] -eq 255) {
    $encoding = [Text.UTF32Encoding]::new($true, $true); $offset = 4
  } elseif ($Bytes.Length -ge 3 -and $Bytes[0] -eq 239 -and $Bytes[1] -eq 187 -and $Bytes[2] -eq 191) {
    $encoding = [Text.UTF8Encoding]::new($true); $offset = 3
  } elseif ($Bytes.Length -ge 2 -and $Bytes[0] -eq 255 -and $Bytes[1] -eq 254) {
    $encoding = [Text.UnicodeEncoding]::new($false, $true); $offset = 2
  } elseif ($Bytes.Length -ge 2 -and $Bytes[0] -eq 254 -and $Bytes[1] -eq 255) {
    $encoding = [Text.UnicodeEncoding]::new($true, $true); $offset = 2
  }
  $text = $encoding.GetString($Bytes, $offset, $Bytes.Length - $offset)
  $body = $encoding.GetBytes((Get-AppIni $text $Desired))
  return ,([byte[]]($encoding.GetPreamble() + $body))
}

function Test-AppIni {
  param([string]$Path, $Desired)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
  $bytes = [IO.File]::ReadAllBytes($Path)
  $expected = Get-AppIniBytes $bytes $Desired
  if ($bytes.Length -ne $expected.Length) { return $false }
  for ($i = 0; $i -lt $bytes.Length; $i++) {
    if ($bytes[$i] -ne $expected[$i]) { return $false }
  }
  return $true
}

function Read-AppText {
  param([string]$Path)
  if (Test-Path -LiteralPath $Path -PathType Leaf) { return [IO.File]::ReadAllText($Path) }
  return ''
}

function Write-AppText {
  param([string]$Path, [string]$Text)
  [void][IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
  [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Test-AppText {
  param([string]$Path, [string]$Desired)
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $false }
  $bytes = [IO.File]::ReadAllBytes($Path)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) { return $false }
  return [IO.File]::ReadAllText($Path) -ceq $Desired
}

function Stop-AppForWrite {
  param([string]$Name, [string]$RestartPath)
  $processes = @(Get-Process -Name $Name -ErrorAction SilentlyContinue)
  # PowerToys children are stopped together, but only its canonical runner is
  # launchable without the runner's child arguments and lifecycle ownership.
  $paths = if ($RestartPath) {
    if ($processes.Count -gt 0) { @($RestartPath) } else { @() }
  } else {
    @($processes | ForEach-Object {
      if (-not $_.Path) { throw "Cannot determine $Name executable for restart; refusing to stop it" }
      $_.Path
    } | Select-Object -Unique)
  }
  if ($processes.Count -gt 0) {
    $processes | Stop-Process -Force -ErrorAction Stop
    $processes | Wait-Process -Timeout 10 -ErrorAction Stop
  }
  return $paths
}

function Restart-AppAfterWrite {
  param([string[]]$Paths)
  foreach ($path in $Paths) { Start-Process -FilePath $path -ErrorAction Stop | Out-Null }
}

function Get-ZenProfiles {
  param([string]$ProfilesIni)
  if (-not (Test-Path -LiteralPath $ProfilesIni -PathType Leaf)) { throw 'Launch Zen once to create a real profile, then reapply chezmoi' }
  $sections = @(); $section = $null
  foreach ($line in [IO.File]::ReadAllLines($ProfilesIni)) {
    if ($line -match '^\s*\[([^\]]+)\]\s*$') {
      $section = [PSCustomObject]@{ Name = $Matches[1]; Values = @{} }; $sections += $section
    } elseif ($null -ne $section -and $line -match '^\s*([^=;#]+?)\s*=(.*)$') { $section.Values[$Matches[1]] = $Matches[2].Trim() }
  }
  $profiles = @()
  foreach ($section in $sections) {
    if ($section.Name -notmatch '^Profile\d+$') { continue }
    $values = $section.Values
    if (-not $values.Path -or $values.IsRelative -notin @('0', '1')) { throw "Zen $($section.Name) lacks Path/IsRelative" }
    $path = $values.Path.Replace('\', [IO.Path]::DirectorySeparatorChar).Replace('/', [IO.Path]::DirectorySeparatorChar)
    if ($values.IsRelative -eq '1') {
      if ([IO.Path]::IsPathRooted($path)) { throw "Zen $($section.Name) declares a rooted relative path" }
      $path = Join-Path (Split-Path -Parent $ProfilesIni) $path
    } elseif (-not [IO.Path]::IsPathRooted($path)) { throw "Zen $($section.Name) declares a non-absolute path" }
    $path = [IO.Path]::GetFullPath($path)
    if (-not (Test-Path -LiteralPath $path -PathType Container)) { throw "Zen profile does not exist: $path; no profile was fabricated" }
    $profiles += $path
  }
  if ($profiles.Count -eq 0) { throw 'Zen profiles.ini contains no real Profile sections' }
  return @($profiles | Select-Object -Unique)
}

function Get-ZenUserJs {
  param([string]$Text, $Preference)
  $Text = $Text.TrimStart([char]0xfeff)
  $line = 'user_pref(' + ($Preference.name | ConvertTo-Json -Compress) + ', ' + ($Preference.value | ConvertTo-Json -Compress) + ');'
  # Match only executable declarations, not examples in JS comments/strings.
  $call = [regex]::new('\Guser_pref\([\t ]*["'']' + [regex]::Escape($Preference.name) + '["''][\t ]*,[^;\r\n]*?\);')
  $removals = @()
  for ($i = 0; $i -lt $Text.Length; $i++) {
    $char = $Text[$i]
    if ($char -eq '/' -and $i + 1 -lt $Text.Length) {
      if ($Text[$i + 1] -eq '/') {
        while ($i -lt $Text.Length -and $Text[$i] -ne "`n") { $i++ }
        continue
      }
      if ($Text[$i + 1] -eq '*') {
        $end = $Text.IndexOf('*/', $i + 2, [StringComparison]::Ordinal)
        if ($end -lt 0) { throw 'Unterminated Zen user.js comment; existing preferences were not overwritten' }
        $i = $end + 1
        continue
      }
    }
    if ($char -in @('"', "'")) {
      $quote = $char; $i++
      while ($i -lt $Text.Length) {
        if ($Text[$i] -eq '\') { $i += 2; continue }
        if ($Text[$i] -eq $quote) { break }
        $i++
      }
      continue
    }
    if ($char -ne 'u' -or ($i -gt 0 -and $Text[$i - 1] -match '[\w$]')) { continue }
    $match = $call.Match($Text, $i)
    if (-not $match.Success) { continue }
    $start = $i; $end = $i + $match.Length
    # Remove the newline only for a standalone owned declaration. Same-line
    # comments and other preferences survive byte-for-byte.
    $lineStart = $Text.LastIndexOf("`n", $i) + 1
    $lineEnd = $Text.IndexOf("`n", $end)
    if ($lineEnd -lt 0) { $lineEnd = $Text.Length }
    if ([string]::IsNullOrWhiteSpace($Text.Substring($lineStart, $start - $lineStart)) -and [string]::IsNullOrWhiteSpace($Text.Substring($end, $lineEnd - $end))) {
      $start = $lineStart
      $end = [Math]::Min($Text.Length, $lineEnd + 1)
    }
    $removals += [PSCustomObject]@{ Start = $start; End = $end }
    $i = $end - 1
  }
  foreach ($removal in $removals | Sort-Object Start -Descending) { $Text = $Text.Remove($removal.Start, $removal.End - $removal.Start) }
  if ($Text.Length -gt 0 -and -not $Text.EndsWith("`n")) { $Text += "`n" }
  return $Text + $line + "`n"
}

function Get-TernUserPath {
  param([string]$Current, [string]$Directory)
  $entries = [Collections.Generic.List[string]]::new()
  $found = $false
  foreach ($entry in $Current.Split(';')) {
    $expanded = [Environment]::ExpandEnvironmentVariables($entry.Trim().Trim('"')).TrimEnd('\', '/')
    if ($expanded -ieq $Directory.TrimEnd('\', '/')) {
      if (-not $found) { $entries.Add($Directory); $found = $true }
    } elseif ($entry.Length -gt 0) { $entries.Add($entry) }
  }
  if (-not $found) { $entries.Add($Directory) }
  return [string]::Join(';', $entries)
}

function Get-ZenWrites {
  param([string]$ProfilesIni, $Files, $Preference)
  # Fresh installs have no profile until the owner launches Zen. Skip only that
  # absent prerequisite; declared but malformed/missing profile paths are fatal.
  if (-not (Test-Path -LiteralPath $ProfilesIni -PathType Leaf)) { return }
  $profiles = @(Get-ZenProfiles $ProfilesIni)
  foreach ($profile in $profiles) {
    foreach ($file in $Files) {
      $path = Join-Path $profile ('chrome/' + $file.Name)
      if (-not (Test-AppText $path $file.Text)) { [PSCustomObject]@{ Path = $path; Text = $file.Text } }
    }
    $path = Join-Path $profile 'user.js'
    $text = Get-ZenUserJs (Read-AppText $path) $Preference
    if (-not (Test-AppText $path $text)) { [PSCustomObject]@{ Path = $path; Text = $text } }
  }
}

function Apply-ZenWrites {
  param($Writes)
  if (@($Writes).Count -eq 0) { return }
  $restart = @(Stop-AppForWrite 'zen')
  try { foreach ($write in $Writes) { Write-AppText $write.Path $write.Text } }
  finally { Restart-AppAfterWrite $restart }
}

function Open-AppUserEnvironment {
  param([bool]$Writable)
  return [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $Writable)
}

function Get-AppUserPath {
  $key = Open-AppUserEnvironment $false
  try {
    return [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
  } finally { $key.Dispose() }
}

function Invoke-AppEnvironmentMessage {
  param([IntPtr]$Window, [uint32]$Message, [IntPtr]$WParam, [string]$LParam, [uint32]$Flags, [uint32]$Timeout)
  if (-not ('WindowsAppEnvironment.NativeMethods' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
namespace WindowsAppEnvironment {
  public static class NativeMethods {
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr SendMessageTimeout(IntPtr window, uint message,
      IntPtr wParam, string lParam, uint flags, uint timeout, out UIntPtr result);
  }
}
'@
  }
  $result = [UIntPtr]::Zero
  [void][WindowsAppEnvironment.NativeMethods]::SendMessageTimeout($Window, $Message, $WParam, $LParam, $Flags, $Timeout, [ref]$result)
}

function Send-AppEnvironmentChange {
  # HWND_BROADCAST, WM_SETTINGCHANGE, SMTO_ABORTIFHUNG.
  Invoke-AppEnvironmentMessage -Window ([IntPtr]0xffff) -Message 0x1a -WParam ([IntPtr]::Zero) -LParam 'Environment' -Flags 2 -Timeout 5000
}

function Set-AppUserPath {
  param([string]$Value)
  $key = Open-AppUserEnvironment $true
  try { $key.SetValue('Path', $Value, [Microsoft.Win32.RegistryValueKind]::ExpandString) }
  finally { $key.Dispose() }
  Send-AppEnvironmentChange
}
