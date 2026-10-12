[CmdletBinding()]
param([string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent }
. (Join-Path $RepositoryRoot 'windows/dev/hook.ps1') -RepositoryRoot $RepositoryRoot
function Assert-Fixture { param([bool]$Condition, [string]$Message) if (-not $Condition) { throw $Message } }
function Expect-Failure {
    param([scriptblock]$Action, [string]$Pattern, [string]$Name)
    $message = ''
    try { & $Action } catch { $message = $_.Exception.Message }
    Assert-Fixture ($message -match $Pattern) "$Name did not fail as expected: $message"
    Write-Host "PASS $Name"
}
$work = Join-Path ([IO.Path]::GetTempPath()) ('native-hook fixture ' + [Guid]::NewGuid().ToString('N'))
$hostExecutable = (Get-Process -Id $PID).Path
$originalLookup = ${function:Get-NativeTool}
try {
    New-Item -ItemType Directory -Path $work | Out-Null
    & git -C $work init --quiet
    if ($LASTEXITCODE -ne 0) { throw 'Cannot initialize fixture checkout' }
    [IO.File]::WriteAllText((Join-Path $work 'space name.md'), 'good')
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'formatting.json') -Destination $work
    & git -C $work add -- 'space name.md'
    if ($LASTEXITCODE -ne 0) { throw 'Cannot stage fixture' }
    $paths = @(Get-GitFormattingPaths -RepositoryRoot $work -Staged)
    Assert-Fixture ($paths.Count -eq 1 -and $paths[0] -ceq 'space name.md') 'Staged path with spaces was corrupted'
    $format = { param($root, $tools, $files) Invoke-NativeFormatting -RepositoryRoot $root -ToolsRoot $tools -Paths $files -Check }
    $noWindows = { param($root) $script:windowsCalled = $true }
    Expect-Failure { Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot (Join-Path $work 'missing-tools') -FormatGate $format -WindowsGate $noWindows } 'bootstrap|environment|missing' 'missing pinned tools'
    $mock = Join-Path $work 'mock formatter.ps1'
    [IO.File]::WriteAllText($mock, 'param([string]$Path); if ([IO.File]::ReadAllText($Path) -eq "bad") { [IO.File]::WriteAllText($Path, "good") }; exit 0')
    function Get-NativeTool { param($Name, $ToolsRoot) [pscustomobject]@{ command = $hostExecutable; prefixArguments = @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $mock) } }
    $script:windowsCalled = $false
    Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot $work -FormatGate $format -WindowsGate $noWindows
    Assert-Fixture $script:windowsCalled 'Native invariant gate did not run'
    Write-Host 'PASS native-only staged commit (no Nix)'
    # Keep both real default gates. Double their checkers only in this disposable
    # checkout to cover fresh host isolation, argument forwarding and exit codes.
    $windowsRoot = Join-Path $work 'windows'
    New-Item -ItemType Directory -Path $windowsRoot | Out-Null
    [IO.File]::WriteAllText((Join-Path $windowsRoot 'check-workstation.ps1'), @'
param([switch]$StaticOnly)
$ErrorActionPreference = 'Stop'
$optional = ([PSCustomObject]@{}).application
$helper = Get-Command Invoke-NativeProcess -CommandType Function -ErrorAction SilentlyContinue
$invocation = @{ staticOnly = $StaticOnly.IsPresent; processId = $PID; hostMajor = $PSVersionTable.PSVersion.Major; leakedHelper = [bool]$helper }
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'engine-invocation.json'), ($invocation | ConvertTo-Json))
if (Test-Path -LiteralPath (Join-Path $PSScriptRoot 'engine-fail.txt')) { exit 24 }
exit 0
'@)
    Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot $work -FormatGate $format
    $engineInvocation = Get-Content -LiteralPath (Join-Path $windowsRoot 'engine-invocation.json') -Raw | ConvertFrom-Json
    Assert-Fixture $engineInvocation.staticOnly 'Default engine gate did not forward -StaticOnly'
    Assert-Fixture ($engineInvocation.processId -ne $PID -and $engineInvocation.hostMajor -ge 7 -and -not $engineInvocation.leakedHelper) 'Default engine gate did not isolate its PowerShell 7 host'
    Write-Host 'PASS default engine static gate isolates host scope and forwards -StaticOnly'
    [IO.File]::WriteAllText((Join-Path $windowsRoot 'engine-fail.txt'), 'fail')
    Expect-Failure { Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot $work -FormatGate $format } 'Workstation static gate failed \(exit 24\)' 'default engine static gate failure propagation'
    Remove-Item -LiteralPath (Join-Path $windowsRoot 'engine-fail.txt')
    [IO.File]::WriteAllText((Join-Path $work 'space name.md'), 'bad')
    Expect-Failure { Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot $work -FormatGate $format -WindowsGate $noWindows } 'Unformatted native' 'unformatted native rejection'
    [IO.File]::WriteAllText((Join-Path $work 'space name.md'), 'good')
    [IO.File]::WriteAllText((Join-Path $work 'fixture.nix'), '{}')
    & git -C $work add -- fixture.nix
    if ($LASTEXITCODE -ne 0) { throw 'Cannot stage Nix fixture' }
    $script:windowsCalled = $false
    $notice = @(Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot $work -FormatGate $format -WindowsGate $noWindows 6>&1) -join "`n"
    Assert-Fixture ($notice -match 'fixture\.nix' -and $notice -match 'CI') 'Staged Nix files were not named as checked by CI'
    Assert-Fixture $script:windowsCalled 'Native invariant gate did not run beside staged Nix'
    Write-Host 'PASS staged Nix named as checked by CI'
} finally {
    ${function:Get-NativeTool} = $originalLookup
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
}
Write-Host 'PASS native hook fixtures'
