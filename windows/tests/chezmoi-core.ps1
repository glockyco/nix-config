param([string]$RepositoryRoot = (Join-Path $PSScriptRoot '../..'))
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
# Fixture applies invoke only a standalone fake engine in a disposable checkout.
# The production engine is never copied or invoked.
foreach ($command in @('chezmoi', 'git', 'ssh', 'pwsh')) {
  if (-not (Get-Command $command -CommandType Application -ErrorAction SilentlyContinue)) { throw "chezmoi-core requires native $command on PATH" }
}
function Assert-Core([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "chezmoi-core: $Message" }
}
function Write-CoreFile([string]$Path, [string]$Content) {
  $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($Path)) -Force
  [IO.File]::WriteAllText($Path, $Content, (New-Object Text.UTF8Encoding($false)))
}
function Assert-CoreSyntax([string]$Name, [string]$Content) {
  $tokens = $null; $errors = $null
  $null = [Management.Automation.Language.Parser]::ParseInput($Content, [ref]$tokens, [ref]$errors)
  Assert-Core ($errors.Count -eq 0) ("$Name parser errors: " + (($errors | ForEach-Object { $_.Message }) -join '; '))
}
function Invoke-CoreNative([string]$Command, [string[]]$Arguments, [switch]$Failure) {
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { $output = @(& $Command @Arguments 2>&1); $code = $LASTEXITCODE }
  finally { $ErrorActionPreference = $oldPreference }
  if ($Failure) { Assert-Core ($code -ne 0) "$Command unexpectedly succeeded" }
  else { Assert-Core ($code -eq 0) ("$Command exited ${code}: " + ($output -join "`n")) }
  return ($output -join "`n")
}
$engineInputs = @('windows/workstation.json', 'windows/workstation.schema.json', 'windows/Workstation.psm1', 'windows/Workstation.Settings.ps1', 'windows/Workstation.Delivery.ps1', 'windows/Workstation.Validation.ps1', 'windows/workstation.ps1', 'windows/managed-applications.json', 'windows/npm/package.json', 'windows/npm/package-lock.json')
$fakeEngine = @'
param([switch]$Apply)
$ErrorActionPreference = 'Stop'
if (-not $Apply -or $args.Count -ne 0) { throw 'The hook must request only -Apply' }
if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) { throw 'The hook must use PowerShell 7' }
if ($env:CORE_REQUIRE_BEFORE -eq '1' -and (Test-Path -LiteralPath $env:CORE_AFTER_FILE)) { exit 31 }
[IO.File]::AppendAllText($env:CORE_ENGINE_LOG, "$PSCommandPath|-Apply`n")
exit ([int]$env:CORE_ENGINE_EXIT)
'@
function Initialize-CoreEngine([string]$Root) {
  foreach ($relative in $engineInputs) {
    $content = if ($relative -ceq 'windows/workstation.ps1') { $fakeEngine } else { "fixture-only input: $relative`n" }
    Write-CoreFile (Join-Path $Root $relative) $content
  }
}
& (Join-Path $PSScriptRoot 'checkout-regressions.ps1') -RepositoryRoot $RepositoryRoot
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('chezmoi core ' + [guid]::NewGuid().ToString('N'))
$checkout = Join-Path $fixtureRoot 'native checkout with spaces'
$target = Join-Path $fixtureRoot 'isolated profile'
$config = Join-Path $fixtureRoot 'init.toml'
$state = Join-Path $fixtureRoot 'chezmoi-state.boltdb'
$saved = @{}
$variables = @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'GIT_CONFIG_GLOBAL', 'GIT_CONFIG_SYSTEM', 'GIT_CONFIG_NOSYSTEM', 'GIT_CONFIG_COUNT', 'GH_CONFIG_DIR', 'CORE_ENGINE_LOG', 'CORE_ENGINE_EXIT', 'CORE_AFTER_FILE', 'CORE_REQUIRE_BEFORE')
foreach ($name in $variables) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
  $null = New-Item -ItemType Directory -Path $checkout, $target -Force
  Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'home') -Destination $checkout -Recurse
  Write-CoreFile (Join-Path $checkout '.chezmoiroot') "home`n"
  Initialize-CoreEngine $checkout
  $null = Invoke-CoreNative git @('init', '-q', $checkout)
  foreach ($name in @('HOME', 'USERPROFILE')) { [Environment]::SetEnvironmentVariable($name, $target, 'Process') }
  foreach ($pair in @(@('APPDATA', 'AppData/Roaming'), @('LOCALAPPDATA', 'AppData/Local'), @('XDG_CONFIG_HOME', '.config'), @('XDG_CACHE_HOME', '.cache'), @('XDG_STATE_HOME', '.local/state'))) {
    $directory = Join-Path $target $pair[1]
    $null = New-Item -ItemType Directory -Path $directory -Force
    [Environment]::SetEnvironmentVariable($pair[0], $directory, 'Process')
  }
  $env:GIT_CONFIG_GLOBAL = Join-Path $target '.gitconfig'
  [Environment]::SetEnvironmentVariable('GIT_CONFIG_NOSYSTEM', $null, 'Process')
  $env:GIT_CONFIG_SYSTEM = Join-Path $fixtureRoot 'system.gitconfig'
  Write-CoreFile $env:GIT_CONFIG_SYSTEM "[core]`n  autocrlf = true`n[credential]`n  helper = fixture-system-helper`n"
  $env:GIT_CONFIG_COUNT = '0'
  $env:GH_CONFIG_DIR = Join-Path $target 'AppData/Roaming/GitHub CLI'
  $override = @{ chezmoi = @{ os = 'windows'; homeDir = $target } }
  function Invoke-CoreChezmoi {
    param([string[]]$Arguments, [hashtable]$OverrideData = $override, [switch]$Failure)
    $overridePath = Join-Path $fixtureRoot 'override-data.json'
    Write-CoreFile $overridePath ($OverrideData | ConvertTo-Json -Depth 30 -Compress)
    $base = @('--no-tty', '--force', '--refresh-externals=never', '--source', $checkout, '--destination', $target, '--config', $config, '--persistent-state', $state, '--override-data-file', $overridePath)
    Invoke-CoreNative chezmoi ($base + $Arguments) -Failure:$Failure
  }
  function Initialize-CoreConfig {
    $null = Invoke-CoreChezmoi @('init', '--promptString', 'host=korolev')
  }
  Initialize-CoreConfig
  $persisted = Invoke-CoreChezmoi @('dump-config', '--format=json') | ConvertFrom-Json
  Assert-Core ($persisted.sourceDir.Replace('\', '/') -eq $checkout.Replace('\', '/')) 'init must persist the native checkout, not home/ or a second clone'
  Assert-Core ($persisted.data.host -eq 'korolev') 'init must persist host=korolev'
  Assert-Core ($persisted.interpreters.ps1.command -ceq 'pwsh') 'Windows init must explicitly use PowerShell 7'
  Assert-Core (($persisted.interpreters.ps1.args -join '|') -ceq '-NoLogo|-NoProfile|-NonInteractive|-File') 'Windows init must persist unattended PowerShell 7 arguments'
  $initText = [IO.File]::ReadAllText($config)
  Assert-Core ($initText -notmatch 'recipient|identity|encryption|useBuiltinAge') 'native init must not select Mac age or secret identity'
  Initialize-CoreConfig
  $facts = Invoke-CoreChezmoi @('data', '--format=json') | ConvertFrom-Json
  $platformFixture = @{ home = $target; checkout = $checkout; ghqRoot = ((Join-Path $target 'src').Replace('\', '/')) }
  $override.hosts = @{ korolev = @{ platforms = @{ windows = $platformFixture } } }
  $coreTargets = @('.gitconfig', '.config/git/github.gitconfig', '.config/delta/catppuccin.gitconfig', 'AppData/Roaming/GitHub CLI/config.yml', '.ssh/config', '.ssh/desktop-known-hosts', '.ssh/macbook-pro-known-hosts')
  # Targeted apply canonicalizes its explicit paths before creating entries;
  # unlike a full apply, it therefore needs disposable parent directories.
  foreach ($relative in $coreTargets) {
    $parentDirectory = [IO.Path]::GetDirectoryName((Join-Path $target $relative))
    $null = New-Item -ItemType Directory -Path $parentDirectory -Force
  }
  $null = Invoke-CoreChezmoi (@('apply', '--exclude=scripts') + @($coreTargets | ForEach-Object { Join-Path $target $_ }))
  $managed = @(((Invoke-CoreChezmoi @('managed', '--path-style=relative')) -split "`r?`n") | ForEach-Object { $_.Replace('\', '/') })
  foreach ($forbidden in @('.ssh/builder-known-hosts', '.zshenv', '.zshrc')) { Assert-Core ($forbidden -notin $managed) "Windows unexpectedly manages $forbidden" }
  Assert-Core (-not (@($managed | Where-Object { $_ -match 'credentials|hosts\.yml|\.omp|Library/' }).Count)) 'native source must not manage Mac secrets or authentication/runtime state'
  $ghConfig = [IO.File]::ReadAllText((Join-Path $target 'AppData/Roaming/GitHub CLI/config.yml'))
  Assert-Core ($ghConfig -match '(?m)^git_protocol: https\r?$' -and $ghConfig -notmatch 'oauth|token|user:') 'native gh config must select HTTPS without auth state'
  Assert-Core ($ghConfig -ceq "version: `"1`"`ngit_protocol: https`neditor: `"`"`naliases: {}`n") 'native gh config must match gh serialization without an extra blank line'
  function Get-CoreGit([string]$Key, [string]$Directory = $target) { Invoke-CoreNative git @('-C', $Directory, 'config', '--get', $Key) }
  Assert-Core ((Get-CoreGit 'ghq.root') -eq $platformFixture.ghqRoot) 'effective native ghq root drifted'
  foreach ($hostName in @('github.com', 'gitlab.scch.at')) {
    $rewrites = Invoke-CoreNative git @('config', '--get-all', "url.https://$hostName/.insteadOf")
    Assert-Core (($rewrites -split "`r?`n" -join '|') -ceq "git@${hostName}:|ssh://git@$hostName/") "$hostName HTTPS rewrite forms drifted"
    foreach ($remote in @("git@${hostName}:owner/project.git", "ssh://git@$hostName/owner/project.git")) {
      $resolved = Invoke-CoreNative git @('ls-remote', '--get-url', $remote)
      Assert-Core ($resolved -ceq "https://$hostName/owner/project.git") "$remote must resolve over HTTPS"
    }
  }
  $helper = Invoke-CoreNative git @('config', '--get-all', 'credential.helper')
  $expectedHelper = '!"' + $target.Replace('\', '/') + '/AppData/Local/Programs/Git/mingw64/bin/git-credential-manager.exe"'
  $helperValues = @($helper -split "`r?`n")
  Assert-Core ($helperValues.Count -eq 3 -and $helperValues[0] -eq 'fixture-system-helper' -and $helperValues[1] -eq '' -and $helperValues[2] -eq $expectedHelper) 'native GCM must reset the system helper and quote its one absolute executable, including spaces'
  foreach ($entry in @(@('src/github.com/any owner/project', '11704293+glockyco@users.noreply.github.com'), @('src/gitlab.scch.at/work project', 'johann.glock@scch.at'), @('outside/work project', 'johann.glock@scch.at'))) {
    $repository = Join-Path $target $entry[0]
    $null = New-Item -ItemType Directory -Path $repository -Force
    $null = Invoke-CoreNative git @('init', '-q', $repository)
    Assert-Core ((Get-CoreGit 'user.email' $repository) -eq $entry[1]) "effective identity in $($entry[0]) drifted"
    $null = Invoke-CoreNative git @('-C', $repository, 'config', 'user.email', 'fixture-local@example.invalid')
    Assert-Core ((Get-CoreGit 'user.email' $repository) -eq 'fixture-local@example.invalid') 'local Git email must override both global and GitHub include'
  }
  $sshPath = Join-Path $target '.ssh/config'
  $sshText = [IO.File]::ReadAllText($sshPath)
  Assert-Core ($sshText -notmatch '(?im)^\s*Control(Master|Path|Persist)\s|/root/|builder-key|IdentityAgent|UseKeychain') 'Windows SSH must omit unsupported multiplexing, Mac agent and root builder identity'
  foreach ($endpoint in @('desktop', 'desktop-batch', 'macbook-pro', 'macbook-pro-batch')) {
    $effective = @{}
    foreach ($line in ((Invoke-CoreNative ssh @('-G', '-F', $sshPath, $endpoint)) -split "`r?`n")) {
      if ($line -match '^(\S+) (.*)$') { $effective[$matches[1]] = $matches[2] }
    }
    $isDesktop = $endpoint.StartsWith('desktop')
    $isBatch = $endpoint.EndsWith('-batch')
    foreach ($key in @('passwordauthentication', 'kbdinteractiveauthentication')) { Assert-Core ($effective[$key] -eq 'no') "$endpoint must disable $key" }
    Assert-Core ($effective.stricthostkeychecking -in @('yes', 'true')) "$endpoint must strictly check host pins"
    Assert-Core ($effective.identitiesonly -eq 'yes' -and $effective.identityfile -match '[/\\]\.ssh[/\\]id_ed25519$') "$endpoint must select only the external user key"
    $pin = if ($isDesktop) { 'desktop-known-hosts' } else { 'macbook-pro-known-hosts' }
    Assert-Core ($effective.userknownhostsfile.Contains($pin) -and $effective.globalknownhostsfile -eq 'NUL') "$endpoint must use only its managed native pin file"
    Assert-Core ($effective.updatehostkeys -in @('no', 'false')) "$endpoint must not auto-update managed pins"
    if ($isBatch) {
      if ($effective.ContainsKey('stdinnull')) { Assert-Core ($effective.stdinnull -eq 'no') "$endpoint must retain stdin" }
    }
    foreach ($key in @('controlmaster', 'controlpersist')) {
      if ($effective.ContainsKey($key)) { Assert-Core ($effective[$key] -in @('false', 'no', '0')) "$endpoint must not enable multiplexing/persistence" }
    }
  }
  foreach ($entry in @(@('desktop', $facts.ssh.desktop.publicKey), @('macbook-pro', $facts.ssh.hostKeys.'macbook-pro'.publicKey))) {
    $pinText = [IO.File]::ReadAllText((Join-Path $target ('.ssh/' + $entry[0] + '-known-hosts'))).Trim()
    Assert-Core ($pinText -eq ($entry[0] + ',' + $entry[0] + '.tail8768af.ts.net ' + $entry[1])) "managed $($entry[0]) pin drifted"
  }
  foreach ($template in @(Get-ChildItem -LiteralPath (Join-Path $checkout 'home') -Filter '*.ps1.tmpl' -File -Recurse)) {
    if ($template.FullName -match '[/\\]\.chezmoitemplates[/\\]') { continue }
    $rendered = Invoke-CoreChezmoi @('execute-template', '--file', $template.FullName)
    Assert-CoreSyntax $template.Name $rendered
  }
  $env:CORE_ENGINE_LOG = Join-Path $fixtureRoot 'engine-calls.log'
  $env:CORE_ENGINE_EXIT = '0'
  $env:CORE_REQUIRE_BEFORE = '0'
  $env:CORE_AFTER_FILE = Join-Path $target '.fixture-after'
  function Get-CoreEngineCallCount {
    if (-not (Test-Path -LiteralPath $env:CORE_ENGINE_LOG)) { return 0 }
    return [IO.File]::ReadAllLines($env:CORE_ENGINE_LOG).Count
  }
  $engineTemplate = Join-Path $checkout 'home/run_onchange_before_windows-00-workstation.ps1.tmpl'
  $engineScript = Invoke-CoreChezmoi @('execute-template', '--file', $engineTemplate)
  & ([scriptblock]::Create($engineScript))
  Assert-Core ((Get-CoreEngineCallCount) -eq 1) 'valid native root should invoke the fake engine exactly once'
  Assert-Core ([IO.File]::ReadAllLines($env:CORE_ENGINE_LOG)[0].Replace('\', '/') -ceq ((Join-Path $checkout 'windows/workstation.ps1').Replace('\', '/') + '|-Apply')) 'pwsh must receive the checkout entrypoint as one argument, including spaces'
  $env:CORE_ENGINE_EXIT = '23'
  $caught = $false
  try { & ([scriptblock]::Create($engineScript)) } catch { $caught = $_.Exception.Message -match 'exit code 23' }
  Assert-Core ($caught -and (Get-CoreEngineCallCount) -eq 2) 'engine native exit 23 must be a terminating apply failure'
  $env:CORE_ENGINE_EXIT = '0'
  $beforeRejection = Get-CoreEngineCallCount
  Write-CoreFile (Join-Path $checkout '.chezmoiroot') "wrong`n"
  $caught = $false
  try { & ([scriptblock]::Create($engineScript)) } catch { $caught = $_.Exception.Message -match 'chezmoiroot' }
  Assert-Core ($caught -and (Get-CoreEngineCallCount) -eq $beforeRejection) 'wrong .chezmoiroot must fail before invoking the engine'
  Write-CoreFile (Join-Path $checkout '.chezmoiroot') "home`n"
  $platformFixture.checkout = Join-Path $fixtureRoot 'wrong checkout'
  $wrongRootScript = Invoke-CoreChezmoi @('execute-template', '--file', $engineTemplate)
  $caught = $false
  try { & ([scriptblock]::Create($wrongRootScript)) } catch { $caught = $_.Exception.Message -match 'checkout root disagrees' }
  Assert-Core ($caught -and (Get-CoreEngineCallCount) -eq $beforeRejection) 'persisted platform checkout mismatch must fail before the engine'
  $platformFixture.checkout = $checkout
  $otherSource = Join-Path $checkout 'other source'
  $null = New-Item -ItemType Directory -Path $otherSource -Force
  # chezmoi reports sourceDir with forward slashes, which the template's dir function requires.
  $override.chezmoi.sourceDir = $otherSource.Replace('\', '/')
  $wrongSourceScript = Invoke-CoreChezmoi @('execute-template', '--file', $engineTemplate)
  $override.chezmoi.Remove('sourceDir')
  $caught = $false
  try { & ([scriptblock]::Create($wrongSourceScript)) } catch { $caught = $_.Exception.Message -match 'Effective chezmoi source directory disagrees' }
  Assert-Core ($caught -and (Get-CoreEngineCallCount) -eq $beforeRejection) 'effective source mismatch must fail before the engine'
  foreach ($relative in $engineInputs) {
    $path = Join-Path $checkout $relative
    $original = [IO.File]::ReadAllText($path)
    Write-CoreFile $path ($original + "`n")
    $caught = $false
    try { & ([scriptblock]::Create($engineScript)) } catch { $caught = $_.Exception.Message -match 'changed after rendering' }
    Assert-Core ($caught -and (Get-CoreEngineCallCount) -eq $beforeRejection) "$relative drift must fail before the engine"
    $changedScript = Invoke-CoreChezmoi @('execute-template', '--file', $engineTemplate)
    Assert-Core ($changedScript -cne $engineScript) "$relative must invalidate rendered run_onchange content"
    Remove-Item -LiteralPath $path
    $caught = $false
    try { & ([scriptblock]::Create($engineScript)) } catch { $caught = $_.Exception.Message -match 'source is missing' }
    Assert-Core ($caught -and (Get-CoreEngineCallCount) -eq $beforeRejection) "$relative absence must fail before the engine"
    Write-CoreFile $path $original
  }
  # Real chezmoi owns run_onchange state and before-file ordering. Only the fake
  # standalone engine and one harmless managed file exist in this second source.
  $checkout = Join-Path $fixtureRoot 'onchange checkout with spaces'
  $target = Join-Path $fixtureRoot 'onchange profile'
  $config = Join-Path $fixtureRoot 'onchange.toml'
  $state = Join-Path $fixtureRoot 'onchange-state.boltdb'
  $platformFixture.checkout = $checkout
  $null = New-Item -ItemType Directory -Path (Join-Path $checkout 'home/.chezmoidata'), $target -Force
  foreach ($relative in @('.chezmoidata/hosts.toml', '.chezmoidata/credentials.toml', '.chezmoi.toml.tmpl', 'run_onchange_before_windows-00-workstation.ps1.tmpl')) {
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot ('home/' + $relative)) -Destination (Join-Path $checkout ('home/' + $relative))
  }
  Write-CoreFile (Join-Path $checkout '.chezmoiroot') "home`n"
  Initialize-CoreEngine $checkout
  Write-CoreFile (Join-Path $checkout 'home/dot_fixture-after') "engine-before-file`n"
  $null = Invoke-CoreNative git @('init', '-q', $checkout)
  Initialize-CoreConfig
  $onchangeConfig = Invoke-CoreChezmoi @('dump-config', '--format=json') | ConvertFrom-Json
  Assert-Core ($onchangeConfig.interpreters.ps1.command -ceq 'pwsh') 'onchange fixture must use the persisted PowerShell 7 host'
  $env:CORE_ENGINE_LOG = Join-Path $fixtureRoot 'onchange-engine-calls.log'
  $env:CORE_AFTER_FILE = Join-Path $target '.fixture-after'
  $env:CORE_REQUIRE_BEFORE = '1'
  $null = Invoke-CoreChezmoi @('apply')
  Assert-Core ((Test-Path -LiteralPath $env:CORE_AFTER_FILE) -and (Get-CoreEngineCallCount) -eq 1) 'hashed before script must execute the engine before managed files'
  $env:CORE_REQUIRE_BEFORE = '0'
  $null = Invoke-CoreChezmoi @('apply')
  Assert-Core ((Get-CoreEngineCallCount) -eq 1) 'unchanged apply must not rerun the engine'
  $null = Invoke-CoreChezmoi @('verify')
  $dataPath = Join-Path $checkout 'windows/workstation.json'
  Write-CoreFile $dataPath ([IO.File]::ReadAllText($dataPath) + "`n")
  $env:CORE_ENGINE_EXIT = '23'
  $failedApply = Invoke-CoreChezmoi @('apply') -Failure
  Assert-Core ($failedApply -match 'exit code 23' -and (Get-CoreEngineCallCount) -eq 2) 'failed engine exit must fail real chezmoi apply with its code'
  $env:CORE_ENGINE_EXIT = '0'
  $null = Invoke-CoreChezmoi @('apply')
  Assert-Core ((Get-CoreEngineCallCount) -eq 3) 'failed onchange state must not be recorded as successful'
  $null = Invoke-CoreChezmoi @('apply')
  Assert-Core ((Get-CoreEngineCallCount) -eq 3) 'unchanged successful engine inputs must not rerun after recovery'
  Write-Output 'chezmoi-core: native init, effective Git/GCM, SSH pins/options, script AST and hashed engine/order/failure fixtures passed'
} finally {
  foreach ($name in $variables) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
  if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}
