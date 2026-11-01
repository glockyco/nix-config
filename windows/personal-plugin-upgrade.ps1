#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$directory = Join-Path $env:LOCALAPPDATA 'WindowsConfiguration'
$null = New-Item -ItemType Directory -Path $directory -Force
$log = Join-Path $directory 'personal-plugin-upgrade.log'

function Write-PluginUpdateLog {
    param([string] $Message)
    Add-Content -LiteralPath $log -Value "$(Get-Date -Format o) $Message" -Encoding utf8
}

function Invoke-PluginUpdateCommand {
    param([string[]] $Arguments)
    $output = @(& $script:omp @Arguments 2>&1)
    $code = $LASTEXITCODE
    foreach ($line in $output) { Write-PluginUpdateLog ([string]$line) }
    return @{ Code = $code; Output = $output -join [Environment]::NewLine }
}

function Invoke-PersonalPluginUpdate {
try {
    Write-PluginUpdateLog 'Personal plugin update starting'
    $env:PATH = [Environment]::ExpandEnvironmentVariables(
        [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User'))
    $script:omp = (Get-Command omp -CommandType Application -ErrorAction Stop).Source
    for ($attempt = 1; $attempt -le 4; $attempt++) {
        Write-PluginUpdateLog "Marketplace refresh attempt $attempt"
        $result = Invoke-PluginUpdateCommand -Arguments @('plugin', 'marketplace', 'update', 'glockyco')
        if ($result.Code -eq 0) { break }
        if ($result.Output -notmatch '\bEPERM\b' -or $attempt -eq 4) {
            throw "Marketplace refresh exited $($result.Code)"
        }
        Start-Sleep -Seconds 15
    }
    $result = Invoke-PluginUpdateCommand -Arguments @('plugin', 'upgrade', '--scope', 'user', 'personal@glockyco')
    if ($result.Code -ne 0) { throw "Personal plugin upgrade exited $($result.Code)" }
    Write-PluginUpdateLog 'Personal plugin update succeeded'
    return 0
} catch {
    Write-PluginUpdateLog "Personal plugin update failed: $_"
    return 1
}
}

exit (Invoke-PersonalPluginUpdate)
