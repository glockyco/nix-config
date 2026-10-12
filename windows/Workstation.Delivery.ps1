function Test-WorkstationFileHash {
  param([string]$Path, [string]$Sha256)
  return ((Test-Path -LiteralPath $Path -PathType Leaf) -and
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -eq $Sha256)
}

function Get-WorkstationArchiveVersion {
  param([hashtable]$Resource, [string]$Directory)
  $executable = Join-Path $Directory $Resource.executable
  if ($Resource.versionSource -eq 'file') {
    $output = (Get-Item -LiteralPath $executable).VersionInfo.ProductVersion
  } else {
    $output = Invoke-WorkstationNative -Command $executable -Arguments $Resource.versionArgs
  }
  $match = [regex]::Match([string]$output, '\d+\.\d+(?:[.\-]\d+){0,2}')
  if (-not $match.Success) { throw "$($Resource.id): cannot establish executable version" }
  return $match.Value
}

function Test-WorkstationArchivePayload {
  param([hashtable]$Resource, [string]$Directory)
  if (-not (Test-Path -LiteralPath (Join-Path $Directory $Resource.executable) -PathType Leaf)) { return $false }
  if ($Resource.ownedFiles) {
    $exact = $true
    foreach ($file in $Resource.ownedFiles.Keys) {
      $path = Join-Path $Directory $file
      if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
      if (-not (Test-WorkstationFileHash -Path $path -Sha256 $Resource.ownedFiles[$file])) { $exact = $false }
    }
    if ($exact) { return $true }
    $actual = Get-WorkstationArchiveVersion -Resource $Resource -Directory $Directory
    return ((Compare-WorkstationVersion -Actual $actual -Desired $Resource.releaseVersion) -gt 0)
  }
  $actual = Get-WorkstationArchiveVersion -Resource $Resource -Directory $Directory
  return ((Compare-WorkstationVersion -Actual $actual -Desired $Resource.releaseVersion) -ge 0)
}

function Test-WorkstationArchive {
  param([hashtable]$Resource, [hashtable]$Context)
  $directory = Get-WorkstationApplicationDirectory -Resource $Resource
  if (-not (Test-WorkstationArchivePayload -Resource $Resource -Directory $directory)) { return $false }
  if ($Resource.ownedFiles) { return $true }
  return (Test-WorkstationUserPath -Directory (Split-Path -Parent (Join-Path $directory $Resource.executable)))
}

function Expand-WorkstationArchive {
  param([hashtable]$Resource, [string]$Archive, [string]$Destination)
  if ($Resource.archiveKind -eq '7z') {
    $tar = Join-Path $env:SystemRoot 'System32\tar.exe'
    if (-not (Test-Path -LiteralPath $tar -PathType Leaf)) { throw 'Inbox System32/tar.exe is missing' }
    $null = Invoke-WorkstationNative -Command $tar -Arguments @('-xf', $Archive, '-C', $Destination)
  } else {
    Expand-Archive -LiteralPath $Archive -DestinationPath $Destination -Force
  }
}

function Save-WorkstationDownload {
  param([hashtable]$Resource, [string]$Path)
  Invoke-WebRequest -Uri $Resource.url -OutFile $Path | Out-Null
  if (-not (Test-WorkstationFileHash -Path $Path -Sha256 $Resource.sha256)) {
    throw "$($Resource.id): archive checksum mismatch"
  }
}

