param(
  [Parameter(Mandatory = $true)][string]$RepositoryRoot,
  [ValidateSet('All', 'AltSnap', 'PowerToys', 'Path')][string]$Case = 'All'
)
$ErrorActionPreference = 'Stop'
# Run this current fixture against any source snapshot, including the pre-fix
# checkout. Only temporary files and process/registry/message doubles are used.
function Assert-AppRegression {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw "app-regressions: $Message" }
}
function Write-AppRegressionFile {
  param([string]$Path, [string]$Text)
  [void][IO.Directory]::CreateDirectory((Split-Path -Parent $Path))
  [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}
function Render-AppRegression {
  param([string]$Relative)
  $inputPath = Join-Path $script:RegressionTemporary 'input.tmpl'
  $outputPath = Join-Path $script:RegressionTemporary 'output'
  $prefix = '{{- $_ := set .chezmoi "os" "windows" -}}{{- $_ := set .chezmoi "homeDir" ' + ($script:RegressionHome | ConvertTo-Json -Compress) + ' -}}'
  Write-AppRegressionFile $inputPath ($prefix + [IO.File]::ReadAllText((Join-Path $script:RegressionSource $Relative)))
  $oldPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = 'Continue'
    $output = & $script:RegressionChezmoi --config $script:RegressionConfig --source $script:RegressionSource --destination $script:RegressionHome --persistent-state $script:RegressionState --cache $script:RegressionCache --output $outputPath execute-template --file $inputPath 2>&1
    $exitCode = $LASTEXITCODE
  } finally { $ErrorActionPreference = $oldPreference }
  Assert-AppRegression ($exitCode -eq 0) "render $Relative exited ${exitCode}: $($output -join '; ')"
  return [IO.File]::ReadAllText($outputPath)
}
function Split-AppRegressionHook {
  param([string]$Text)
  $tokens = $null; $errors = $null
  $ast = [Management.Automation.Language.Parser]::ParseInput($Text, [ref]$tokens, [ref]$errors)
  Assert-AppRegression ($errors.Count -eq 0) "hook parser: $($errors.Message -join '; ')"
  $start = @($ast.EndBlock.Statements | Where-Object { $_ -is [Management.Automation.Language.AssignmentStatementAst] -and $_.Left.Extent.Text -eq '$restartState' })[0].Extent.StartOffset
  return @{ Prelude = $Text.Substring(0, $start); Body = $Text.Substring($start) }
}
function Invoke-AppRegressionFilter {
  param([byte[]]$Bytes)
  $start = [Diagnostics.ProcessStartInfo]::new()
  # This directly tests the byte-stream contract in the current test host; the
  # normal apps suite separately exercises the shared init interpreter policy.
  $start.FileName = $script:RegressionEngine
  $start.Arguments = '-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $script:RegressionFilter + '"'
  $start.UseShellExecute = $false
  $start.RedirectStandardInput = $true; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
  # .NET Framework builds an AutoFlush StreamWriter for redirected stdin.
  # Its inherited console encoding can emit a BOM before any BaseStream write.
  # Construct that pipe with a BOMless writer, then restore the caller's encoding.
  $parentInputEncoding = [Console]::InputEncoding
  try {
    [Console]::InputEncoding = [Text.UTF8Encoding]::new($false)
    $process = [Diagnostics.Process]::Start($start)
    $inputStream = $process.StandardInput.BaseStream
  } finally { [Console]::InputEncoding = $parentInputEncoding }
  $result = [IO.MemoryStream]::new()
  try {
    $inputStream.Write($Bytes, 0, $Bytes.Length)
    $process.StandardInput.Close()
    $process.StandardOutput.BaseStream.CopyTo($result)
    $stderr = $process.StandardError.ReadToEnd()
    $script:RegressionFilterStderr = $stderr
    $process.WaitForExit()
    Assert-AppRegression ($process.ExitCode -eq 0) "AltSnap filter exited $($process.ExitCode): $stderr"
    return ,$result.ToArray()
  } finally { $result.Dispose(); $process.Dispose() }
}
function Test-AltSnapRegression {
  . ([scriptblock]::Create($script:RegressionBefore.Prelude))
  Write-AppText (Join-Path $env:LOCALAPPDATA 'Fork/settings.json') (Get-AppJson '' $forkDesired 'fork')
  Write-AppText (Join-Path $env:LOCALAPPDATA 'Microsoft/PowerToys/settings.json') (Get-AppJson '' $powerToysDesired 'power-toys')
  $path = Join-Path $env:APPDATA 'AltSnap/AltSnap.ini'
  $unrelated = '; untouched ' + [char]0x00fc + [char]0x03bb + [char]0x6771
  $text = "[General]`r`n$unrelated`r`nAero=0`r`nAutoSnap=0`r`nCustom=" + [char]0x00e9 + "`r`n[Input]`r`nHotkeys=keep`r`n"
  $encoding = [Text.UnicodeEncoding]::new($false, $true)
  $inputBytes = [byte[]]($encoding.GetPreamble() + $encoding.GetBytes($text))
  # Hosted Windows PowerShell can inherit BOM-bearing UTF-8 console input.
  # The binary fixture transport must not prepend that encoding's preamble.
  $parentInputEncoding = [Console]::InputEncoding
  try {
    [Console]::InputEncoding = [Text.Encoding]::UTF8
    $outputBytes = Invoke-AppRegressionFilter $inputBytes
  } finally { [Console]::InputEncoding = $parentInputEncoding }
  if ($outputBytes.Length -lt 2 -or $outputBytes[0] -ne 255 -or $outputBytes[1] -ne 254) {
    $prefix = [BitConverter]::ToString($outputBytes, 0, [Math]::Min(16, $outputBytes.Length))
    throw "AltSnap must retain the original UTF-16 LE BOM; stdout length=$($outputBytes.Length), first bytes=$prefix; stderr=$script:RegressionFilterStderr"
  }
  $actual = $encoding.GetString($outputBytes, 2, $outputBytes.Length - 2)
  Assert-AppRegression ($actual.Contains($unrelated + "`r`n") -and $actual.Contains('Custom=' + [char]0x00e9 + "`r`n") -and $actual.Contains("Hotkeys=keep`r`n")) 'AltSnap unrelated non-ASCII lines must survive unchanged'
  foreach ($line in @('Aero=1', 'AutoSnap=2', 'SmartAero=1', 'AeroHoffset=50', 'AeroVoffset=50')) {
    Assert-AppRegression ($actual.Contains($line)) "AltSnap declared $line must converge"
  }
  [void][IO.Directory]::CreateDirectory((Split-Path -Parent $path))
  [IO.File]::WriteAllBytes($path, $inputBytes)
  $events = [Collections.Generic.List[string]]::new()
  function Get-Process { param([string]$Name, $ErrorAction) if ($Name -eq 'AltSnap') { [PSCustomObject]@{ Path = 'fixture AltSnap.exe'; ProcessName = 'AltSnap' } } }
  function Stop-Process { [CmdletBinding()]param([Parameter(ValueFromPipeline = $true)]$InputObject, [switch]$Force) process { $events.Add('stop:' + $InputObject.ProcessName) } }
  function Wait-Process { [CmdletBinding()]param([Parameter(ValueFromPipeline = $true)]$InputObject, [int]$Timeout) process { $events.Add('wait:' + $InputObject.ProcessName) } }
  function Start-Process { param([string]$FilePath, $ErrorAction) $events.Add('start:' + $FilePath) }
  & ([scriptblock]::Create($script:RegressionBefore.Body))
  Assert-AppRegression ($events -contains 'stop:AltSnap' -and $events -contains 'wait:AltSnap') 'AltSnap drift must stop/wait before writing'
  [IO.File]::WriteAllBytes($path, $outputBytes)
  & ([scriptblock]::Create($script:RegressionAfter))
  Assert-AppRegression ($events -contains 'start:fixture AltSnap.exe') 'AltSnap must restart after writing'
  $events.Clear()
  & ([scriptblock]::Create($script:RegressionBefore.Body))
  $repeated = Invoke-AppRegressionFilter $outputBytes
  & ([scriptblock]::Create($script:RegressionAfter))
  Assert-AppRegression ($events.Count -eq 0) 'UTF-16 AltSnap must produce no false repeated hook drift'
  Assert-AppRegression ([Convert]::ToBase64String($outputBytes) -ceq [Convert]::ToBase64String($repeated)) 'UTF-16 AltSnap repeated modification must be byte stable'
  $newBytes = Invoke-AppRegressionFilter ([byte[]]@())
  Assert-AppRegression ($newBytes[0] -eq [byte][char]'[' -and [Text.Encoding]::UTF8.GetString($newBytes).Contains('Aero=1')) 'new BOMless AltSnap INI must use UTF-8 without BOM'
}
function Test-PowerToysRegression {
  . ([scriptblock]::Create($script:RegressionBefore.Prelude))
  Write-AppText (Join-Path $env:LOCALAPPDATA 'Fork/settings.json') (Get-AppJson '' $forkDesired 'fork')
  Write-AppText (Join-Path $env:APPDATA 'AltSnap/AltSnap.ini') (Get-AppIni '' $altSnapDesired)
  Write-AppText (Join-Path $env:LOCALAPPDATA 'Microsoft/PowerToys/settings.json') '{"startup":false,"enabled":{"CmdPal":false}}'
  $runner = Join-Path $env:LOCALAPPDATA 'PowerToys/PowerToys.exe'
  $events = [Collections.Generic.List[string]]::new()
  function Get-Process {
    param([string]$Name, $ErrorAction)
    if ($Name -eq 'PowerToys*') {
      [PSCustomObject]@{ Path = $runner; ProcessName = 'PowerToys' }
      [PSCustomObject]@{ Path = 'fixture PowerToys.FancyZones.exe'; ProcessName = 'PowerToys.FancyZones' }
    }
  }
  function Stop-Process { [CmdletBinding()]param([Parameter(ValueFromPipeline = $true)]$InputObject, [switch]$Force) process { $events.Add('stop:' + $InputObject.ProcessName) } }
  function Wait-Process { [CmdletBinding()]param([Parameter(ValueFromPipeline = $true)]$InputObject, [int]$Timeout) process { $events.Add('wait:' + $InputObject.ProcessName) } }
  function Start-Process { param([string]$FilePath, $ErrorAction) $events.Add('start:' + $FilePath) }
  & ([scriptblock]::Create($script:RegressionBefore.Body))
  & ([scriptblock]::Create($script:RegressionAfter))
  Assert-AppRegression ($events -contains 'stop:PowerToys' -and $events -contains 'stop:PowerToys.FancyZones' -and $events -contains 'wait:PowerToys.FancyZones') 'PowerToys runner and children must stop/wait together'
  $starts = @($events | Where-Object { $_ -like 'start:*' })
  Assert-AppRegression ($starts.Count -eq 1 -and $starts[0] -ceq ('start:' + $runner)) 'PowerToys must restart only its canonical runner, never a child'
}
function Test-PathRegression {
  $helperPath = Join-Path $script:RegressionSource '.chezmoitemplates/windows-apps/functions.ps1'
  $helperText = [IO.File]::ReadAllText($helperPath)
  # Do not call pre-fix static Environment APIs: even the negative run is kept
  # away from the actual user registry and broadcast API.
  Assert-AppRegression ($helperText.Contains('function Open-AppUserEnvironment') -and $helperText.Contains('function Invoke-AppEnvironmentMessage')) 'PATH requires narrow registry/message seams before safely testing production helpers'
  . $helperPath
  $state = [PSCustomObject]@{ Raw = '%USERPROFILE%\bin; keep raw ;%LOCALAPPDATA%\Tools'; Reads = 0; Writes = 0; Disposals = 0; Opens = [Collections.Generic.List[bool]]::new(); Kind = $null; Option = $null; Name = ''; Messages = [Collections.Generic.List[object]]::new() }
  $key = [PSCustomObject]@{ State = $state }
  $key | Add-Member -MemberType ScriptMethod -Name GetValue -Value { param($Name, $Default, $Option) $this.State.Reads++; $this.State.Name = $Name; $this.State.Option = $Option; return $this.State.Raw }
  $key | Add-Member -MemberType ScriptMethod -Name SetValue -Value { param($Name, $Value, $Kind) $this.State.Writes++; $this.State.Name = $Name; $this.State.Raw = $Value; $this.State.Kind = $Kind }
  $key | Add-Member -MemberType ScriptMethod -Name Dispose -Value { $this.State.Disposals++ }
  function Open-AppUserEnvironment { param([bool]$Writable) $state.Opens.Add($Writable); return $key }
  function Invoke-AppEnvironmentMessage {
    param([IntPtr]$Window, [uint32]$Message, [IntPtr]$WParam, [string]$LParam, [uint32]$Flags, [uint32]$Timeout)
    $state.Messages.Add([PSCustomObject]@{ Window = $Window; Message = $Message; WParam = $WParam; LParam = $LParam; Flags = $Flags; Timeout = $Timeout; Writes = $state.Writes; Disposals = $state.Disposals })
  }
  $raw = $state.Raw
  $current = Get-AppUserPath
  Assert-AppRegression ($current -ceq $raw -and $state.Option -eq [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames -and $state.Name -ceq 'Path') 'PATH registry read must preserve raw unexpanded entries'
  $directory = Join-Path $env:LOCALAPPDATA 'Programs/Tern'
  $desired = Get-TernUserPath $current $directory
  Assert-AppRegression ($desired.StartsWith($raw + ';', [StringComparison]::Ordinal)) 'PATH convergence must preserve unrelated raw entries'
  Set-AppUserPath $desired
  Assert-AppRegression ($state.Raw -ceq $desired -and $state.Kind -eq [Microsoft.Win32.RegistryValueKind]::ExpandString -and $state.Name -ceq 'Path') 'PATH registry write must preserve expansion kind and raw values'
  Assert-AppRegression ($state.Opens.Count -eq 2 -and -not $state.Opens[0] -and $state.Opens[1] -and $state.Disposals -eq 2) 'PATH registry handles must use correct access and be disposed'
  Assert-AppRegression ($state.Messages.Count -eq 1) 'PATH write must broadcast exactly once'
  $message = $state.Messages[0]
  Assert-AppRegression ($message.Window -eq [IntPtr]0xffff -and $message.Message -eq 0x1a -and $message.WParam -eq [IntPtr]::Zero -and $message.LParam -ceq 'Environment' -and $message.Flags -eq 2 -and $message.Timeout -eq 5000 -and $message.Writes -eq 1 -and $message.Disposals -eq 2) 'PATH must broadcast WM_SETTINGCHANGE Environment after the registry write, using bounded SendMessageTimeout'
  $repeated = Get-TernUserPath (Get-AppUserPath) $directory
  if ($repeated -cne $state.Raw) { Set-AppUserPath $repeated }
  Assert-AppRegression ($state.Writes -eq 1 -and $state.Messages.Count -eq 1) 'unchanged PATH must not rewrite or rebroadcast'
}
$script:RegressionTemporary = Join-Path ([IO.Path]::GetTempPath()) ('app regressions ' + [Guid]::NewGuid().ToString('N'))
$script:RegressionHome = Join-Path $script:RegressionTemporary 'user home'
$script:RegressionSource = Join-Path (Resolve-Path -LiteralPath $RepositoryRoot).ProviderPath 'home'
$script:RegressionConfig = Join-Path $script:RegressionTemporary 'chezmoi.json'
$script:RegressionState = Join-Path $script:RegressionTemporary 'state.boltdb'
$script:RegressionCache = Join-Path $script:RegressionTemporary 'cache'
$script:RegressionChezmoi = (Get-Command chezmoi -ErrorAction Stop).Source
$script:RegressionEngine = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$script:RegressionFilter = Join-Path $script:RegressionTemporary 'altsnap.ps1'
$saved = @{}
foreach ($name in @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'PSModulePath')) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
  [void][IO.Directory]::CreateDirectory($script:RegressionHome)
  $env:HOME = $script:RegressionHome; $env:USERPROFILE = $script:RegressionHome
  $env:APPDATA = Join-Path $script:RegressionHome 'AppData/Roaming'
  $env:LOCALAPPDATA = Join-Path $script:RegressionHome 'AppData/Local'
  Write-AppRegressionFile $script:RegressionConfig '{"data":{"host":"korolev"}}'
  $script:RegressionBefore = Split-AppRegressionHook (Render-AppRegression 'run_before_windows-apps-stop.ps1.tmpl')
  $script:RegressionAfter = Render-AppRegression 'run_after_windows-apps-restart.ps1.tmpl'
  Write-AppRegressionFile $script:RegressionFilter (Render-AppRegression 'AppData/Roaming/AltSnap/modify_AltSnap.ini.ps1.tmpl')
  $failures = [Collections.Generic.List[string]]::new()
  foreach ($name in @('AltSnap', 'PowerToys', 'Path')) {
    if ($Case -ne 'All' -and $Case -ne $name) { continue }
    try { & ('Test-' + $name + 'Regression'); Write-Output "PASS app-regressions: $name" }
    catch { $failures.Add("${name}: $($_.Exception.Message)") }
    # A deliberately failing baseline must not contaminate the next case with
    # interrupted restart state; this is fixture-only temporary state.
    $restartState = Join-Path $env:LOCALAPPDATA 'WindowsConfiguration/chezmoi-app-restarts.json'
    if (Test-Path -LiteralPath $restartState) { Remove-Item -LiteralPath $restartState -Force }
  }
  if ($failures.Count -gt 0) { throw ($failures -join "`n") }
} finally {
  foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
  Remove-Item -LiteralPath $script:RegressionTemporary -Recurse -Force -ErrorAction SilentlyContinue
}
