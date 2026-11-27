#Requires -Version 7.0
$ErrorActionPreference = 'Stop'
$directory = Join-Path $env:LOCALAPPDATA 'WindowsConfiguration'
$null = New-Item -ItemType Directory -Path $directory -Force
$log = Join-Path $directory 'personal-plugin-upgrade.log'

function Write-PluginUpdateLog {
    param([string] $Message)
    Add-Content -LiteralPath $log -Value "$(Get-Date -Format o) $Message" -Encoding utf8
}

function Invoke-PluginUpdateCommand {
    param([string] $Command, [string[]] $Arguments)
    $commandLine = "$Command $($Arguments -join ' ')"
    $process = New-Object System.Diagnostics.Process
    try {
        $process.StartInfo.FileName = (Get-Command $Command -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.RedirectStandardInput = $true
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        # OMP and Git write UTF-8, which the console code page would garble in the log.
        $process.StartInfo.StandardOutputEncoding = [Text.Encoding]::UTF8
        $process.StartInfo.StandardErrorEncoding = [Text.Encoding]::UTF8
        $process.StartInfo.Environment['GIT_TERMINAL_PROMPT'] = '0'
        $process.StartInfo.Environment['GIT_SSH_COMMAND'] = 'ssh -o BatchMode=yes'
        $process.StartInfo.Environment['GCM_INTERACTIVE'] = '0'
        foreach ($argument in $Arguments) { $process.StartInfo.ArgumentList.Add($argument) }
        $timer = [Diagnostics.Stopwatch]::StartNew()
        $null = $process.Start()
        $process.StandardInput.Close()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        $streams = [Threading.Tasks.Task[]]@($stdout, $stderr)
        if (-not $process.WaitForExit(300000) -or
            -not [Threading.Tasks.Task]::WaitAll($streams, [int][Math]::Max(0, 300000 - $timer.ElapsedMilliseconds))) {
            try { $process.Kill($true) }
            catch [InvalidOperationException] { if (-not $process.HasExited) { throw } }
            finally { Write-PluginUpdateLog "$commandLine timed out after 300 seconds" }
            return @{ Code = 124; Stdout = ''; Stderr = '' }
        }
        foreach ($line in (($stdout.Result + "`n" + $stderr.Result) -split '\r?\n')) {
            if ($line) { Write-PluginUpdateLog $line }
        }
        return @{ Code = $process.ExitCode; Stdout = $stdout.Result; Stderr = $stderr.Result }
    } catch {
        Write-PluginUpdateLog "${commandLine}: $_"
        return @{ Code = 1; Stdout = ''; Stderr = '' }
    } finally {
        $process.Dispose()
    }
}

function Read-PluginMarketplaces {
    $result = Invoke-PluginUpdateCommand -Command omp -Arguments @('plugin', 'marketplace', 'list')
    if ($result.Code -ne 0) { return $null }
    $lines = @($result.Stdout.Trim() -split '\r?\n' | Where-Object { $_.Trim() })
    $marketplaces = @{}
    if ($lines.Count -eq 2 -and $lines[0] -ceq 'No marketplaces configured' -and
        $lines[1].Trim() -ceq 'Add one with: omp plugin marketplace add <source>') { return $marketplaces }
    if ($lines.Count -eq 0 -or $lines[0].Trim() -cne 'Configured Marketplaces:') { return $null }
    foreach ($line in ($lines | Select-Object -Skip 1)) {
        if ($line -notmatch '^\s+(\S+)\s{2,}(\S+)\s*$' -or $marketplaces.ContainsKey($Matches[1])) { return $null }
        $marketplaces[$Matches[1]] = $Matches[2]
    }
    return $marketplaces
}

function Invoke-PersonalPluginUpdate {
    param([string] $Directory)
    try {
        Write-PluginUpdateLog 'Personal plugin update starting'
        $env:PATH = [Environment]::ExpandEnvironmentVariables(
            [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('Path', 'User'))
        $plugins = Get-Content -LiteralPath (Join-Path $Directory 'omp-plugins.json') -Raw | ConvertFrom-Json -NoEnumerate
        foreach ($entry in $plugins) {
            $url = "https://github.com/$($entry.source)"
            $result = Invoke-PluginUpdateCommand -Command git -Arguments @('ls-remote', '--exit-code', $url, 'HEAD')
            if ($result.Code -ne 0) { Write-PluginUpdateLog "Git cannot read ${url}: run gh auth login -h github.com --web" }
        }
        $marketplaces = Read-PluginMarketplaces
        if ($null -eq $marketplaces) { Write-PluginUpdateLog 'Cannot read omp plugin marketplace list' }
        $missing = @{}
        if ($null -ne $marketplaces) {
            foreach ($entry in $plugins) {
                $name = $entry.marketplace
                if (-not $marketplaces.ContainsKey($name)) {
                    Write-PluginUpdateLog "Marketplace $name is not registered: run omp plugin marketplace add $($entry.source)"
                    $missing[$name] = $true
                } elseif ($marketplaces[$name] -cne $entry.source) {
                    Write-PluginUpdateLog "Marketplace $name is registered as $($marketplaces[$name]), declared $($entry.source): run omp plugin marketplace remove $name && omp plugin marketplace add $($entry.source)"
                }
            }
        }
        $failed = $missing.Count -ne 0
        foreach ($entry in $plugins) {
            if ($missing.ContainsKey($entry.marketplace)) { continue }
            for ($attempt = 1; $attempt -le 4; $attempt++) {
                Write-PluginUpdateLog "Marketplace $($entry.marketplace) refresh attempt $attempt"
                $result = Invoke-PluginUpdateCommand -Command omp -Arguments @('plugin', 'marketplace', 'update', $entry.marketplace)
                if ($result.Code -eq 0) { break }
                Write-PluginUpdateLog "Marketplace $($entry.marketplace) refresh exited $($result.Code)"
                if ($attempt -eq 4 -or ($result.Stdout + "`n" + $result.Stderr) -notmatch '\bEPERM\b') { break }
                Start-Sleep -Seconds 15
            }
            if ($result.Code -ne 0) {
                $failed = $true
                continue
            }
            $result = Invoke-PluginUpdateCommand -Command omp -Arguments @('plugin', 'upgrade', '--scope', 'user', $entry.plugin)
            if ($result.Code -ne 0) {
                Write-PluginUpdateLog "Plugin $($entry.plugin) upgrade exited $($result.Code)"
                $failed = $true
            }
        }
        if ($failed) {
            Write-PluginUpdateLog 'Personal plugin update failed for one or more plugins'
            return 1
        }
        Write-PluginUpdateLog 'Personal plugin update succeeded'
        return 0
    } catch {
        Write-PluginUpdateLog "Personal plugin update failed: $_"
        return 1
    }
}

exit (Invoke-PersonalPluginUpdate -Directory $directory)
