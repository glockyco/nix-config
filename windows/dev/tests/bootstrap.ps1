[CmdletBinding()]
param([string]$RepositoryRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent }
. (Join-Path $RepositoryRoot 'windows/dev/bootstrap.ps1') -RepositoryRoot $RepositoryRoot
$script:BootstrapReceive = ${function:Receive-NativeArtifact}

function Assert-BootstrapFixture {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw "Bootstrap fixture: $Message" }
}

function Assert-BootstrapFailure {
    param([string]$Name, [scriptblock]$Action, [string]$Pattern)
    $failure = $null
    try { & $Action | Out-Null } catch { $failure = $_.Exception.Message }
    Assert-BootstrapFixture -Condition ($null -ne $failure -and $failure -match $Pattern) -Message "$Name did not fail with '$Pattern': $failure"
    Write-Output "PASS negative bootstrap fixture: $Name"
}

function Invoke-WebRequest {
    param([switch]$UseBasicParsing, [string]$Uri, [string]$OutFile)
    $script:ObservedProgressPreference = $ProgressPreference
    if ($script:WebRequestFault) { throw 'fixture download failure' }
    [IO.File]::WriteAllText($OutFile, 'fixture artifact', (New-Object Text.UTF8Encoding($false)))
}

# Doubles intercept downloads, extraction and native processes, never the lock/hash/lookup/bootstrap decisions.
function Receive-NativeArtifact {
    param([string]$Uri, [string]$Destination)
    $script:DownloadCount++
    if ($script:DownloadFault -eq 'missing') { return }
    $content = if ($script:DownloadFault -eq 'hash') { 'corrupt' } else { 'fixture artifact' }
    [IO.File]::WriteAllText($Destination, $content, (New-Object Text.UTF8Encoding($false)))
}

function Expand-NativeArtifact {
    param($Artifact, [string]$Path, [string]$Destination)
    $script:ExtractionCount++
    $relative = switch ($Artifact.name) {
        'python' { 'python.exe' }
        'node' { 'node-v' + $Artifact.version + '-win-x64/node.exe' }
        'ruff' { 'ruff-' + $Artifact.version + '.data/scripts/ruff.exe' }
        'prettier' { 'package/bin/prettier.cjs' }
        'jsonfmt' { 'jsonfmt.exe' }
        'yamlfmt' { 'yamlfmt.exe' }
        'lefthook' { 'lefthook.exe' }
        'chezmoi' { 'chezmoi.exe' }
        default { $Artifact.name + '.dist-info/METADATA' }
    }
    $file = Join-Path $Destination $relative
    $null = New-Item -ItemType Directory -Path (Split-Path $file -Parent) -Force
    [IO.File]::WriteAllText($file, 'isolated fixture executable', (New-Object Text.UTF8Encoding($false)))
}

function Get-BootstrapFixtureVersion {
    param([string]$Name)
    (@($script:FixtureLock.tools | Where-Object { $_.id -eq $Name })[0]).version
}

