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
    $neverNix = { param($root) throw 'Native-only commit unexpectedly required Nix' }
    Expect-Failure { Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot (Join-Path $work 'missing-tools') -NixGate $neverNix -FormatGate $format -WindowsGate $noWindows } 'bootstrap|environment|missing' 'missing pinned tools'
    $mock = Join-Path $work 'mock formatter.ps1'
    [IO.File]::WriteAllText($mock, 'param([string]$Path); if ([IO.File]::ReadAllText($Path) -eq "bad") { [IO.File]::WriteAllText($Path, "good") }; exit 0')
    function Get-NativeTool { param($Name, $ToolsRoot) [pscustomobject]@{ command = $hostExecutable; prefixArguments = @('-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $mock) } }
    $script:windowsCalled = $false
    Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot $work -NixGate $neverNix -FormatGate $format -WindowsGate $noWindows
    Assert-Fixture $script:windowsCalled 'Native invariant gate did not run'
    Write-Host 'PASS native-only staged commit (no Nix)'
    [IO.File]::WriteAllText((Join-Path $work 'space name.md'), 'bad')
    Expect-Failure { Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot $work -NixGate $neverNix -FormatGate $format -WindowsGate $noWindows } 'Unformatted native' 'unformatted native rejection'
    [IO.File]::WriteAllText((Join-Path $work 'fixture.nix'), '{}')
    & git -C $work add -- fixture.nix
    if ($LASTEXITCODE -ne 0) { throw 'Cannot stage Nix fixture' }
    Expect-Failure { Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot $work -NixGate { throw 'Staged .nix requires declared Nix/WSL environment' } -FormatGate $format -WindowsGate $noWindows } 'Nix/WSL' 'staged Nix without environment'
    Expect-Failure { Invoke-NativeCommitGate -RepositoryRoot $work -ToolsRoot $work -NixGate { throw 'Wrong checkout: WSL must validate exact native checkout' } -FormatGate $format -WindowsGate $noWindows } 'Wrong checkout' 'wrong checkout rejection'
    # Exercise the real WSL adapter's missing-runtime and result propagation,
    # without starting WSL or installing anything on the live host.
    function Get-Command { param($Name, $CommandType, $ErrorAction) return $null }
    Expect-Failure { Invoke-SameCheckoutNixGate $work } 'Staged .nix.*WSL' 'missing WSL diagnostic'
    function Get-Command { param($Name, $CommandType, $ErrorAction) [pscustomobject]@{ Source = 'fixture-wsl' } }
    function Invoke-CapturedProcess {
        param($Command, $Arguments, $WorkingDirectory)
        if ($Arguments -contains '/bin/wslpath') { return [pscustomobject]@{ code = 0; output = '/wrong/checkout'; error = '' } }
        [pscustomobject]@{ code = 23; output = ''; error = 'Wrong checkout: native proof file does not match' }
    }
    Expect-Failure { Invoke-SameCheckoutNixGate $work } 'exit 23.*Wrong checkout' 'WSL wrong-checkout and native exit propagation'
    Assert-Fixture (@(Get-ChildItem -LiteralPath $work -Filter '.native-nix-gate-*' -Force).Count -eq 0) 'Nix proof file leaked'
} finally {
    ${function:Get-NativeTool} = $originalLookup
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
}
& (Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) 'tests/wsl-hook-regressions.ps1') -RepositoryRoot $RepositoryRoot
Write-Host 'PASS native hook fixtures'
