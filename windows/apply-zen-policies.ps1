[CmdletBinding()]
param([switch]$Test)

$ErrorActionPreference = 'Stop'
$browser = Join-Path $env:ProgramFiles 'Zen Browser\zen.exe'
$path = Join-Path $env:ProgramFiles 'Zen Browser\distribution\policies.json'
$desired = @'
{"policies":{"ExtensionSettings":{"enhancerforyoutube@maximerf.addons.mozilla.org":{"install_url":"https://addons.mozilla.org/firefox/downloads/latest/enhancer-for-youtube/latest.xpi","installation_mode":"force_installed"},"sponsorBlocker@ajay.app":{"install_url":"https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi","installation_mode":"force_installed"},"uBlock0@raymondhill.net":{"install_url":"https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi","installation_mode":"force_installed","private_browsing":true},"{1be309c5-3e4f-4b99-927d-bb500eb4fa88}":{"install_url":"https://addons.mozilla.org/firefox/downloads/latest/augmented-steam/latest.xpi","installation_mode":"force_installed"},"{446900e4-71c2-419f-a6a7-df9c091e268b}":{"install_url":"https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi","installation_mode":"force_installed","private_browsing":true},"{aecec67f-0d10-4fa7-b7c7-609a2db280cf}":{"install_url":"https://addons.mozilla.org/firefox/downloads/latest/violentmonkey/latest.xpi","installation_mode":"force_installed"}}}}
'@
$current = if (Test-Path -LiteralPath $path) { [IO.File]::ReadAllText($path) } else { $null }
if ($current -eq $desired) {
  Write-Output 'Zen policies: desired'
  exit 0
}
if ($Test) {
  Write-Output 'Zen policies: drift'
  exit 1
}

$principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  throw 'The Zen policy apply requires an Administrator PowerShell session'
}
if (-not (Test-Path -LiteralPath $browser)) {
  throw "Zen is not installed at $browser"
}

New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
[IO.File]::WriteAllText($path, $desired, [Text.UTF8Encoding]::new($false))
Write-Output 'Zen policies: changed'
