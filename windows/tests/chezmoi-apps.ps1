param([Parameter(Mandatory = $true)][string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'

function Assert-Apps {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw "chezmoi-apps: $Message" }
}
function Assert-AppsFailure {
  param([scriptblock]$Action, [string]$Pattern, [string]$Context = '')
  $failure = $null; $failureStack = ''
  try { & $Action | Out-Null } catch { $failure = $_.Exception.Message; $failureStack = $_.ScriptStackTrace }
  Assert-Apps ($null -ne $failure -and $failure -match $Pattern) "$Context expected failure matching $Pattern, got $failure; stack=$failureStack"
}
function Assert-AppsAst {
  param([string]$Text, [string]$Name)
  $tokens = $null; $errors = $null
  [void][Management.Automation.Language.Parser]::ParseInput($Text, $Name, [ref]$tokens, [ref]$errors)
  Assert-Apps ($errors.Count -eq 0) "PowerShell parser $Name`: $($errors.Message -join '; ')"
}
function Write-AppsFixture {
  param([string]$Path, [string]$Text)
  [void][IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
  [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}
function Invoke-AppsChezmoi {
  param([string[]]$Arguments)
  $previousPreference = $ErrorActionPreference
  try {
    # PS5.1 wraps native stderr in ErrorRecord even when it is redirected.
    $ErrorActionPreference = 'Continue'
    $output = & $script:AppsChezmoi @Arguments 2>&1
    $nativeExit = $LASTEXITCODE
  } finally { $ErrorActionPreference = $previousPreference }
  if ($nativeExit -ne 0) { throw "chezmoi-apps: chezmoi exit $nativeExit`: $($output -join "`n")" }
  return ($output -join "`n")
}
function Render-AppsTemplate {
  param([string]$Relative)
  $inputPath = Join-Path $script:AppsTemporary 'render-input.tmpl'
  $prefix = '{{- $_ := set .chezmoi "os" "windows" -}}{{- $_ := set .chezmoi "homeDir" ' + ($script:AppsHome | ConvertTo-Json -Compress) + ' -}}'
  Write-AppsFixture $inputPath ($prefix + [IO.File]::ReadAllText((Join-Path $script:AppsSource $Relative)))
  $outputPath = Join-Path $script:AppsTemporary 'render-output'
  $null = Invoke-AppsChezmoi -Arguments @('--config', $script:AppsConfig, '--source', $script:AppsSource, '--destination', $script:AppsHome, '--persistent-state', $script:AppsState, '--cache', $script:AppsCache, '--output', $outputPath, 'execute-template', '--file', $inputPath)
  return [IO.File]::ReadAllText($outputPath)
}
function Invoke-AppsApply {
  param([string]$Command)
  return Invoke-AppsChezmoi -Arguments @('--config', $script:AppsConfig, '--source', $script:AppsRenderedSource, '--destination', $script:AppsHome, '--persistent-state', $script:AppsState, '--cache', $script:AppsCache, '--force', '--no-tty', $Command)
}

$script:AppsChezmoi = (Get-Command chezmoi -ErrorAction Stop).Source
$engine = (Get-Process -Id $PID).Path
$script:AppsTemporary = Join-Path ([IO.Path]::GetTempPath()) ('chezmoi apps ' + [Guid]::NewGuid().ToString('N'))
$script:AppsHome = Join-Path $script:AppsTemporary 'user home'
$script:AppsSource = Join-Path $RepositoryRoot 'home'
$script:AppsRenderedSource = Join-Path $script:AppsTemporary 'rendered source'
$script:AppsConfig = Join-Path $script:AppsTemporary 'init.toml'
$script:AppsState = Join-Path $script:AppsTemporary 'state.boltdb'
$script:AppsCache = Join-Path $script:AppsTemporary 'cache'
$saved = @{}
foreach ($name in @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'PSModulePath')) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
  [void][IO.Directory]::CreateDirectory($script:AppsHome)
  $env:HOME = $script:AppsHome; $env:USERPROFILE = $script:AppsHome
  $env:APPDATA = Join-Path $script:AppsHome 'AppData/Roaming'
  $env:LOCALAPPDATA = Join-Path $script:AppsHome 'AppData/Local'
  # promptStringOnce is init-only: exercise the shared template through actual
  # init in a disposable minimal checkout, not through execute-template.
  $initCheckout = Join-Path $script:AppsTemporary 'init checkout'
  Write-AppsFixture (Join-Path $initCheckout '.chezmoiroot') "home`n"
  foreach ($relative in @('.chezmoidata/hosts.toml', '.chezmoidata/credentials.toml')) {
    Write-AppsFixture (Join-Path $initCheckout ('home/' + $relative)) ([IO.File]::ReadAllText((Join-Path $script:AppsSource $relative)))
  }
  $initTemplate = [IO.File]::ReadAllText((Join-Path $script:AppsSource '.chezmoi.toml.tmpl'))
  if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    $initTemplate = '{{- $_ := set .chezmoi "os" "windows" -}}{{- $_ := set .chezmoi "homeDir" ' + ($script:AppsHome | ConvertTo-Json -Compress) + ' -}}' + $initTemplate
  }
  Write-AppsFixture (Join-Path $initCheckout 'home/.chezmoi.toml.tmpl') $initTemplate
  $null = Invoke-AppsChezmoi -Arguments @('--config', $script:AppsConfig, '--source', $initCheckout, '--destination', $script:AppsHome, '--persistent-state', $script:AppsState, '--cache', $script:AppsCache, '--no-tty', 'init', '--promptString', 'host=korolev')
  $configured = (Invoke-AppsChezmoi -Arguments @('--config', $script:AppsConfig, 'dump-config', '--format=json')) | ConvertFrom-Json
  Assert-Apps ($configured.interpreters.ps1.command -ceq 'powershell.exe') 'shared Windows init uses the in-box Windows PowerShell interpreter'
  Assert-Apps (($configured.interpreters.ps1.args -join '|') -ceq '-NoLogo|-NoProfile|-NonInteractive|-ExecutionPolicy|Bypass|-File') 'shared Windows init supplies the noninteractive script interpreter arguments'
  if ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT) {
    $engine = (Get-Command $configured.interpreters.ps1.command -ErrorAction Stop).Source
  } else {
    # Linux can render Windows source but cannot execute powershell.exe.
    # Adapt execution only after asserting the actual shared-init contract.
    $configured.interpreters.ps1.command = $engine
    $script:AppsConfig = Join-Path $script:AppsTemporary 'linux-execution.json'
    Write-AppsFixture $script:AppsConfig (ConvertTo-Json -InputObject $configured -Depth 30)
  }
  $assetRoot = Join-Path $script:AppsSource '.chezmoitemplates/windows-apps'
  $metadata = ([IO.File]::ReadAllText((Join-Path $script:AppsSource '.chezmoidata/windows-apps.json')) | ConvertFrom-Json).windowsApps
  Assert-Apps ((Get-FileHash (Join-Path $assetRoot $metadata.zed.path) -Algorithm SHA256).Hash -ieq $metadata.zed.sha256) 'pinned Zed asset hash'
  foreach ($app in @('zed', 'zen')) {
    $license = $metadata.$app.license
    Assert-Apps ((Get-FileHash (Join-Path $assetRoot $license.path) -Algorithm SHA256).Hash -ieq $license.sha256) "$app license hash"
    Assert-Apps ([IO.File]::ReadAllText((Join-Path $assetRoot $license.path)).Contains('MIT License')) "$app license declaration"
  }
  foreach ($file in $metadata.zen.files.PSObject.Properties) {
    Assert-Apps ((Get-FileHash (Join-Path $assetRoot ('zen/' + $file.Name)) -Algorithm SHA256).Hash -ieq $file.Value.sha256) "pinned Zen $($file.Name) hash"
  }
  . (Join-Path $assetRoot 'functions.ps1')
  . (Join-Path $assetRoot 'jsonc.ps1')
  Assert-AppsAst ([IO.File]::ReadAllText((Join-Path $assetRoot 'jsonc.ps1'))) 'windows-apps/jsonc.ps1'
  Assert-AppsAst ([IO.File]::ReadAllText((Join-Path $assetRoot 'functions.ps1'))) 'windows-apps/functions.ps1'
  Assert-AppsAst ([IO.File]::ReadAllText((Join-Path $assetRoot 'start-reneo-elevated.ps1'))) 'ReNeo launcher'
  $reneoRelative = 'AppData/Local/Microsoft/WinGet/Packages/Rojetto.ReNeo.neo2_Microsoft.Winget.Source_8wekyb3d8bbwe/ReNeo/modify_config.json.ps1.tmpl'
  $sources = @('AppData/Roaming/Zed/modify_settings.json.ps1.tmpl', 'AppData/Roaming/Zed/keymap.json.tmpl', 'AppData/Roaming/Zed/themes/catppuccin-mauve.json.tmpl', 'AppData/Local/Fork/modify_settings.json.ps1.tmpl', 'AppData/Local/Microsoft/PowerToys/modify_settings.json.ps1.tmpl', $reneoRelative, 'AppData/Roaming/AltSnap/modify_AltSnap.ini.ps1.tmpl', 'AppData/Local/WindowsConfiguration/start-reneo-elevated.ps1.tmpl')
  foreach ($relative in $sources) {
    $rendered = Render-AppsTemplate $relative
    if ($relative.Contains('/modify_') -or $relative.EndsWith('.ps1.tmpl')) { Assert-AppsAst $rendered $relative }
    Write-AppsFixture (Join-Path $script:AppsRenderedSource $relative.Substring(0, $relative.Length - 5)) $rendered
  }
  $before = Render-AppsTemplate 'run_before_windows-apps-stop.ps1.tmpl'
  $after = Render-AppsTemplate 'run_after_windows-apps-restart.ps1.tmpl'
  $tern = Render-AppsTemplate 'run_after_windows-tern-path.ps1.tmpl'
  $expectedZed = (Render-AppsTemplate '.chezmoitemplates/zed-settings.json.tmpl') | ConvertFrom-Json
  Assert-AppsAst $before 'run_before_windows-apps-stop.ps1'
  Assert-AppsAst $after 'run_after_windows-apps-restart.ps1'
  Assert-AppsAst $tern 'run_after_windows-tern-path.ps1'
  $beforePath = Join-Path $script:AppsTemporary 'before.ps1'
  $afterPath = Join-Path $script:AppsTemporary 'after.ps1'
  Write-AppsFixture $beforePath $before
  Write-AppsFixture $afterPath $after

  # The fixture's source has only app files. Package/service/admin operations are absent.
  $zed = Join-Path $env:APPDATA 'Zed/settings.json'
  $fork = Join-Path $env:LOCALAPPDATA 'Fork/settings.json'
  $powerToys = Join-Path $env:LOCALAPPDATA 'Microsoft/PowerToys/settings.json'
  $reneo = Join-Path $script:AppsHome $reneoRelative.Replace('modify_config.json.ps1.tmpl', 'config.json')
  $altSnap = Join-Path $env:APPDATA 'AltSnap/AltSnap.ini'
  $keymap = Join-Path $env:APPDATA 'Zed/keymap.json'
  $jsonc = @'
{
  // state and strings with comment-looking text are legitimate JSONC
  "ui_state": {"label": "unicode \u03bb", "url": "https://example.invalid/a/*b*/"},
  "buffer_font_size": 99,
  "languages": {"Nix": {"language_servers": ["nixd", "!nil"], "tab_size": 7}},
  "lsp": {"nixd": {"binary": {"path": "wsl.exe"}}, "texlab": {}, "pyright": {"settings": {"custom": true}}},
  "agent_servers": {"omp": {"command": "wsl.exe"}, "other": {"command": "native.exe"}},
  "wsl_connections": [{"distro_name": "NixOS"}],
}
'@
  $spanResult = ConvertFrom-AppJsonc (Get-AppJson $jsonc $expectedZed 'zed')
  Assert-Apps ($spanResult.buffer_font_size -eq 14 -and $spanResult.vim_mode -eq $true -and $spanResult.base_keymap -eq 'VSCode') 'pure JSONC merge uses native shared declaration'
  # Exercise the rendered filter's actual stdin/stdout contract in this engine.
  $filterStart = [Diagnostics.ProcessStartInfo]::new()
  $filterStart.FileName = $engine
  $filterStart.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + (Join-Path $script:AppsRenderedSource 'AppData/Roaming/Zed/modify_settings.json.ps1') + '"'
  $filterStart.UseShellExecute = $false
  $filterStart.RedirectStandardInput = $true; $filterStart.RedirectStandardOutput = $true; $filterStart.RedirectStandardError = $true
  $filterStart.StandardOutputEncoding = [Text.UTF8Encoding]::new($false)
  $filterProcess = [Diagnostics.Process]::Start($filterStart)
  try {
    $filterProcess.StandardInput.Write($jsonc)
    $filterProcess.StandardInput.Close()
    $filterOutput = $filterProcess.StandardOutput.ReadToEnd()
    $filterError = $filterProcess.StandardError.ReadToEnd()
    $filterProcess.WaitForExit()
    Assert-Apps ($filterProcess.ExitCode -eq 0) "direct rendered Zed filter exit=$($filterProcess.ExitCode): $filterError"
  } finally { $filterProcess.Dispose() }
  $filterResult = ConvertFrom-AppJsonc $filterOutput
  Assert-Apps ($filterResult.buffer_font_size -eq 14 -and $filterResult.vim_mode -eq $true -and $filterResult.base_keymap -eq 'VSCode') "direct rendered Zed filter: buffer_font_size=$($filterResult.buffer_font_size), vim_mode=$($filterResult.vim_mode), base_keymap=$($filterResult.base_keymap); stderr=$filterError"
  Write-AppsFixture $zed ($jsonc.Replace('unicode \u03bb', 'unicode ' + [char]0x03bb))
  Write-AppsFixture $fork '{"GitInstancePath":"old-wslgit","ui":{"column":37},"repository":"keep me"}'
  Write-AppsFixture $powerToys '{"startup":false,"enabled":{"CmdPal":false,"FutureModule":true},"ui":{"window":123}}'
  Write-AppsFixture $reneo '{"standaloneMode":false,"runtime":{"lastLayout":"keep"}}'
  [void][IO.Directory]::CreateDirectory((Split-Path -Parent $altSnap))
  $altSnapUnrelated = 'Unrelated=keep ' + [char]0x00fc + [char]0x03bb + [char]0x6771
  [IO.File]::WriteAllText($altSnap, "[General]`r`nAero=0`r`nAutoSnap=0`r`n$altSnapUnrelated`r`n[Input]`r`nHotkeys=keep`r`n", [Text.UnicodeEncoding]::new($false, $true))
  Write-AppsFixture $keymap '[{"context":"Editor","bindings":{"ctrl-c":"bad"}}]'
  # Existing relative and absolute profiles are discovered by their own sections.
  $zenRoot = Join-Path $env:APPDATA 'zen'
  $relativeProfile = Join-Path $zenRoot 'Profiles/existing.default'
  $absoluteProfile = Join-Path $script:AppsTemporary 'absolute profile'
  [void][IO.Directory]::CreateDirectory($relativeProfile)
  [void][IO.Directory]::CreateDirectory($absoluteProfile)
  $profilesIni = Join-Path $zenRoot 'profiles.ini'
  Write-AppsFixture $profilesIni "[General]`nStartWithLastProfile=1`n[Profile0]`nName=existing`nIsRelative=1`nPath=Profiles/existing.default`n[InstallNotAProfile]`nDefault=must-not-be-treated-as-path`n[Profile1]`nName=absolute`nIsRelative=0`nPath=$absoluteProfile`n"
  foreach ($profile in @($relativeProfile, $absoluteProfile)) {
    Write-AppsFixture (Join-Path $profile 'cookies.sqlite') 'unchanged cookies fixture'
    Write-AppsFixture (Join-Path $profile 'prefs.js') 'unchanged runtime preferences'
    Write-AppsFixture (Join-Path $profile 'chrome/unrelated.css') 'unchanged custom file'
    Write-AppsFixture (Join-Path $profile 'user.js') "// keep comment`nuser_pref(`"unrelated.value`", 19);`nuser_pref(`"toolkit.legacyUserProfileCustomizations.stylesheets`", false);`nuser_pref(`"toolkit.legacyUserProfileCustomizations.stylesheets`", false); // preserve inline comment`n"
  }

  # Process doubles expose exactly the stop/wait/write/start boundary, no real app.
  $script:AppsEvents = [Collections.Generic.List[string]]::new()
  $powerToysRunner = Join-Path $env:LOCALAPPDATA 'PowerToys/PowerToys.exe'
  $processFixture = [PSCustomObject]@{ Events = $script:AppsEvents; ReNeoRunning = $false; PowerToysRunner = $powerToysRunner }
  ${function:Get-Process} = {
    param([string]$Name, $ErrorAction)
    $processFixture.Events.Add('get:' + $Name)
    if ($Name -eq 'reneo' -and -not $processFixture.ReNeoRunning) { return }
    if ($Name -eq 'PowerToys*') {
      [PSCustomObject]@{ Path = $processFixture.PowerToysRunner; ProcessName = 'PowerToys'; Id = 12345 }
      [PSCustomObject]@{ Path = 'fixture PowerToys.FancyZones.exe'; ProcessName = 'PowerToys.FancyZones'; Id = 12346 }
      return
    }
    [PSCustomObject]@{ Path = ('fixture ' + $Name + '.exe'); ProcessName = $Name; Id = 12345 }
  }.GetNewClosure()
  ${function:Stop-Process} = {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline = $true)]$InputObject, [switch]$Force)
    process { $processFixture.Events.Add('stop:' + $InputObject.ProcessName) }
  }.GetNewClosure()
  ${function:Wait-Process} = {
    [CmdletBinding()]
    param([Parameter(ValueFromPipeline = $true)]$InputObject, [int]$Timeout)
    process { $processFixture.Events.Add('wait:' + $InputObject.ProcessName) }
  }.GetNewClosure()
  ${function:Start-Process} = {
    param([string]$FilePath, $ErrorAction, [string]$Verb)
    $processFixture.Events.Add('start:' + $FilePath)
    if ($Verb) { $processFixture.Events.Add('verb:' + $Verb) }
  }.GetNewClosure()
  & $beforePath
  Assert-Apps ($script:AppsEvents -contains 'stop:Fork' -and $script:AppsEvents -contains 'wait:Fork') 'Fork stop/wait before write'
  Assert-Apps ($script:AppsEvents -contains 'stop:PowerToys' -and $script:AppsEvents -contains 'stop:PowerToys.FancyZones' -and $script:AppsEvents -contains 'stop:AltSnap') 'PowerToys runner/child and AltSnap stop before write'
  Assert-Apps ([IO.File]::ReadAllText($fork).Contains('old-wslgit')) 'before hook does not write a managed file'
  $null = Invoke-AppsApply 'apply'
  & $afterPath
  Assert-Apps ($script:AppsEvents -contains 'start:fixture Fork.exe' -and $script:AppsEvents -contains ('start:' + $powerToysRunner) -and $script:AppsEvents -contains 'start:fixture AltSnap.exe') "held applications restart after write; process events=$($script:AppsEvents -join '; ')"
  Assert-Apps (@($script:AppsEvents | Where-Object { $_ -like 'start:*PowerToys*' }).Count -eq 1 -and $script:AppsEvents -notcontains 'start:fixture PowerToys.FancyZones.exe') 'PowerToys restarts only its canonical runner, never a child'
  Assert-Apps ($script:AppsEvents -contains 'stop:zen' -and $script:AppsEvents -contains 'wait:zen' -and $script:AppsEvents -contains 'start:fixture zen.exe') 'Zen stop/write/restart'
  $null = Invoke-AppsApply 'verify'
  Assert-Apps ((Get-FileHash (Join-Path $env:APPDATA 'Zed/themes/catppuccin-mauve.json') -Algorithm SHA256).Hash -ieq $metadata.zed.sha256) 'rendered Zed theme preserves exact source bytes'
  $actual = ConvertFrom-AppJsonc ([IO.File]::ReadAllText($zed))
  Assert-Apps ($actual.buffer_font_size -eq 14 -and $actual.vim_mode -eq $true -and $actual.base_keymap -eq 'VSCode') "native shared Zed settings: expected buffer_font_size=$($expectedZed.buffer_font_size), vim_mode=$($expectedZed.vim_mode), base_keymap=$($expectedZed.base_keymap); actual buffer_font_size=$($actual.buffer_font_size), vim_mode=$($actual.vim_mode), base_keymap=$($actual.base_keymap)"
  Assert-Apps ([IO.File]::ReadAllText($zed).Contains('// state and strings with comment-looking text are legitimate JSONC')) 'changed Zed JSONC retains comments'
  Assert-Apps ($actual.ui_state.label -ceq ('unicode ' + [char]0x03bb)) 'literal UTF-8 input/output preserved'
  Assert-Apps ($actual.ui_state.url -ceq 'https://example.invalid/a/*b*/' -and $actual.languages.Nix.tab_size -eq 7) 'Zed undeclared JSONC state preserved'
  Assert-Apps ($actual.languages.Nix.language_servers.Count -eq 0 -and $null -eq $actual.lsp.nixd -and $null -eq $actual.lsp.texlab -and $null -eq $actual.agent_servers.omp) 'removed retired managed integrations'
  Assert-Apps ($actual.wsl_connections.Count -eq 1 -and $actual.wsl_connections[0].distro_name -ceq 'NixOS') 'Zed remembered WSL projects preserved'
  Assert-Apps ($actual.lsp.pyright.settings.custom -eq $true -and $actual.agent_servers.other.command -eq 'native.exe') 'unrelated Zed agent/LSP preserved'
  $actual = [IO.File]::ReadAllText($fork) | ConvertFrom-Json
  Assert-Apps ($actual.GitInstancePath -eq (Join-Path $script:AppsHome 'AppData/Local/Programs/Git/cmd/git.exe') -and $actual.ui.column -eq 37) 'native Fork Git and UI state'
  $actual = [IO.File]::ReadAllText($powerToys) | ConvertFrom-Json
  $declared = [IO.File]::ReadAllText((Join-Path $assetRoot 'power-toys-settings.json')) | ConvertFrom-Json
  foreach ($property in $declared.enabled.PSObject.Properties) { Assert-Apps ($actual.enabled.($property.Name) -eq $property.Value) "PowerToys $($property.Name)" }
  Assert-Apps ($actual.enabled.FutureModule -eq $true -and $actual.ui.window -eq 123) 'PowerToys undeclared module/UI state'
  $actual = [IO.File]::ReadAllText($reneo) | ConvertFrom-Json
  Assert-Apps ($actual.standaloneLayout -eq 'Neo' -and $actual.standaloneMode -eq $true -and $actual.runtime.lastLayout -eq 'keep') 'ReNeo declared keys and runtime state'
  $actual = [IO.File]::ReadAllText($altSnap)
  foreach ($line in @('Aero=1', 'SmartAero=1', 'AutoSnap=2', 'AeroHoffset=50', 'AeroVoffset=50', 'Unrelated=keep', 'Hotkeys=keep')) { Assert-Apps ($actual.Contains($line)) "AltSnap $line" }
  Assert-Apps ($actual.Contains($altSnapUnrelated)) 'AltSnap unrelated non-ASCII content survives UTF-16 modification'
  $altSnapBytes = [IO.File]::ReadAllBytes($altSnap)
  Assert-Apps ($altSnapBytes[0] -eq 255 -and $altSnapBytes[1] -eq 254) 'AltSnap retains its original UTF-16 LE BOM'
  $actualKeymap = [IO.File]::ReadAllText($keymap) | ConvertFrom-Json
  Assert-Apps ($actualKeymap.Count -eq 2 -and $actualKeymap[0].context -eq 'Editor && mode == full' -and $actualKeymap[1].bindings.'ctrl-c' -eq 'editor::Copy' -and $null -eq $actualKeymap[0].bindings.'ctrl-k') 'complete Windows-first editor-only keymap'
  foreach ($profile in @($relativeProfile, $absoluteProfile)) {
    $userJs = [IO.File]::ReadAllText((Join-Path $profile 'user.js'))
    Assert-Apps ([regex]::Matches($userJs, 'user_pref\("toolkit\.legacyUserProfileCustomizations\.stylesheets"').Count -eq 1) 'Zen single preference'
    Assert-Apps ($userJs.Contains('user_pref("unrelated.value", 19);') -and $userJs.Contains('// keep comment') -and $userJs.Contains('// preserve inline comment')) 'Zen unrelated preference/comments'
    Assert-Apps ([IO.File]::ReadAllText((Join-Path $profile 'cookies.sqlite')) -ceq 'unchanged cookies fixture') 'Zen cookies untouched'
    Assert-Apps ([IO.File]::ReadAllText((Join-Path $profile 'prefs.js')) -ceq 'unchanged runtime preferences') 'Zen runtime prefs untouched'
    Assert-Apps ([IO.File]::ReadAllText((Join-Path $profile 'chrome/unrelated.css')) -ceq 'unchanged custom file') 'Zen undeclared chrome file untouched'
    foreach ($file in $metadata.zen.files.PSObject.Properties) {
      Assert-Apps ((Get-FileHash (Join-Path $profile ('chrome/' + $file.Name)) -Algorithm SHA256).Hash -ieq $file.Value.sha256) "applied Zen $($file.Name) exact bytes"
    }
  }
  # JSON/text writes use BOMless UTF-8; AltSnap retains its own encoding above.
  foreach ($path in @($zed, $fork, $powerToys, $reneo, $keymap, (Join-Path $relativeProfile 'user.js'))) {
    $bytes = [IO.File]::ReadAllBytes($path)
    Assert-Apps (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)) "no BOM: $path"
  }
  $snapshot = @{}
  foreach ($path in @($zed, $fork, $powerToys, $reneo, $altSnap, $keymap, (Join-Path $relativeProfile 'user.js'))) { $snapshot[$path] = (Get-FileHash $path -Algorithm SHA256).Hash }
  $script:AppsEvents.Clear()
  & $beforePath
  $null = Invoke-AppsApply 'apply'
  & $afterPath
  $null = Invoke-AppsApply 'verify'
  Assert-Apps ($script:AppsEvents.Count -eq 0) 'unchanged apply stops/restarts no app'
  foreach ($path in $snapshot.Keys) { Assert-Apps ((Get-FileHash $path -Algorithm SHA256).Hash -ceq $snapshot[$path]) "repeat write identity: $path" }
  # Enforced keymap is repaired, not merged with an undeclared entry.
  Write-AppsFixture $keymap '[{"context":"Terminal","bindings":{"ctrl-c":"bad"}}]'
  $null = Invoke-AppsApply 'apply'
  $null = Invoke-AppsApply 'verify'
  Assert-Apps (-not [IO.File]::ReadAllText($keymap).Contains('Terminal')) 'keymap convergence removes undeclared entries'

  $validZed = [IO.File]::ReadAllText($zed)
  foreach ($malformed in @('{"bad":', '{/* unterminated', '[1,2]', '"string"', 'true', 'null', '{"quoted":"unterminated}', '{"bad":[1}', '{"bad":tru3}', '{"a":1 "b":2}', '{"a":1} true', '{"escape":"\x"}')) {
    Write-AppsFixture $zed $malformed
    $script:AppsEvents.Clear()
    Assert-AppsFailure { & $beforePath } 'JSON|comment|object|string' -Context "malformed JSONC [$malformed]"
    Assert-Apps ($script:AppsEvents.Count -eq 0) 'malformed JSONC rejected before stopping any app'
    Assert-AppsFailure { $null = Invoke-AppsApply 'apply' } 'chezmoi exit' -Context "malformed JSONC [$malformed]"
    Assert-Apps ([IO.File]::ReadAllText($zed) -ceq $malformed) 'malformed JSONC never overwritten'
  }
  Write-AppsFixture $zed $validZed
  $null = Invoke-AppsApply 'verify'
  # Pure unchanged JSONC retains comments/trailing commas exactly.
  $unchanged = @'
{ // retained
 "x": {"url": "https://example.invalid/\"quoted\"",},
}
'@
  Assert-Apps ((Get-AppJson $unchanged ([PSCustomObject]@{ x = [PSCustomObject]@{} }) 'fixture') -ceq $unchanged) 'unchanged JSONC byte preservation'
  $sameLine = 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", false); user_pref("other", 22);'
  Assert-Apps ((Get-ZenUserJs $sameLine $metadata.zen.preference).Contains('user_pref("other", 22);')) 'same-line unrelated Zen preference preservation'
  $commentExample = "/*`nuser_pref(`"toolkit.legacyUserProfileCustomizations.stylesheets`", false);`n*/`n"
  Assert-Apps ((Get-ZenUserJs $commentExample $metadata.zen.preference).StartsWith($commentExample)) 'Zen commented preference example preserved'
  $missingIni = Join-Path $script:AppsTemporary 'missing profiles.ini'
  $script:AppsEvents.Clear()
  Apply-ZenWrites @(Get-ZenWrites $missingIni @() $metadata.zen.preference)
  Assert-Apps ($script:AppsEvents.Count -eq 0 -and -not (Test-Path $missingIni)) 'fresh Zen without a profile skips setup without writes/process changes'
  $preservedOnly = ConvertFrom-AppJsonc (Get-AppJson '{"wsl_connections":[]}' ([PSCustomObject]@{ vim_mode = $true }) 'zed')
  Assert-Apps ($preservedOnly.vim_mode -eq $true -and $null -ne $preservedOnly.wsl_connections -and $preservedOnly.wsl_connections.Count -eq 0) 'JSONC sole UI-state property preserved with missing-key insertion'
  $changedComment = Get-AppJson "{/*keep nested*/`"nested`":{`"declared`":0,/*keep sibling*/`"other`":5,},}" ([PSCustomObject]@{ nested = [PSCustomObject]@{ declared = 1 } }) 'fixture'
  Assert-Apps ($changedComment.Contains('/*keep nested*/') -and $changedComment.Contains('/*keep sibling*/') -and (ConvertFrom-AppJsonc $changedComment).nested.other -eq 5) 'changed nested JSONC retains comments, sibling state and trailing commas'
  Assert-AppsFailure { Get-ZenProfiles (Join-Path $script:AppsTemporary 'missing profiles.ini') } 'Launch Zen once'
  $badIni = Join-Path $script:AppsTemporary 'bad profiles.ini'
  Write-AppsFixture $badIni "[Profile0]`nIsRelative=1`nPath=missing-profile`n"
  Assert-AppsFailure { Get-ZenProfiles $badIni } 'does not exist'
  Assert-Apps (-not (Test-Path (Join-Path $script:AppsTemporary 'missing-profile'))) 'no Zen profile fabrication'
  Write-AppsFixture $badIni "[Profile0]`nIsRelative=0`nPath=relative-not-absolute`n"
  Assert-AppsFailure { Get-ZenProfiles $badIni } 'non-absolute'
  Write-AppsFixture $badIni "[Profile0]`nIsRelative=1`nPath=$absoluteProfile`n"
  Assert-AppsFailure { Get-ZenProfiles $badIni } 'rooted relative'
  # A write failure still restarts a previously running Zen process.
  $script:AppsEvents.Clear()
  $notDirectory = Join-Path $script:AppsTemporary 'not a directory'
  Write-AppsFixture $notDirectory 'file'
  Assert-AppsFailure { Apply-ZenWrites @([PSCustomObject]@{ Path = (Join-Path $notDirectory 'user.js'); Text = 'cannot write' }) } 'directory|file|path|exist'
  Assert-Apps ($script:AppsEvents -contains 'start:fixture zen.exe') 'failed Zen write restarts prior process'

  # Tern PATH setup uses user scope only, canonicalizes duplicates, and repeats no write.
  $ternPath = Join-Path $script:AppsHome 'AppData/Local/Programs/Tern'
  Write-AppsFixture (Join-Path $ternPath 'tern.exe') 'fixture executable'
  $pathFixture = [PSCustomObject]@{ UserPath = ('keep before;' + $ternPath + ';keep after;' + $ternPath.ToUpperInvariant() + '/'); Writes = 0 }
  # The standalone regressions below exercise the real registry wrappers with
  # registry and native-message doubles; this fixture tests the rendered tail.
  # Definitions must precede the operational tail, so separate its function prelude.
  $ternAstTokens = $null; $ternAstErrors = $null
  $ternAst = [Management.Automation.Language.Parser]::ParseInput($tern, [ref]$ternAstTokens, [ref]$ternAstErrors)
  $directoryStatement = @($ternAst.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -eq '$directory' })[0]
  $split = $directoryStatement.Extent.StartOffset
  $ternDoubles = "param(`$FixtureState)`n" + $tern.Substring(0, $split) + "`nfunction Get-AppUserPath { return `$FixtureState.UserPath }`nfunction Set-AppUserPath { param([string]`$Value) `$FixtureState.UserPath = `$Value; `$FixtureState.Writes++ }`n" + $tern.Substring($split)
  $ternFixturePath = Join-Path $script:AppsTemporary 'tern.ps1'
  Write-AppsFixture $ternFixturePath $ternDoubles
  & $ternFixturePath $pathFixture
  & $ternFixturePath $pathFixture
  Assert-Apps ($pathFixture.UserPath -ceq ('keep before;' + $ternPath + ';keep after') -and $pathFixture.Writes -eq 1) 'Tern stable user PATH exactly once'
  Assert-Apps (-not $tern.Contains('omp.json') -and -not $tern.Contains('settings.json') -and -not $tern.Contains("SetEnvironmentVariable('Path', 'Machine')")) 'Tern setup has no OMP/state/machine PATH owner'
  $launcher = Join-Path $env:LOCALAPPDATA 'WindowsConfiguration/start-reneo-elevated.ps1'
  $script:AppsEvents.Clear()
  Assert-AppsFailure { & $launcher } 'ReNeo is not installed'
  Assert-Apps ($script:AppsEvents.Count -eq 0) 'missing ReNeo payload is not launched'
  Write-AppsFixture (Join-Path (Split-Path -Parent $reneo) 'reneo.exe') 'fixture ReNeo executable'
  $processFixture.ReNeoRunning = $true
  & $launcher
  Assert-Apps (@($script:AppsEvents | Where-Object { $_ -like 'start:*' }).Count -eq 0) 'running ReNeo is not duplicated'
  $processFixture.ReNeoRunning = $false
  $script:AppsEvents.Clear()
  & $launcher
  Assert-Apps ($script:AppsEvents -contains 'verb:RunAs' -and @($script:AppsEvents | Where-Object { $_ -like 'start:*' }).Count -eq 1) 'ReNeo launcher requests explicit owner RunAs once'
  Write-Output 'PASS chezmoi app fixtures: JSONC/state, native keymap/Fork, module keys, real Zen profiles, BOM, process doubles, repeats, Tern user PATH'
  & (Join-Path $PSScriptRoot 'app-regressions.ps1') -RepositoryRoot $RepositoryRoot
} finally {
  foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
  Remove-Item -LiteralPath $script:AppsTemporary -Recurse -Force -ErrorAction SilentlyContinue
}
