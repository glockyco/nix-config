$ErrorActionPreference = 'Stop'
$path = Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages/Rojetto.ReNeo.neo2_Microsoft.Winget.Source_8wekyb3d8bbwe/ReNeo/reneo.exe'
if (-not (Test-Path -LiteralPath $path)) { throw "ReNeo is not installed at $path" }
if (@(Get-Process -Name reneo -ErrorAction SilentlyContinue).Count -gt 0) { return }
Start-Process -FilePath $path -Verb RunAs