function Set-WorkstationArchive {
  param([hashtable]$Resource, [hashtable]$Context)
  $directory = Get-WorkstationApplicationDirectory -Resource $Resource
  $binDirectory = Split-Path -Parent (Join-Path $directory $Resource.executable)
  if (Test-WorkstationArchivePayload -Resource $Resource -Directory $directory) {
    if (-not $Resource.ownedFiles -and -not (Test-WorkstationUserPath -Directory $binDirectory)) {
      Set-WorkstationUserPath -Directory $binDirectory
    }
    return
  }
  $installedExecutable = Join-Path $directory $Resource.executable
  if (Test-Path -LiteralPath $installedExecutable -PathType Leaf) {
    $actual = Get-WorkstationArchiveVersion -Resource $Resource -Directory $directory
    if ((Compare-WorkstationVersion -Actual $actual -Desired $Resource.releaseVersion) -gt 0) {
      throw "$($Resource.id): refusing replacement of newer installed version $actual"
    }
  }
  $token = [guid]::NewGuid().ToString('N')
  $parent = Split-Path -Parent $directory
  $work = Join-Path $parent ".workstation-$token"
  $archive = Join-Path $work "download.$($Resource.archiveKind)"
  $expanded = Join-Path $work 'expanded'
  $staged = Join-Path $work 'installation'
  $backup = "$directory.previous-$token"
  $movedPrevious = $false
  try {
    New-Item -ItemType Directory -Path $expanded -Force | Out-Null
    Save-WorkstationDownload -Resource $Resource -Path $archive
    Expand-WorkstationArchive -Resource $Resource -Archive $archive -Destination $expanded
    $payload = Join-Path $expanded $Resource.payload
    if ($Resource.ownedFiles) {
      foreach ($file in $Resource.ownedFiles.Keys) {
        if (-not (Test-WorkstationFileHash -Path (Join-Path $payload $file) -Sha256 $Resource.ownedFiles[$file])) {
          throw "$($Resource.id): $file checksum mismatch"
        }
      }
      if (Test-Path -LiteralPath $directory -PathType Container) {
        Copy-Item -LiteralPath $directory -Destination $staged -Recurse
      } else {
        New-Item -ItemType Directory -Path $staged | Out-Null
      }
      # Only release-owned binaries cross the boundary. Chezmoi's INI remains untouched.
      foreach ($file in $Resource.ownedFiles.Keys) {
        Copy-Item -LiteralPath (Join-Path $payload $file) -Destination (Join-Path $staged $file) -Force
      }
    } else {
      Move-Item -LiteralPath $payload -Destination $staged
    }
    if (-not (Test-WorkstationArchivePayload -Resource $Resource -Directory $staged)) {
      throw "$($Resource.id): extracted executable failed version verification"
    }
    if ($Resource.process) {
      Get-Process -Name $Resource.process -ErrorAction SilentlyContinue | Stop-Process -ErrorAction Stop
    }
    if (Test-Path -LiteralPath $directory) {
      Move-Item -LiteralPath $directory -Destination $backup
      $movedPrevious = $true
    }
    Move-Item -LiteralPath $staged -Destination $directory
    if ($Resource.ownedFiles) {
      if ($Resource.process) { Start-Process -FilePath $installedExecutable | Out-Null }
    } else {
      Set-WorkstationUserPath -Directory $binDirectory
    }
  } catch {
    if ($movedPrevious -and -not (Test-Path -LiteralPath $directory)) {
      Copy-Item -LiteralPath $backup -Destination $directory -Recurse
    }
    throw
  } finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
  }
}

function Test-WorkstationJsonValue {
  param($Actual, $Desired)
  if ($null -eq $Desired) { return ($null -eq $Actual) }
  if ($Desired -is [System.Collections.IDictionary]) {
    if ($Actual -isnot [System.Collections.IDictionary] -or $Actual.Count -ne $Desired.Count) { return $false }
    foreach ($key in $Desired.Keys) {
      if (-not $Actual.Contains($key) -or -not (Test-WorkstationJsonValue -Actual $Actual[$key] -Desired $Desired[$key])) { return $false }
    }
    return $true
  }
  if ($Desired -is [array]) {
    if ($Actual -isnot [array] -or $Actual.Count -ne $Desired.Count) { return $false }
    for ($index = 0; $index -lt $Desired.Count; $index++) {
      if (-not (Test-WorkstationJsonValue -Actual $Actual[$index] -Desired $Desired[$index])) { return $false }
    }
    return $true
  }
  return ($Actual -ceq $Desired)
}