function Invoke-NativeProcess {
    param([string]$Command, [string[]]$Arguments)
    $script:ProcessCount++
    if ($Command -eq 'git') {
        $relative = $Arguments[-1]
        $output = if ($relative -eq 'hooks/pre-commit') { '.git/hooks/pre-commit' } else { '.git/native-dev' }
        return [PSCustomObject]@{ ExitCode = 0; Output = $output }
    }
    if ($script:ProcessFault -eq 'exit') { return [PSCustomObject]@{ ExitCode = 23; Output = 'fixture native failure' } }
    if ($script:ProcessFault -eq 'version') { return [PSCustomObject]@{ ExitCode = 0; Output = '0.0.0' } }
    if ($Arguments[0] -eq '-c') {
        $wheels = @($script:FixtureLock.artifacts | Where-Object { $_.kind -eq 'wheel' })
        $output = ($wheels | ForEach-Object { "$($_.name)=$($_.version)" }) -join ';'
        if ($script:ProcessFault -eq 'closure') { $output = 'invalid fixture closure' }
    } elseif ($Arguments -contains 'mdformat') { $output = 'mdformat ' + (Get-BootstrapFixtureVersion mdformat) }
    elseif ($Arguments[0] -like '*prettier.cjs') { $output = Get-BootstrapFixtureVersion prettier }
    else {
        $output = switch ([IO.Path]::GetFileName($Command)) {
            'python.exe' { 'Python ' + (Get-BootstrapFixtureVersion python) }
            'node.exe' { 'v' + (Get-BootstrapFixtureVersion node) }
            'ruff.exe' { 'ruff ' + (Get-BootstrapFixtureVersion ruff-format) }
            'jsonfmt.exe' { 'jsonfmt version ' + (Get-BootstrapFixtureVersion jsonfmt) }
            'yamlfmt.exe' { 'yamlfmt ' + (Get-BootstrapFixtureVersion yamlfmt) + ' (fixture)' }
            'lefthook.exe' { Get-BootstrapFixtureVersion lefthook }
            'chezmoi.exe' { 'chezmoi version v' + (Get-BootstrapFixtureVersion chezmoi) + ', fixture' }
            default { throw "Unexpected fixture command $Command" }
        }
    }
    [PSCustomObject]@{ ExitCode = 0; Output = $output }
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ('native bootstrap fixtures ' + [Guid]::NewGuid().ToString('N'))
$originalLockPath = $script:NativeLockPath
$originalOS = $env:OS
$env:OS = 'Windows_NT'
$script:DownloadFault = ''
$script:ProcessFault = ''
$script:DownloadCount = 0
$script:ExtractionCount = 0
$script:ProcessCount = 0
try {
    $null = New-Item -ItemType Directory -Path $temp
    $script:WebRequestFault = $false
    $savedProgressPreference = $ProgressPreference
    & $script:BootstrapReceive -Uri 'https://fixture.invalid/artifact' -Destination (Join-Path $temp 'progress artifact')
    Assert-BootstrapFixture -Condition ($script:ObservedProgressPreference -eq 'SilentlyContinue' -and $ProgressPreference -eq $savedProgressPreference) -Message 'download progress was not suppressed locally and restored'
    $script:WebRequestFault = $true
    Assert-BootstrapFailure 'download progress restoration' { & $script:BootstrapReceive -Uri 'https://fixture.invalid/artifact' -Destination (Join-Path $temp 'progress artifact') } 'fixture download failure'
    Assert-BootstrapFixture -Condition ($ProgressPreference -eq $savedProgressPreference) -Message 'failed download changed caller progress preference'
    $script:WebRequestFault = $false
    $fixtureArtifact = Join-Path $temp 'artifact'
    [IO.File]::WriteAllText($fixtureArtifact, 'fixture artifact', (New-Object Text.UTF8Encoding($false)))
    $script:FixtureLock = Get-NativeDependencies
    foreach ($artifact in $script:FixtureLock.artifacts) {
        $artifact.sha256 = (Get-FileHash -LiteralPath $fixtureArtifact -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($artifact.PSObject.Properties.Name -contains 'integrity') {
            $sha = [Security.Cryptography.SHA512]::Create()
            try { $artifact.integrity = 'sha512-' + [Convert]::ToBase64String($sha.ComputeHash([IO.File]::ReadAllBytes($fixtureArtifact))) }
            finally { $sha.Dispose() }
        }
    }
    $script:NativeLockPath = Join-Path $temp 'dependencies.lock.json'
    [IO.File]::WriteAllText($script:NativeLockPath, ($script:FixtureLock | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding($false)))
    $checkout = Join-Path $temp 'checkout with spaces'
    $null = New-Item -ItemType Directory -Path $checkout
    $root = Get-NativeToolsRoot -RepositoryRoot $checkout
    Invoke-NativeBootstrap -RepositoryRoot $checkout | Out-Null
    Assert-BootstrapFixture -Condition (Test-Path -LiteralPath (Join-Path $root 'tools.json')) -Message 'normal bootstrap did not install manifest'
    $hook = Get-NativeHookPath -RepositoryRoot $checkout
    $hookBytes = [IO.File]::ReadAllBytes($hook)
    Assert-BootstrapFixture -Condition ($hookBytes[0] -eq 35 -and [IO.File]::ReadAllText($hook) -ceq (Get-NativeHookContent)) -Message 'hook has a BOM or differs from the owned launcher'
    $launcher = [IO.File]::ReadAllText($hook)
    Assert-BootstrapFixture -Condition ($launcher.Contains('exec pwsh.exe -NoProfile -NonInteractive -File') -and -not $launcher.Contains('powershell.exe')) -Message 'hook did not dispatch exclusively to pwsh'
    $previous = $launcher.Replace('native pre-commit v2', 'native pre-commit v1').
        Replace('pwsh.exe', 'powershell.exe').
        Replace('PowerShell 7 is required; run windows/bootstrap.ps1.', 'Windows PowerShell is required; run windows/dev/bootstrap.ps1.').
        Replace('-NoProfile -NonInteractive -File', '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File')
    [IO.File]::WriteAllText($hook, $previous)
    Install-NativeHook -RepositoryRoot $checkout
    Assert-BootstrapFixture -Condition ([IO.File]::ReadAllText($hook) -ceq $launcher) -Message 'exact prior owned hook was not migrated to pwsh'
    $downloads = $script:DownloadCount
    $processes = $script:ProcessCount
    Invoke-NativeBootstrap -RepositoryRoot $checkout | Out-Null
    Assert-BootstrapFixture -Condition ($script:DownloadCount -eq $downloads -and $script:ProcessCount -gt $processes) -Message 'repeat bootstrap downloaded again or skipped version verification'
    Assert-BootstrapFixture -Condition ([Convert]::ToBase64String([IO.File]::ReadAllBytes($hook)) -ceq [Convert]::ToBase64String($hookBytes)) -Message 'repeat bootstrap changed the hook'
    Assert-BootstrapFixture -Condition (@(Get-ChildItem -LiteralPath (Split-Path $hook -Parent) -File).Count -eq 1) -Message 'bootstrap installed duplicate hooks'
    $tool = Get-NativeTool -Name prettier -ToolsRoot $root
    Assert-BootstrapFixture -Condition ([IO.Path]::IsPathRooted($tool.command) -and [IO.Path]::IsPathRooted($tool.prefixArguments[0])) -Message 'prettier did not resolve locked absolute runtime/script paths'
    Write-Output 'PASS bootstrap normal, repeat, paths with spaces, and one idempotent hook'

    Invoke-NativeBootstrap -RepositoryRoot $checkout -IncludeTestDependencies -SkipHook | Out-Null
    $manifest = Get-Content -LiteralPath (Join-Path $root 'tools.json') -Raw | ConvertFrom-Json
    Assert-BootstrapFixture -Condition $manifest.includeTestDependencies -Message 'test dependency upgrade was not recorded'
    $null = Get-NativeTool -Name mdformat -ToolsRoot $root
    $null = Get-NativeTool -Name chezmoi -ToolsRoot $root
    Write-Output 'PASS bootstrap isolated test dependency closure upgrade'

    $cache = Join-Path $temp 'archive cache with spaces'
    $cachedTools = Join-Path $temp 'cold cache tools'
    $downloads = $script:DownloadCount
    Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot $cachedTools -ArchiveCacheRoot $cache -IncludeTestDependencies -SkipHook | Out-Null
    Assert-BootstrapFixture -Condition ($script:DownloadCount -eq $downloads + $script:FixtureLock.artifacts.Count) -Message 'cold cache did not download the full test dependency closure'
    Assert-BootstrapFixture -Condition (@(Get-ChildItem -LiteralPath $cache -File).Count -eq $script:FixtureLock.artifacts.Count -and @(Get-ChildItem -LiteralPath $cache -Directory).Count -eq 0) -Message 'cache contains extracted installations or lacks locked archives'
    $warmTools = Join-Path $temp 'warm cache tools'
    $downloads = $script:DownloadCount
    Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot $warmTools -ArchiveCacheRoot $cache -IncludeTestDependencies -SkipHook | Out-Null
    Assert-BootstrapFixture -Condition ($script:DownloadCount -eq $downloads) -Message 'warm cache redownloaded locked archives'
    $null = Get-NativeTool -Name mdformat -ToolsRoot $warmTools
    $cachedArtifact = Join-Path $cache $script:FixtureLock.artifacts[0].file
    $cachedBytes = [IO.File]::ReadAllBytes($cachedArtifact)
    [IO.File]::WriteAllText($cachedArtifact, 'corrupt cache')
    $extractions = $script:ExtractionCount
    $corruptRoot = Join-Path $temp 'corrupt cache tools'
    Assert-BootstrapFailure 'restored archive hash' { Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot $corruptRoot -ArchiveCacheRoot $cache -IncludeTestDependencies -SkipHook } 'SHA-256 mismatch'
    Assert-BootstrapFailure 'installed tools restored archive hash' { Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot $warmTools -ArchiveCacheRoot $cache -IncludeTestDependencies -SkipHook } 'SHA-256 mismatch'
    Assert-BootstrapFixture -Condition ($script:DownloadCount -eq $downloads -and $script:ExtractionCount -eq $extractions -and -not (Test-Path -LiteralPath $corruptRoot) -and [IO.File]::ReadAllText($cachedArtifact) -ceq 'corrupt cache') -Message 'cache corruption was redownloaded, overwritten, extracted or installed'
    [IO.File]::WriteAllBytes($cachedArtifact, $cachedBytes)
    $lockBytes = [IO.File]::ReadAllBytes($script:NativeLockPath)
    $npmArtifact = @($script:FixtureLock.artifacts | Where-Object name -eq 'prettier')[0]
    $npmIntegrity = $npmArtifact.integrity
    $npmArtifact.integrity = 'sha512-invalid'
    [IO.File]::WriteAllText($script:NativeLockPath, ($script:FixtureLock | ConvertTo-Json -Depth 10))
    Assert-BootstrapFailure 'restored npm integrity' { Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot (Join-Path $temp 'bad cached npm tools') -ArchiveCacheRoot $cache -IncludeTestDependencies -SkipHook } 'npm integrity mismatch'
    Assert-BootstrapFixture -Condition ($script:DownloadCount -eq $downloads) -Message 'restored npm integrity failure redownloaded an archive'
    $npmArtifact.integrity = $npmIntegrity
    [IO.File]::WriteAllBytes($script:NativeLockPath, $lockBytes)
    Assert-BootstrapFailure 'archive cache inside tools' { Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot $warmTools -ArchiveCacheRoot (Join-Path $warmTools 'archives') -SkipHook } 'separate, non-overlapping'
    Assert-BootstrapFailure 'tools inside archive cache' { Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot (Join-Path $cache 'tools') -ArchiveCacheRoot $cache -SkipHook } 'separate, non-overlapping'
    $script:DownloadFault = 'hash'
    $freshBadCache = Join-Path $temp 'bad fresh archive cache'
    Assert-BootstrapFailure 'fresh cache archive hash' { Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot (Join-Path $temp 'bad fresh cached tools') -ArchiveCacheRoot $freshBadCache -SkipHook } 'SHA-256 mismatch'
    Assert-BootstrapFixture -Condition (@(Get-ChildItem -LiteralPath $freshBadCache).Count -eq 0 -and @(Get-ChildItem -LiteralPath $temp -Directory | Where-Object Name -like 'native-dev-stage-*').Count -eq 0) -Message 'failed download persisted an unverified archive or staged tools'
    $script:DownloadFault = ''
    Write-Output 'PASS bootstrap archive cache cold/warm reuse, full test closure, fatal corruption/integrity, archive-only scope and staging cleanup'

    $script:ProcessFault = 'version'
    Assert-BootstrapFailure 'version mismatch' { Get-NativeTool -Name jsonfmt -ToolsRoot $root } 'version mismatch.*bootstrap.ps1'
    Assert-BootstrapFailure 'bootstrap existing version mismatch' { Invoke-NativeBootstrap -RepositoryRoot $checkout -SkipHook } 'version mismatch'
    $script:ProcessFault = 'exit'
    Assert-BootstrapFailure 'native exit propagation' { Get-NativeTool -Name lefthook -ToolsRoot $root } 'exited 23.*fixture native failure'
    Assert-BootstrapFailure 'bootstrap native exit propagation' { Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot (Join-Path $temp 'native exit tools') -SkipHook } 'exited 23'
    Assert-BootstrapFixture -Condition (-not (Test-Path -LiteralPath (Join-Path $temp 'native exit tools'))) -Message 'failed native version command installed tools'
    $script:ProcessFault = 'closure'
    Assert-BootstrapFailure 'plugin closure mismatch' { Get-NativeTool -Name mdformat -ToolsRoot $root } 'closure mismatch'
    $script:ProcessFault = ''

    $prettierPath = Join-Path $root 'prettier/package/bin/prettier.cjs'
    Remove-Item -LiteralPath $prettierPath
    Assert-BootstrapFailure 'missing installed artifact' { Get-NativeTool -Name prettier -ToolsRoot $root } 'Missing locked artifact.*bootstrap.ps1'
    Assert-BootstrapFailure 'bootstrap missing artifact refusal' { Invoke-NativeBootstrap -RepositoryRoot $checkout -SkipHook } 'Missing locked artifact'
    [IO.File]::WriteAllText($prettierPath, 'fixture')
    $manifestPath = Join-Path $root 'tools.json'
    $manifestBytes = [IO.File]::ReadAllBytes($manifestPath)
    $manifest.tools[0].command = 'untrusted/python.exe'
    [IO.File]::WriteAllText($manifestPath, ($manifest | ConvertTo-Json -Depth 10))
    Assert-BootstrapFailure 'manifest path injection' { Get-NativeTool -Name python -ToolsRoot $root } 'unlocked record'
    [IO.File]::WriteAllBytes($manifestPath, $manifestBytes)
    Assert-BootstrapFailure 'missing environment' { Get-NativeTool -Name ruff-format -ToolsRoot (Join-Path $temp 'absent') } 'Missing native tools.json.*bootstrap.ps1'

    $script:DownloadFault = 'hash'
    $extractions = $script:ExtractionCount
    $failedRoot = Join-Path $temp 'bad hash tools'
    Assert-BootstrapFailure 'artifact hash' { Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot $failedRoot -SkipHook } 'SHA-256 mismatch'
    Assert-BootstrapFixture -Condition ($script:ExtractionCount -eq $extractions -and -not (Test-Path -LiteralPath $failedRoot)) -Message 'bad hash reached extraction or installed tools'
    $script:DownloadFault = 'missing'
    Assert-BootstrapFailure 'missing download artifact' { Invoke-NativeBootstrap -RepositoryRoot $checkout -ToolsRoot (Join-Path $temp 'missing tools') -SkipHook } 'Missing downloaded artifact'
    $script:DownloadFault = ''

    $npm = @($script:FixtureLock.artifacts | Where-Object { $_.name -eq 'prettier' })[0]
    $npm.integrity = 'sha512-invalid'
    Assert-BootstrapFailure 'npm integrity' { Test-NativeArtifactHash -Artifact $npm -Path $fixtureArtifact } 'npm integrity mismatch'

    [IO.File]::WriteAllText($hook, "#!/bin/sh`necho unrelated`n")
    $unrelated = [IO.File]::ReadAllText($hook)
    $downloads = $script:DownloadCount
    Assert-BootstrapFailure 'unrelated hook refusal' { Invoke-NativeBootstrap -RepositoryRoot $checkout } 'Refusing to replace unrelated'
    Assert-BootstrapFixture -Condition ([IO.File]::ReadAllText($hook) -ceq $unrelated -and $script:DownloadCount -eq $downloads) -Message 'unrelated hook changed or refusal happened after downloads'
    Write-Output 'Native bootstrap fixtures passed (no real downloads, installs, hook execution or workstation changes).'
} catch { [Console]::Error.WriteLine($_.Exception.Message); exit 1 }
finally {
    $script:NativeLockPath = $originalLockPath
    $env:OS = $originalOS
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
