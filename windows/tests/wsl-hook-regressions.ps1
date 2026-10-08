[CmdletBinding()]
param([string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
if (-not $RepositoryRoot) { $RepositoryRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent }
. (Join-Path $RepositoryRoot 'windows/dev/hook.ps1') -RepositoryRoot $RepositoryRoot
if ((ConvertTo-NativeArgument '--distribution') -cne '--distribution') { throw 'WSL options must not be quoted into Linux command tokens' }
if ((ConvertTo-NativeArgument 'checkout with spaces') -cne '"checkout with spaces"') { throw 'Native argument quoting must preserve checkout spaces' }
if ((ConvertTo-NativeArgument '') -cne '""') { throw 'Native argument quoting must preserve empty values' }
function Assert-WslFixture {
    param([bool]$Condition, [string]$Message)
    if (-not $Condition) { throw $Message }
}
function Expect-WslFailure {
    param([scriptblock]$Action, [string]$Pattern)
    $message = ''
    try { & $Action } catch { $message = $_.Exception.Message }
    Assert-WslFixture ($message -match $Pattern) "Expected $Pattern, received: $message"
}
$work = Join-Path ([IO.Path]::GetTempPath()) ('wsl hook checkout with spaces ' + [Guid]::NewGuid().ToString('N'))
$oldDistribution = $env:NIX_CONFIG_WSL_DISTRIBUTION
try {
    New-Item -ItemType Directory -Path $work | Out-Null
    $env:NIX_CONFIG_WSL_DISTRIBUTION = 'fixture NixOS'
    $script:linuxRoot = '/mnt/c/fixture checkout with spaces'
    $script:conversionCode = 0
    $script:gateCode = 0
    $script:gateCalls = 0
    function Get-Command {
        param($Name, $CommandType, $ErrorAction)
        # Native PATH can expose both System32 WSL and the WindowsApps alias.
        [pscustomobject]@{ Source = 'fixture-wsl.exe' }
        [pscustomobject]@{ Source = 'fixture-windowsapps-wsl.exe' }
    }
    function Invoke-CapturedProcess {
        param($Command, $Arguments, $WorkingDirectory)
        Assert-WslFixture ($Command -ceq 'fixture-wsl.exe') 'Transport did not use resolved WSL executable'
        Assert-WslFixture ($WorkingDirectory -ceq $work) 'Transport lost native checkout working directory'
        Assert-WslFixture ($Arguments[0] -ceq '--distribution' -and $Arguments[1] -ceq 'fixture NixOS') 'Transport lost selected distribution'
        # Model --exec with no bare bash/wslpath on its fixed FHS PATH. This
        # double deliberately rejects the pre-fix transport, rather than
        # reporting success for commands the real host cannot resolve.
        if ($Arguments -contains 'bash' -or $Arguments -contains 'wslpath') {
            return [pscustomobject]@{ code = 127; output = ''; error = 'Bare command unavailable in WSL exec PATH' }
        }
        if ($Arguments[2] -ceq '--exec') {
            Assert-WslFixture ($Arguments.Count -eq 7 -and $Arguments[3] -ceq '/bin/wslpath' -and $Arguments[4] -ceq '-a' -and $Arguments[5] -ceq '-u' -and $Arguments[6] -ceq $work) 'Path conversion arguments changed'
            return [pscustomobject]@{ code = $script:conversionCode; output = $script:linuxRoot + "`r`n"; error = 'fixture conversion failure' }
        }
        Assert-WslFixture ($Arguments.Count -eq 10 -and $Arguments[2] -ceq '--cd' -and $Arguments[3] -ceq $script:linuxRoot -and $Arguments[4] -ceq '--exec' -and $Arguments[5] -ceq '/run/current-system/sw/bin/bash') 'Gate must use absolute activated host bash with exact checkout'
        Assert-WslFixture ($Arguments[6] -ceq './windows/dev/nix-gate.sh' -and $Arguments[7] -ceq $script:linuxRoot) 'Gate script/root argument changed'
        $proofPath = Join-Path $work $Arguments[8]
        Assert-WslFixture ([IO.File]::Exists($proofPath) -and [IO.File]::ReadAllText($proofPath) -ceq $Arguments[9]) 'Same-checkout proof was not supplied intact'
        $script:gateCalls++
        return [pscustomobject]@{ code = $script:gateCode; output = ''; error = 'Wrong checkout: fixture native proof does not match' }
    }
    Invoke-SameCheckoutNixGate $work
    Assert-WslFixture ($script:gateCalls -eq 1) 'Absolute WSL transport did not reach gate'
    $script:gateCode = 23
    Expect-WslFailure { Invoke-SameCheckoutNixGate $work } 'exit 23.*Wrong checkout'
    $script:conversionCode = 19
    Expect-WslFailure { Invoke-SameCheckoutNixGate $work } 'Cannot map native checkout.*exit 19'
    Assert-WslFixture ($script:gateCalls -eq 2) 'Failed conversion invoked Nix gate'
    $script:conversionCode = 0
    $script:linuxRoot = 'relative checkout'
    Expect-WslFailure { Invoke-SameCheckoutNixGate $work } 'Wrong checkout.*absolute'
    Assert-WslFixture (@(Get-ChildItem -LiteralPath $work -Filter '.native-nix-gate-*' -Force).Count -eq 0) 'Native proof leaked after success/failure'

    $gate = [IO.File]::ReadAllText((Join-Path $RepositoryRoot 'windows/dev/nix-gate.sh'))
    # Assert the environment before any external command; merely changing the
    # launcher leaves git/realpath/cat unavailable in the actual --exec host.
    Assert-WslFixture ($gate -match '(?m)^export PATH=/run/current-system/sw/bin:/bin\r?$') 'Nix gate lacks the activated host/declared WSL bridge PATH'
    Assert-WslFixture ($gate.IndexOf('export PATH=') -lt $gate.IndexOf('actual_root=$(git')) 'Nix gate initializes PATH after checkout validation'
    Assert-WslFixture ($gate -match '(?m)^host_nix=/run/current-system/sw/bin/nix\r?$') 'Nix gate replaced trusted host Nix with PATH lookup'
    Assert-WslFixture ($gate.Contains("pinned_nix=`$(`$host_nix build '.#nixosConfigurations.korolev.config.nix.package^out' --no-link --print-out-paths)")) 'Nix gate no longer resolves checkout-declared Nix with host Nix'
    Assert-WslFixture ($gate.Contains('exec "$pinned_nix/bin/nix" fmt -- --fail-on-change')) 'Nix gate no longer propagates pinned formatter status'
    Assert-WslFixture ($gate.Contains('realpath -- "$actual_root"') -and $gate.Contains('realpath -- "$expected_root"') -and $gate.Contains('cat -- "$proof_file"')) 'Nix gate lost canonical same-checkout/proof validation'
} finally {
    $env:NIX_CONFIG_WSL_DISTRIBUTION = $oldDistribution
    if (Test-Path -LiteralPath $work) { Remove-Item -LiteralPath $work -Recurse -Force }
}
Write-Host 'PASS WSL hook absolute transport, host PATH, checkout proof and failure regressions'