function Read-WorkstationJsonFile {
  param([string]$Path)
  return (Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable)
}

function Get-WorkstationNpmNodeResource {
  param([hashtable]$Resource, [hashtable]$Context)
  $nodes = @($Context.Data.applications | Where-Object { $_.id -eq $Resource.nodeId })
  if ($nodes.Count -ne 1) { throw "$($Resource.id): requires exactly one declared Node resource" }
  return $nodes[0]
}

function Test-WorkstationNpmPayload {
  param([hashtable]$Resource, [string]$Directory, [string]$Node)
  foreach ($file in @('package.json', 'package-lock.json')) {
    if (-not (Test-Path -LiteralPath (Join-Path $Directory $file) -PathType Leaf)) { return $false }
  }
  $manifest = Read-WorkstationJsonFile -Path (Join-Path $Directory 'package.json')
  $lock = Read-WorkstationJsonFile -Path (Join-Path $Directory 'package-lock.json')
  if (-not (Test-WorkstationJsonValue -Actual $manifest -Desired $Resource.manifest) -or
    -not (Test-WorkstationJsonValue -Actual $lock -Desired $Resource.lock)) { return $false }
  foreach ($entry in $Resource.lock.packages.Keys) {
    if (-not $entry) { continue }
    $selected = $Resource.lock.packages[$entry]
    # npm omits platform-specific optional dependencies on Windows.
    if ($selected.optional -and (($selected.os -and 'win32' -notin $selected.os) -or
      ($selected.cpu -and 'x64' -notin $selected.cpu))) { continue }
    $path = Join-Path $Directory "$entry/package.json"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $false }
    $installed = Read-WorkstationJsonFile -Path $path
    if ($installed.version -cne $selected.version) { return $false }
  }
  $binDirectory = Join-Path $Directory 'node_modules\.bin'
  foreach ($package in $Resource.packages.Keys) {
    $selected = $Resource.packages[$package]
    $packageDirectory = Join-Path $Directory "node_modules/$package"
    $installed = Read-WorkstationJsonFile -Path (Join-Path $packageDirectory 'package.json')
    if (-not (Test-WorkstationJsonValue -Actual $installed.bin -Desired $selected.bin)) { return $false }
    foreach ($command in $selected.bin.Keys) {
      $target = Join-Path $packageDirectory $selected.bin[$command]
      if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { return $false }
      foreach ($suffix in @('', '.cmd', '.ps1')) {
        $wrapper = Join-Path $binDirectory "$command$suffix"
        if (-not (Test-Path -LiteralPath $wrapper -PathType Leaf)) { return $false }
        $text = (Get-Content -LiteralPath $wrapper -Raw).Replace('\', '/')
        $expectedTarget = "../$package/$($selected.bin[$command])"
        if (-not $text.Contains($expectedTarget)) { return $false }
      }
      # svelteserver, tsserver and pyright-langserver have no version-only mode.
      if ($command -in @('pyright', 'tsc', 'typescript-language-server', 'openspec')) {
        $output = Invoke-WorkstationNative -Command $Node -Arguments @($target, '--version')
        $match = [regex]::Match($output, '\d+\.\d+\.\d+(?:[.\-]\d+)?')
        if (-not $match.Success -or $match.Value -ne $selected.version) { return $false }
      }
    }
  }
  return $true
}

function Test-WorkstationNpm {
  param([hashtable]$Resource, [hashtable]$Context)
  $node = Resolve-WorkstationExecutable -Resource (Get-WorkstationNpmNodeResource -Resource $Resource -Context $Context)
  if (-not $node) { return $false }
  if (-not (Test-Path -LiteralPath (Join-Path (Split-Path -Parent $node) 'npm.cmd') -PathType Leaf)) { return $false }
  $directory = Get-WorkstationApplicationDirectory -Resource $Resource
  if (-not (Test-WorkstationNpmPayload -Resource $Resource -Directory $directory -Node $node)) { return $false }
  return (Test-WorkstationUserPath -Directory (Join-Path $directory 'node_modules\.bin'))
}

