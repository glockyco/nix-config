param([Parameter(Mandatory = $true)][string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
# Run this current fixture against any source snapshot, including the pre-fix
# checkout. Only temporary files and process/registry/message doubles are used.
function Assert-AppRegression {
  param([bool]$Condition, [string]$Message)
  if (-not $Condition) { throw "app-regressions: $Message" }
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
$saved = @{}
foreach ($name in @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'PSModulePath')) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
  [void][IO.Directory]::CreateDirectory($script:RegressionHome)
  $env:HOME = $script:RegressionHome; $env:USERPROFILE = $script:RegressionHome
  $env:APPDATA = Join-Path $script:RegressionHome 'AppData/Roaming'
  $env:LOCALAPPDATA = Join-Path $script:RegressionHome 'AppData/Local'
  Test-PathRegression
  Write-Output 'PASS app-regressions: Path'
} finally {
  foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
  Remove-Item -LiteralPath $script:RegressionTemporary -Recurse -Force -ErrorAction SilentlyContinue
}
