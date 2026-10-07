[CmdletBinding()]
param([switch]$Test)

$ErrorActionPreference = 'Stop'
$specification = '{"archiveSha256":"66f8e7f18c95a9a4416acc3d3eb52afcdbc2a3278a7286136c574b3271add84c","layoutFile":"kbdneo2.dll","layoutId":"b0000407","layoutText":"Deutsch (Neo)","sysWow64Sha256":"c10dfdb1ffd19f1a21b76f7288d3dde200ee19907bacd3acad8a70b19d887480","system32Sha256":"c5248c7b4024a2fdac956311a73a17428eab5fd54d59908a4a020501a49b775d","url":"https://dl.neo-layout.org/kbdneo64.zip","version":"2022-10-04"}' | ConvertFrom-Json
$system32 = Join-Path $env:SystemRoot "System32\$($specification.layoutFile)"
$sysWow64 = Join-Path $env:SystemRoot "SysWOW64\$($specification.layoutFile)"
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$($specification.layoutId)"
$registry = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
$desired = (Test-Path -LiteralPath $system32) `
  -and (Get-FileHash -LiteralPath $system32 -Algorithm SHA256).Hash.ToLowerInvariant() -eq $specification.system32Sha256 `
  -and (Test-Path -LiteralPath $sysWow64) `
  -and (Get-FileHash -LiteralPath $sysWow64 -Algorithm SHA256).Hash.ToLowerInvariant() -eq $specification.sysWow64Sha256 `
  -and $registry.'Layout Text' -eq $specification.layoutText `
  -and $registry.'Layout File' -eq $specification.layoutFile `
  -and $registry.'Layout Id' -eq '00c0' `
  -and $registry.'Layout Display Name' -eq '@%SystemRoot%\system32\kbdneo2.dll,-1000' `
  -and $registry.'Custom Language Name' -eq 'German (Germany)' `
  -and $registry.'Custom Language Display Name' -eq '@%SystemRoot%\system32\kbdneo2.dll,-1100'
if ($desired) {
  Write-Output 'kbdneo: desired'
  exit 0
}
if ($Test) {
  Write-Output 'kbdneo: drift'
  exit 1
}

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  throw 'The kbdneo apply requires an Administrator PowerShell session'
}
if (-not [Environment]::Is64BitProcess) {
  throw 'Run the kbdneo apply from 64-bit PowerShell'
}

$archive = Join-Path $env:TEMP 'kbdneo64.zip'
$expanded = Join-Path $env:TEMP 'kbdneo64'
try {
  Invoke-WebRequest -Uri $specification.url -OutFile $archive -UseBasicParsing
  if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $specification.archiveSha256) { throw 'kbdneo archive checksum mismatch' }
  Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [IO.Compression.ZipFile]::ExtractToDirectory($archive, $expanded)
  $payload = Join-Path $expanded 'kbdneo64'
  $system32Source = Join-Path $payload "System32\$($specification.layoutFile)"
  $sysWow64Source = Join-Path $payload "SysWOW64\$($specification.layoutFile)"
  if ((Get-FileHash -LiteralPath $system32Source -Algorithm SHA256).Hash.ToLowerInvariant() -ne $specification.system32Sha256) { throw 'kbdneo System32 DLL checksum mismatch' }
  if ((Get-FileHash -LiteralPath $sysWow64Source -Algorithm SHA256).Hash.ToLowerInvariant() -ne $specification.sysWow64Sha256) { throw 'kbdneo SysWOW64 DLL checksum mismatch' }
  Copy-Item -LiteralPath $system32Source -Destination $system32 -Force
  Copy-Item -LiteralPath $sysWow64Source -Destination $sysWow64 -Force
  New-Item -Path $registryPath -Force | Out-Null
  New-ItemProperty -Path $registryPath -Name 'Layout Text' -Value $specification.layoutText -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $registryPath -Name 'Layout File' -Value $specification.layoutFile -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $registryPath -Name 'Layout Id' -Value '00c0' -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $registryPath -Name 'Layout Display Name' -Value '@%SystemRoot%\system32\kbdneo2.dll,-1000' -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $registryPath -Name 'Custom Language Name' -Value 'German (Germany)' -PropertyType String -Force | Out-Null
  New-ItemProperty -Path $registryPath -Name 'Custom Language Display Name' -Value '@%SystemRoot%\system32\kbdneo2.dll,-1100' -PropertyType String -Force | Out-Null
} finally {
  Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Output 'kbdneo: changed; restart Windows before selecting the layout'
