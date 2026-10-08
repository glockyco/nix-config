param([string]$RepositoryRoot = (Join-Path $PSScriptRoot '../..'))
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
# Dependencies are native chezmoi, Git and OpenSSH; fixture applies call only a
# disposable winget double, never the installed package manager or user state.
foreach ($command in @('chezmoi', 'git', 'ssh')) {
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
& (Join-Path $PSScriptRoot 'checkout-regressions.ps1') -RepositoryRoot $RepositoryRoot
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('chezmoi core ' + [guid]::NewGuid().ToString('N'))
$checkout = Join-Path $fixtureRoot 'native checkout with spaces'
$target = Join-Path $fixtureRoot 'isolated profile'
$config = Join-Path $fixtureRoot 'init.toml'
$state = Join-Path $fixtureRoot 'chezmoi-state.boltdb'
$saved = @{}
$variables = @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'GIT_CONFIG_GLOBAL', 'GIT_CONFIG_SYSTEM', 'GIT_CONFIG_NOSYSTEM', 'GIT_CONFIG_COUNT', 'GH_CONFIG_DIR', 'PATH', 'PSModulePath', 'CORE_WINGET_LOG', 'CORE_WINGET_EXIT', 'CORE_AFTER_FILE', 'CORE_REQUIRE_BEFORE', 'CORE_MODULE_PATH_LOG')
foreach ($name in $variables) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
  $null = New-Item -ItemType Directory -Path $checkout, $target -Force
  Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'home') -Destination $checkout -Recurse
  Write-CoreFile (Join-Path $checkout '.chezmoiroot') "home`n"
  Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'windows/configuration.winget') -Destination (New-Item -ItemType Directory -Path (Join-Path $checkout 'windows')).FullName
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
    param([string[]]$Arguments, [hashtable]$OverrideData = $override, [switch]$Failure, [switch]$ViaPowerShell7)
    # A file avoids Windows PowerShell 5.1's lossy native JSON-argument quoting.
    $overridePath = Join-Path $fixtureRoot 'override-data.json'
    Write-CoreFile $overridePath ($OverrideData | ConvertTo-Json -Depth 30 -Compress)
    $base = @('--no-tty', '--force', '--refresh-externals=never', '--source', $checkout, '--destination', $target, '--config', $config, '--persistent-state', $state, '--override-data-file', $overridePath)
    if ($ViaPowerShell7) {
      $invocationPath = Join-Path $fixtureRoot 'PowerShell 7 chezmoi invocation.json'
      Write-CoreFile $invocationPath (@{ command = (Get-Command chezmoi -CommandType Application | Select-Object -First 1).Source; arguments = $base + $Arguments } | ConvertTo-Json -Depth 30)
      $bridge = Join-Path $fixtureRoot 'PowerShell 7 chezmoi bridge.ps1'
      Write-CoreFile $bridge @'
param([string]$InvocationPath)
$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSEdition -ne 'Core' -or $PSVersionTable.PSVersion.Major -lt 7) { throw 'The interpreter-boundary regression requires PowerShell 7' }
$invocation = [IO.File]::ReadAllText($InvocationPath) | ConvertFrom-Json
& $invocation.command @($invocation.arguments)
exit $LASTEXITCODE
'@
      Invoke-CoreNative (Get-Command pwsh -CommandType Application | Select-Object -First 1).Source @('-NoLogo', '-NoProfile', '-NonInteractive', '-ExecutionPolicy', 'Bypass', '-File', $bridge, $invocationPath) -Failure:$Failure
      return
    }
    Invoke-CoreNative chezmoi ($base + $Arguments) -Failure:$Failure
  }
  function Initialize-CoreConfig {
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
      # init ignores override-data OS, and promptStringOnce exists only in
      # init. Force Windows context in the disposable template, not production.
      $prefix = '{{- $_ := set .chezmoi "os" "windows" -}}{{- $_ := set .chezmoi "homeDir" ' + ($target | ConvertTo-Json -Compress) + ' -}}'
      Write-CoreFile (Join-Path $checkout 'home/.chezmoi.toml.tmpl') ($prefix + [IO.File]::ReadAllText((Join-Path $RepositoryRoot 'home/.chezmoi.toml.tmpl')))
    }
    $null = Invoke-CoreChezmoi @('init', '--promptString', 'host=korolev')
  }
  Initialize-CoreConfig
  $persisted = Invoke-CoreChezmoi @('dump-config', '--format=json') | ConvertFrom-Json
  Assert-Core ($persisted.sourceDir.Replace('\', '/') -eq $checkout.Replace('\', '/')) 'init must persist the native checkout, not home/ or a second clone'
  Assert-Core ($persisted.data.host -eq 'korolev') 'init must persist host=korolev'
  Assert-Core ($persisted.interpreters.ps1.command -ceq 'powershell.exe') 'Windows init must explicitly use in-box Windows PowerShell, not bootstrap-dependent pwsh'
  Assert-Core (($persisted.interpreters.ps1.args -join '|') -ceq '-NoLogo|-NoProfile|-NonInteractive|-ExecutionPolicy|Bypass|-File') 'Windows init must persist unattended Windows PowerShell arguments'
  $initText = [IO.File]::ReadAllText($config)
  Assert-Core ($initText -notmatch 'recipient|identity|encryption|useBuiltinAge') 'native init must not select Mac age or secret identity'
  Initialize-CoreConfig
  $facts = Invoke-CoreChezmoi @('data', '--format=json') | ConvertFrom-Json
  $windows = $facts.hosts.korolev.platforms.windows
  $linux = $facts.hosts.korolev.platforms.linux
  Assert-Core ($windows.home -eq 'C:\Users\jglock' -and $windows.username -eq 'jglock') 'Windows home/account facts drifted'
  Assert-Core ($windows.checkout -eq 'C:\Users\jglock\src\github.com\glockyco\nix-config') 'Windows native checkout fact drifted'
  Assert-Core ($windows.ghqRoot -eq 'C:/Users/jglock/src' -and $linux.ghqRoot -eq '/home/user/src') 'ghq roots must stay native and platform-distinct'
  Assert-Core ($windows.home -ne $linux.home -and $windows.checkout -ne $linux.checkout) 'Windows paths must not be inferred from Linux'
  Assert-Core ($windows.ternDirectory -eq 'AppData/Local/Programs/Tern') 'Tern must use the stable native directory'
  Assert-Core ($windows.gcmHelper -eq 'mingw64/bin/git-credential-manager.exe') 'reviewed installed GCM helper must remain one explicit path'
  $productionGit = Invoke-CoreChezmoi @('execute-template', '--file', (Join-Path $checkout 'home/dot_gitconfig.tmpl'))
  Assert-Core ($productionGit.Contains('C:/Users/jglock/src')) 'native ghq root must render from platform facts'
  Assert-Core ($productionGit -notmatch '/Users/glockyco|/home/user|credentialStore|gh auth git-credential') 'Windows Git must use native GCM, not Mac/Linux auth'
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
  function Get-CoreGit([string]$Key, [string]$Directory = $target) { Invoke-CoreNative git @('-C', $Directory, 'config', '--get', $Key) }
  foreach ($entry in @(@('init.defaultBranch', 'main'), @('pull.rebase', 'true'), @('push.autoSetupRemote', 'true'), @('core.autocrlf', 'input'), @('core.pager', 'delta'), @('interactive.diffFilter', 'delta --color-only'), @('filter.lfs.required', 'true'), @('filter.lfs.process', 'git-lfs filter-process'), @('credential.https://git.overleaf.com.provider', 'generic'))) {
    Assert-Core ((Get-CoreGit $entry[0]) -eq $entry[1]) "effective Git $($entry[0]) drifted"
  }
  Assert-Core ((Get-CoreGit 'ghq.root') -eq $platformFixture.ghqRoot) 'effective native ghq root drifted'
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
  # The >=2.56 layout is an explicit reviewed fact change, never a helper chain.
  $platformFixture.gcmHelper = 'ucrt64/bin/git-credential-manager.exe'
  $transition = Invoke-CoreChezmoi @('execute-template', '--file', (Join-Path $checkout 'home/dot_gitconfig.tmpl'))
  Assert-Core ($transition.Contains('/ucrt64/bin/git-credential-manager.exe') -and -not $transition.Contains('/mingw64/')) 'Git >=2.56 transition must replace, not append/fallback, the helper'
  $transitionPath = Join-Path $fixtureRoot 'transition.gitconfig'
  Write-CoreFile $transitionPath $transition
  $transitionHelper = Invoke-CoreNative git @('config', '--file', $transitionPath, '--get-all', 'credential.helper')
  Assert-Core ($transitionHelper.Trim() -eq $expectedHelper.Replace('/mingw64/', '/ucrt64/')) 'effective transitioned GCM helper drifted'
  $platformFixture.Remove('gcmHelper')
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
    Assert-Core ($effective.hostname -eq $(if ($isDesktop) { 'desktop.tail8768af.ts.net' } else { 'macbook-pro.tail8768af.ts.net' })) "$endpoint hostname drifted"
    Assert-Core ($effective.user -eq $(if ($isDesktop) { 'User' } else { 'glockyco' })) "$endpoint user drifted"
    foreach ($key in @('passwordauthentication', 'kbdinteractiveauthentication')) { Assert-Core ($effective[$key] -eq 'no') "$endpoint must disable $key" }
    Assert-Core ($effective.stricthostkeychecking -in @('yes', 'true')) "$endpoint must strictly check host pins"
    Assert-Core ($effective.identitiesonly -eq 'yes' -and $effective.identityfile -match '[/\\]\.ssh[/\\]id_ed25519$') "$endpoint must select only the external user key"
    $pin = if ($isDesktop) { 'desktop-known-hosts' } else { 'macbook-pro-known-hosts' }
    Assert-Core ($effective.userknownhostsfile.Contains($pin) -and $effective.globalknownhostsfile -eq 'NUL') "$endpoint must use only its managed native pin file"
    Assert-Core ($effective.updatehostkeys -in @('no', 'false')) "$endpoint must not auto-update managed pins"
    Assert-Core ($effective.serveraliveinterval -eq '60' -and $effective.serveralivecountmax -eq '3' -and $effective.hashknownhosts -eq 'yes') "$endpoint must retain supported interactive keepalive/pin options"
    if ($isBatch) {
      Assert-Core ($effective.batchmode -eq 'yes' -and $effective.requesttty -eq 'false' -and $effective.connecttimeout -eq '8') "$endpoint batch/timeout/no-PTY behavior drifted"
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
  # Every Windows entry point must establish the shared interpreter boundary
  # before module cmdlets, including modify filters and the explicit launcher.
  $prelude = [IO.File]::ReadAllText((Join-Path $checkout 'home/.chezmoitemplates/windows-powershell-prelude.ps1'))
  $renderedEntryPoints = @{}
  foreach ($template in @(Get-ChildItem -LiteralPath (Join-Path $checkout 'home') -Filter '*.ps1.tmpl' -File -Recurse)) {
    if ($template.FullName -match '[/\\]\.chezmoitemplates[/\\]') { continue }
    $rendered = Invoke-CoreChezmoi @('execute-template', '--file', $template.FullName)
    Assert-CoreSyntax $template.Name $rendered
    $renderedEntryPoints[$template.FullName] = $rendered
  }
  $wingetTemplate = Join-Path $checkout 'home/run_onchange_before_windows-00-winget.ps1.tmpl'
  $wingetScript = Invoke-CoreChezmoi @('execute-template', '--file', $wingetTemplate)
  Assert-Core ($wingetScript -notmatch 'apply-kbdneo|apply-zen|Add-WindowsCapability|Start-Service|sshd') 'user apply must not execute Administrator or OpenSSH service operations'
  $nativeState = @{ Count = 0; ExitCode = 0 }
  function winget {
    Assert-Core ($args.Count -eq 4 -and $args[0] -eq 'configure' -and $args[1] -eq '--file' -and $args[2] -eq (Join-Path $checkout 'windows/configuration.winget') -and $args[3] -eq '--accept-configuration-agreements') 'winget must receive the real document as one argument, including spaces'
    $nativeState.Count++
    $global:LASTEXITCODE = $nativeState.ExitCode
  }
  & ([scriptblock]::Create($wingetScript))
  Assert-Core ($nativeState.Count -eq 1) 'valid native root should invoke WinGet exactly once'
  $nativeState.ExitCode = 23
  $caught = $false
  try { & ([scriptblock]::Create($wingetScript)) } catch { $caught = $_.Exception.Message -match 'exit code 23' }
  Assert-Core $caught 'WinGet native exit 23 must be a terminating apply failure'
  $nativeState.ExitCode = 0
  $beforeRejection = $nativeState.Count
  Write-CoreFile (Join-Path $checkout '.chezmoiroot') "wrong`n"
  $caught = $false
  try { & ([scriptblock]::Create($wingetScript)) } catch { $caught = $_.Exception.Message -match 'chezmoiroot' }
  Assert-Core ($caught -and $nativeState.Count -eq $beforeRejection) 'wrong .chezmoiroot must fail before invoking WinGet'
  Write-CoreFile (Join-Path $checkout '.chezmoiroot') "home`n"
  $platformFixture.checkout = Join-Path $fixtureRoot 'wrong checkout'
  $wrongRootScript = Invoke-CoreChezmoi @('execute-template', '--file', $wingetTemplate)
  $caught = $false
  try { & ([scriptblock]::Create($wrongRootScript)) } catch { $caught = $_.Exception.Message -match 'checkout root disagrees' }
  Assert-Core ($caught -and $nativeState.Count -eq $beforeRejection) 'persisted platform checkout mismatch must fail before WinGet'
  $platformFixture.checkout = $checkout
  $documentPath = Join-Path $checkout 'windows/configuration.winget'
  $originalDocument = [IO.File]::ReadAllText($documentPath)
  Write-CoreFile $documentPath ($originalDocument + "`n")
  $caught = $false
  try { & ([scriptblock]::Create($wingetScript)) } catch { $caught = $_.Exception.Message -match 'changed after rendering' }
  Assert-Core ($caught -and $nativeState.Count -eq $beforeRejection) 'hash drift after render must fail before WinGet'
  Write-CoreFile $documentPath $originalDocument
  Remove-Item Function:winget
  # Real chezmoi run_onchange state/order, with only this script and a harmless
  # file in a second fixture source. The native double records child calls.
  $checkout = Join-Path $fixtureRoot 'onchange checkout with spaces'
  $target = Join-Path $fixtureRoot 'onchange profile'
  $config = Join-Path $fixtureRoot 'onchange.toml'
  $state = Join-Path $fixtureRoot 'onchange-state.boltdb'
  $platformFixture.checkout = $checkout
  $null = New-Item -ItemType Directory -Path (Join-Path $checkout 'home/.chezmoidata'), (Join-Path $checkout 'home/.chezmoitemplates'), (Join-Path $checkout 'windows'), $target -Force
  Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'home/.chezmoidata/hosts.toml') -Destination (Join-Path $checkout 'home/.chezmoidata/hosts.toml')
  Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'home/.chezmoidata/credentials.toml') -Destination (Join-Path $checkout 'home/.chezmoidata/credentials.toml')
  Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'home/.chezmoi.toml.tmpl') -Destination (Join-Path $checkout 'home/.chezmoi.toml.tmpl')
  Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'home/run_onchange_before_windows-00-winget.ps1.tmpl') -Destination (Join-Path $checkout 'home/run_onchange_before_windows-00-winget.ps1.tmpl')
  Copy-Item -LiteralPath (Join-Path $RepositoryRoot 'home/.chezmoitemplates/windows-powershell-prelude.ps1') -Destination (Join-Path $checkout 'home/.chezmoitemplates/windows-powershell-prelude.ps1')
  Write-CoreFile (Join-Path $checkout '.chezmoiroot') "home`n"
  Write-CoreFile (Join-Path $checkout 'windows/configuration.winget') $originalDocument
  Write-CoreFile (Join-Path $checkout 'home/dot_fixture-after') "package-before-file`n"
  $null = Invoke-CoreNative git @('init', '-q', $checkout)
  $override.data = @{ checkMode = $true }
  Initialize-CoreConfig
  $onchangeConfig = Invoke-CoreChezmoi @('dump-config', '--format=json') | ConvertFrom-Json
  Assert-Core ($onchangeConfig.interpreters.ps1.command -ceq 'powershell.exe') 'onchange fixture must use the rendered Windows init interpreter'
  if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    # Linux cannot execute in-box Windows PowerShell. Adapt execution only after
    # asserting the production init above; Windows exercises it unchanged.
    $onchangeConfig.interpreters.ps1.command = (Get-Process -Id $PID).Path
    $config = Join-Path $fixtureRoot 'onchange-linux.json'
    Write-CoreFile $config ($onchangeConfig | ConvertTo-Json -Depth 30)
  }
  $bin = Join-Path $fixtureRoot 'fixture executables'
  $null = New-Item -ItemType Directory -Path $bin
  $env:CORE_WINGET_LOG = Join-Path $fixtureRoot 'winget-calls.log'
  $env:CORE_AFTER_FILE = Join-Path $target '.fixture-after'
  $env:CORE_MODULE_PATH_LOG = Join-Path $fixtureRoot 'classic-module-path.log'
  $env:CORE_REQUIRE_BEFORE = '1'
  $env:CORE_WINGET_EXIT = '0'
  if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    Write-CoreFile (Join-Path $bin 'winget.cmd') (@'
@echo off
if "%CORE_REQUIRE_BEFORE%"=="1" if exist "%CORE_AFTER_FILE%" exit /b 31
echo %*>>"%CORE_WINGET_LOG%"
echo %PSModulePath%>"%CORE_MODULE_PATH_LOG%"
exit /b %CORE_WINGET_EXIT%
'@).Replace("`n", "`r`n")
  } else {
    $double = Join-Path $bin 'winget'
    Write-CoreFile $double (@'
#!/bin/sh
if [ "$CORE_REQUIRE_BEFORE" = 1 ] && [ -e "$CORE_AFTER_FILE" ]; then exit 31; fi
printf '%s\n' "$*" >> "$CORE_WINGET_LOG"
exit "$CORE_WINGET_EXIT"
'@ + "`n")
    $null = Invoke-CoreNative chmod @('+x', $double)
  }
  $env:PATH = $bin + [IO.Path]::PathSeparator + $saved.PATH
  $viaPowerShell7 = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT -and $null -ne (Get-Command pwsh -CommandType Application -ErrorAction SilentlyContinue)
  if ($viaPowerShell7) {
    # Hosted runners also have an ambient pwsh behind the locked one. Exercise
    # that discovery shape without installing another runtime or invoking it.
    $secondaryShell = Join-Path $fixtureRoot 'second PowerShell on PATH'
    Write-CoreFile (Join-Path $secondaryShell 'pwsh.cmd') "@echo off`r`nexit /b 89`r`n"
    $env:PATH += [IO.Path]::PathSeparator + $secondaryShell
    Assert-Core (@(Get-Command pwsh -CommandType Application).Count -gt 1) 'PowerShell discovery regression must expose multiple PATH candidates'
  }
  $null = Invoke-CoreChezmoi @('apply') -ViaPowerShell7:$viaPowerShell7
  if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    $classicModules = Join-Path (Split-Path (Get-Command powershell.exe -CommandType Application | Select-Object -First 1).Source -Parent) 'Modules'
    Assert-Core ([IO.File]::ReadAllText($env:CORE_MODULE_PATH_LOG).StartsWith($classicModules + ';', [StringComparison]::OrdinalIgnoreCase)) 'chezmoi must run Classic with its own module defaults, not inherited Core module directories'
    if ($viaPowerShell7) { Write-Output 'chezmoi-core: real PowerShell 7 -> chezmoi -> Windows PowerShell module boundary passed' }
  }
  Assert-Core ((Test-Path -LiteralPath $env:CORE_AFTER_FILE) -and [IO.File]::ReadAllLines($env:CORE_WINGET_LOG).Count -eq 1) 'hashed before script must install before managed files'
  $env:CORE_REQUIRE_BEFORE = '0'
  $null = Invoke-CoreChezmoi @('apply')
  Assert-Core ([IO.File]::ReadAllLines($env:CORE_WINGET_LOG).Count -eq 1) 'unchanged apply must not rerun WinGet'
  $null = Invoke-CoreChezmoi @('verify')
  Write-CoreFile (Join-Path $checkout 'windows/configuration.winget') ($originalDocument + "`n")
  $env:CORE_WINGET_EXIT = '23'
  $failedApply = Invoke-CoreChezmoi @('apply') -Failure
  Assert-Core ($failedApply -match 'exit code 23' -and [IO.File]::ReadAllLines($env:CORE_WINGET_LOG).Count -eq 2) 'failed native exit must fail real chezmoi apply with its code'
  $env:CORE_WINGET_EXIT = '0'
  $null = Invoke-CoreChezmoi @('apply')
  Assert-Core ([IO.File]::ReadAllLines($env:CORE_WINGET_LOG).Count -eq 3) 'failed onchange state must not be recorded as successful'
  $null = Invoke-CoreChezmoi @('apply')
  Assert-Core ([IO.File]::ReadAllLines($env:CORE_WINGET_LOG).Count -eq 3) 'unchanged successful document must not rerun after recovery'
  foreach ($entryPoint in $renderedEntryPoints.Keys) {
    Assert-Core (($renderedEntryPoints[$entryPoint] -replace '\A#![^\r\n]*\r?\n', '').StartsWith($prelude)) "$entryPoint must include the shared Windows PowerShell prelude first"
  }
  Write-Output 'chezmoi-core: native init, effective Git/GCM, SSH pins/options, script AST and hashed WinGet/order/failure fixtures passed'
} finally {
  foreach ($name in $variables) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
  if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}
