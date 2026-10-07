[CmdletBinding()]
param([string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent }
. (Join-Path $RepositoryRoot 'windows/dev/bootstrap.ps1') -RepositoryRoot $RepositoryRoot
. (Join-Path $RepositoryRoot 'windows/dev/formatting.ps1')
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('native formatter smoke ' + [Guid]::NewGuid().ToString('N'))
try {
    $null = New-Item -ItemType Directory -Path $fixture
    $null = New-Item -ItemType Directory -Path (Join-Path $fixture 'dns')
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'formatting.json') -Destination $fixture
    & git -C $fixture init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Cannot initialize isolated native Git fixture' }
    $files = @{
        'space name.py' = "value= 1`n"
        'frontmatter.md' = "---`nname: fixture`n---`n`n| A | B |`n| - | - |`n| x | y |`n"
        'data.json' = '{"key":1}'
        'configuration.winget' = '{"resources":[]}'
        'workflow.yml' = "name: fixture`n`njobs: {}`n"
        'dns/dnsconfig.js' = 'const value={key:1};'
    }
    foreach ($entry in $files.GetEnumerator()) { [IO.File]::WriteAllText((Join-Path $fixture $entry.Key), $entry.Value, (New-Object Text.UTF8Encoding($false))) }
    $tools = Get-NativeToolsRoot $fixture
    Invoke-NativeBootstrap -RepositoryRoot $fixture -ToolsRoot $tools -SkipHook -IncludeTestDependencies
    Invoke-NativeBootstrap -RepositoryRoot $fixture -ToolsRoot $tools -SkipHook -IncludeTestDependencies
    Invoke-NativeFormatting -RepositoryRoot $fixture -ToolsRoot $tools -Paths @($files.Keys)
    Invoke-NativeFormatting -RepositoryRoot $fixture -ToolsRoot $tools -Paths @($files.Keys) -Check
    $markdown = [IO.File]::ReadAllText((Join-Path $fixture 'frontmatter.md'))
    if ($markdown -notmatch '^---\r?\nname: fixture\r?\n---' -or $markdown -notmatch '\| A\s+\| B\s+\|') { throw 'Native mdformat lost frontmatter/GFM table fixture' }
    $dev = Join-Path $fixture 'windows/dev'
    $null = New-Item -ItemType Directory -Path $dev -Force
    foreach ($name in @('tools.ps1', 'dependencies.lock.json', 'hook.ps1', 'formatting.ps1')) {
        Copy-Item -LiteralPath (Join-Path $RepositoryRoot ('windows/dev/' + $name)) -Destination $dev
    }
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'lefthook.yml') -Destination $fixture
    # Only the invariant process is doubled in this isolated Git fixture. Its
    # real document/AST fixtures are exercised separately by windows/check.ps1.
    [IO.File]::WriteAllText((Join-Path $fixture 'windows/check.ps1'), '[IO.File]::WriteAllText((Join-Path $PSScriptRoot "invariant-called"), "fixture"); exit 0')
    Invoke-NativeBootstrap -RepositoryRoot $fixture -IncludeTestDependencies
    & git -C $fixture add --all
    if ($LASTEXITCODE -ne 0) { throw 'Cannot stage native smoke fixture' }
    & git -C $fixture -c user.name=Fixture -c user.email=fixture@example.invalid commit --quiet -m fixture
    if ($LASTEXITCODE -ne 0) { throw 'Native Git commit outside bootstrap failed' }
    if (-not (Test-Path -LiteralPath (Join-Path $fixture 'windows/invariant-called'))) { throw 'Native Git hook skipped the invariant process' }
    $hook = Get-NativeHookPath $fixture
    Assert-NativeHookOwnership $hook
    if (Test-Path -LiteralPath ($hook + '.old')) { throw 'lefthook replaced the pinned native launcher' }
    Invoke-NativeBootstrap -RepositoryRoot $fixture -IncludeTestDependencies
    Write-Host 'PASS real locked Windows distributions, Python closure/plugins, native-only formatting, repeat bootstrap, formatter idempotence and native Git hook outside bootstrap in isolated temporary tree'
} finally { if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force } }