function Set-WorkstationNpm {
  param([hashtable]$Resource, [hashtable]$Context)
  $directory = Get-WorkstationApplicationDirectory -Resource $Resource
  $node = Resolve-WorkstationExecutable -Resource (Get-WorkstationNpmNodeResource -Resource $Resource -Context $Context)
  if (-not $node) { throw 'npm requires the declared native per-user Node runtime' }
  $npm = Join-Path (Split-Path -Parent $node) 'npm.cmd'
  if (-not (Test-Path -LiteralPath $npm -PathType Leaf)) { throw 'npm.cmd is absent beside the selected node.exe' }
  $binDirectory = Join-Path $directory 'node_modules\.bin'
  if (Test-WorkstationNpmPayload -Resource $Resource -Directory $directory -Node $node) {
    if (-not (Test-WorkstationUserPath -Directory $binDirectory)) { Set-WorkstationUserPath -Directory $binDirectory }
    return
  }
  foreach ($package in $Resource.packages.Keys) {
    $path = Join-Path $directory "node_modules/$package/package.json"
    if (Test-Path -LiteralPath $path -PathType Leaf) {
      $installed = Read-WorkstationJsonFile -Path $path
      if ((Compare-WorkstationVersion -Actual $installed.version -Desired $Resource.packages[$package].version) -gt 0) {
        throw "$package`: refusing downgrade of installed version $($installed.version)"
      }
    }
  }
  $token = [guid]::NewGuid().ToString('N')
  $staged = "$directory.installing-$token"
  $backup = "$directory.previous-$token"
  $movedPrevious = $false
  try {
    New-Item -ItemType Directory -Path $staged -Force | Out-Null
    $encoding = [Text.UTF8Encoding]::new($false)
    [IO.File]::WriteAllText((Join-Path $staged 'package.json'), ($Resource.manifest | ConvertTo-Json -Depth 100), $encoding)
    [IO.File]::WriteAllText((Join-Path $staged 'package-lock.json'), ($Resource.lock | ConvertTo-Json -Depth 100), $encoding)
    $null = Invoke-WorkstationNative -Command $npm -Arguments @('ci', '--prefix', $staged, '--ignore-scripts', '--no-audit', '--no-fund')
    if (-not (Test-WorkstationNpmPayload -Resource $Resource -Directory $staged -Node $node)) {
      throw 'npm closure failed manifest, lock, binary or wrapper verification'
    }
    if (Test-Path -LiteralPath $directory) {
      Move-Item -LiteralPath $directory -Destination $backup
      $movedPrevious = $true
    }
    Move-Item -LiteralPath $staged -Destination $directory
    Set-WorkstationUserPath -Directory $binDirectory
  } catch {
    if ($movedPrevious -and -not (Test-Path -LiteralPath $directory)) {
      Copy-Item -LiteralPath $backup -Destination $directory -Recurse
    }
    throw
  } finally {
    if (Test-Path -LiteralPath $staged) { Remove-Item -LiteralPath $staged -Recurse -Force }
  }
}

function Get-WorkstationFontFamilies {
  Add-Type -AssemblyName System.Drawing
  $collection = [System.Drawing.Text.InstalledFontCollection]::new()
  try { return $collection.Families.Name } finally { $collection.Dispose() }
}

