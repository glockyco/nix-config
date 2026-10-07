Set-StrictMode -Version Latest

function Get-FormattingPolicy {
    param([string]$RepositoryRoot)
    $policy = Get-Content -LiteralPath (Join-Path $RepositoryRoot 'formatting.json') -Raw | ConvertFrom-Json
    if ($policy.version -ne 1) { throw 'Unsupported formatting.json policy version' }
    return $policy
}

# treefmt's basename globs match files at any depth; patterns containing a slash
# are relative to the root. ** crosses directories; * and ? do not.
function Test-FormattingPattern {
    param([string]$Path, [string]$Pattern)
    $candidate = $Path
    if (-not $Pattern.Contains('/')) { $candidate = ($Path -split '/')[-1] }
    $regex = [regex]::Escape($Pattern)
    $regex = $regex.Replace('\*\*', '.*').Replace('\*', '[^/]*').Replace('\?', '[^/]')
    return [regex]::IsMatch($candidate, '\A' + $regex + '\z')
}

function Get-FormattingPlan {
    param($Policy, [string[]]$Paths, [switch]$IncludeNix)
    foreach ($path in $Paths) {
        if ($path.StartsWith('/') -or $path -match '(^|/)\.\.(/|$)') { throw "Formatting path is outside checkout: $path" }
        $excluded = $false
        foreach ($pattern in $Policy.excludes) {
            if (Test-FormattingPattern $path $pattern) { $excluded = $true; break }
        }
        if ($excluded) { continue }
        foreach ($formatter in @($Policy.formatters | Sort-Object priority, name)) {
            if (-not $formatter.native -and -not $IncludeNix) { continue }
            foreach ($pattern in $formatter.includes) {
                if (Test-FormattingPattern $path $pattern) {
                    $configuration = $null
                    if ($formatter.PSObject.Properties['configuration']) { $configuration = $formatter.configuration }
                    [pscustomobject]@{ name = $formatter.name; path = $path; options = @($formatter.options); plugins = @($formatter.plugins); priority = $formatter.priority; configuration = $configuration }
                    break
                }
            }
        }
    }
}

function ConvertTo-NativeArgument {
    param([string]$Value)
    # CommandLineToArgvW quoting for Windows PowerShell's ProcessStartInfo.
    '"' + [regex]::Replace([regex]::Replace($Value, '(\\*)"', '$1$1\"'), '(\\+)$', '$1$1') + '"'
}

function Invoke-CapturedProcess {
    param([string]$Command, [string[]]$Arguments, [string]$WorkingDirectory)
    $info = New-Object System.Diagnostics.ProcessStartInfo
    $info.FileName = $Command
    $info.Arguments = (@($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' ')
    $info.WorkingDirectory = $WorkingDirectory
    $info.UseShellExecute = $false
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $info
    $buffer = New-Object System.IO.MemoryStream
    try {
        if (-not $process.Start()) { throw "Cannot start $Command" }
        $errorTask = $process.StandardError.ReadToEndAsync()
        $process.StandardOutput.BaseStream.CopyTo($buffer)
        $process.WaitForExit()
        [pscustomobject]@{ code = $process.ExitCode; output = [Text.Encoding]::UTF8.GetString($buffer.ToArray()); error = $errorTask.Result }
    } finally { $buffer.Dispose(); $process.Dispose() }
}

function Get-GitFormattingPaths {
    param([string]$RepositoryRoot, [switch]$Staged)
    $arguments = @('-C', $RepositoryRoot)
    if ($Staged) { $arguments += @('diff', '--cached', '--name-only', '--diff-filter=ACMR', '-z') }
    else { $arguments += @('ls-files', '-z') }
    $result = Invoke-CapturedProcess -Command 'git' -Arguments $arguments -WorkingDirectory $RepositoryRoot
    if ($result.code -ne 0) { throw "Cannot enumerate Git paths (exit $($result.code)): $($result.error)" }
    # Never split on lines, whitespace, or Git's optional quoted presentation.
    @($result.output.Split([char]0) | Where-Object { $_.Length -gt 0 })
}

function Invoke-NativeFormatting {
    param([string]$RepositoryRoot, [string]$ToolsRoot, [string[]]$Paths, [switch]$Check)
    $policy = Get-FormattingPolicy $RepositoryRoot
    $plan = @(Get-FormattingPlan -Policy $policy -Paths $Paths)
    $changed = New-Object 'System.Collections.Generic.List[string]'
    # Resolve every required tool before writing anything; GUI Git gets exactly
    # the bootstrap's pinned executables, not whichever versions are on PATH.
    $tools = @{}
    $configurations = @{}
    foreach ($entry in $plan) {
        if (-not $tools.ContainsKey($entry.name)) { $tools[$entry.name] = Get-NativeTool -Name $entry.name -ToolsRoot $ToolsRoot }
        if ($entry.configuration -and -not $configurations.ContainsKey($entry.name)) {
            $configurationPath = Join-Path $ToolsRoot ($entry.name + '-configuration.json')
            [IO.File]::WriteAllText($configurationPath, ($entry.configuration | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding($false)))
            $configurations[$entry.name] = $configurationPath
        }
    }
    foreach ($entry in $plan) {
        $file = Join-Path $RepositoryRoot $entry.path
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Tracked formatter input is missing: $($entry.path)" }
        $before = (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash
        $tool = $tools[$entry.name]
        # Go glob-based tools treat backslashes as escapes, even on Windows.
        $argumentPath = if ($env:OS -eq 'Windows_NT') { $file.Replace('\', '/') } else { $file }
        $options = @($entry.options | ForEach-Object { if ($_ -eq '@configuration@') { $configurations[$entry.name] } else { $_ } })
        $arguments = @($tool.prefixArguments) + $options + @($argumentPath)
        & $tool.command @arguments
        if ($LASTEXITCODE -ne 0) { throw "$($entry.name) failed (exit $LASTEXITCODE): $($entry.path)" }
        if ($Check -and (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash -ne $before) { $changed.Add($entry.path) }
    }
    if ($changed.Count -gt 0) { throw "Unformatted native files (formatter changes retained; review and stage): $($changed -join ', ')" }
}