function Register-WorkstationFont {
  param([string]$Path)
  if (-not ('WorkstationNative.FontApi' -as [type])) {
    Add-Type -Namespace WorkstationNative -Name FontApi -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("gdi32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = true)]
public static extern int AddFontResourceEx(string filename, uint flags, System.IntPtr reserved);
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
public static extern System.IntPtr SendMessageTimeout(System.IntPtr window, uint message, System.UIntPtr wParam, System.IntPtr lParam, uint flags, uint timeout, out System.UIntPtr result);
'@
  }
  if ([WorkstationNative.FontApi]::AddFontResourceEx($Path, 0, [IntPtr]::Zero) -eq 0) {
    throw "Font could not be loaded: $Path"
  }
  $result = [UIntPtr]::Zero
  $null = [WorkstationNative.FontApi]::SendMessageTimeout([IntPtr]0xffff, 0x001d, [UIntPtr]::Zero, [IntPtr]::Zero, 0x0002, 5000, [ref]$result)
}

function Test-WorkstationFont {
  param([hashtable]$Resource, [hashtable]$Context)
  $directory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
  $registry = Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' -ErrorAction SilentlyContinue
  if ($null -eq $registry) { return $false }
  foreach ($file in $Resource.fonts.Keys) {
    $path = Join-Path $directory $file
    if (-not (Test-WorkstationFileHash -Path $path -Sha256 $Resource.fonts[$file].sha256)) { return $false }
    $property = $registry.PSObject.Properties[$Resource.fonts[$file].registryName]
    if ($null -eq $property -or $property.Value -ne $path) { return $false }
  }
  $regular = @($Resource.fonts.Values | Where-Object { $_.registryName -notmatch ' (Bold|Italic)' })
  if ($regular.Count -eq 1) {
    $family = $regular[0].registryName.Replace(' (TrueType)', '')
    if ($family -notin @(Get-WorkstationFontFamilies)) { return $false }
  }
  return $true
}

function Set-WorkstationFont {
  param([hashtable]$Resource, [hashtable]$Context)
  if (Test-WorkstationFont -Resource $Resource -Context $Context) { return }
  $directory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
  $registryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
  $registry = Get-ItemProperty -LiteralPath $registryPath -ErrorAction SilentlyContinue
  $missing = @()
  foreach ($file in $Resource.fonts.Keys) {
    $path = Join-Path $directory $file
    if (Test-Path -LiteralPath $path) {
      if (-not (Test-WorkstationFileHash -Path $path -Sha256 $Resource.fonts[$file].sha256)) {
        throw "$file`: existing font bytes differ. Owner review is required before replacement"
      }
    } else { $missing += $file }
    if ($null -ne $registry) {
      $property = $registry.PSObject.Properties[$Resource.fonts[$file].registryName]
      if ($null -ne $property -and $property.Value -ne $path) {
        throw "$file`: existing font registration conflicts. Owner review is required"
      }
    }
  }
  $work = Join-Path $env:TEMP ('.workstation-font-' + [guid]::NewGuid().ToString('N'))
  try {
    if ($missing.Count -gt 0) {
      $expanded = Join-Path $work 'expanded'
      $archive = Join-Path $work 'download.zip'
      New-Item -ItemType Directory -Path $expanded -Force | Out-Null
      Save-WorkstationDownload -Resource $Resource -Path $archive
      Expand-WorkstationArchive -Resource $Resource -Archive $archive -Destination $expanded
      # Validate every declared face before the first destination write.
      foreach ($file in $Resource.fonts.Keys) {
        if (-not (Test-WorkstationFileHash -Path (Join-Path $expanded $file) -Sha256 $Resource.fonts[$file].sha256)) {
          throw "$file`: extracted font checksum mismatch"
        }
      }
      New-Item -ItemType Directory -Path $directory -Force | Out-Null
      foreach ($file in $missing) {
        $destination = Join-Path $directory $file
        if (Test-Path -LiteralPath $destination) { throw "$file`: destination appeared during installation" }
        Copy-Item -LiteralPath (Join-Path $expanded $file) -Destination $destination
      }
    }
    New-Item -Path $registryPath -Force | Out-Null
    foreach ($file in $Resource.fonts.Keys) {
      $path = Join-Path $directory $file
      New-ItemProperty -LiteralPath $registryPath -Name $Resource.fonts[$file].registryName -Value $path -PropertyType String -Force | Out-Null
      Register-WorkstationFont -Path $path
    }
  } finally {
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
  }
}
