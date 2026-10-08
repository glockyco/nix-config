param(
  [string]$RepositoryRoot = (Join-Path $PSScriptRoot '../..'),
  [ValidateSet('All', 'Interpreter')][string]$Case = 'All'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).Path
foreach ($command in @('git', 'chezmoi')) {
  if (-not (Get-Command $command -CommandType Application -ErrorAction SilentlyContinue)) { throw "checkout-regressions requires $command on PATH" }
}
function Assert-Checkout([bool]$Condition, [string]$Message) {
  if (-not $Condition) { throw "checkout-regressions: $Message" }
}
function Invoke-CheckoutNative([string]$Command, [string[]]$Arguments) {
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try { $output = @(& $Command @Arguments 2>&1); $code = $LASTEXITCODE }
  finally { $ErrorActionPreference = $oldPreference }
  Assert-Checkout ($code -eq 0) ("$Command exited ${code}: " + ($output -join "`n"))
  return ($output -join "`n")
}
$fixtureRoot = Join-Path ([IO.Path]::GetTempPath()) ('checkout regressions ' + [guid]::NewGuid().ToString('N'))
$seed = Join-Path $fixtureRoot 'source snapshot'
$clone = Join-Path $fixtureRoot 'autocrlf checkout'
$target = Join-Path $fixtureRoot 'isolated profile'
$variables = @('HOME', 'USERPROFILE', 'APPDATA', 'LOCALAPPDATA', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'GIT_CONFIG_GLOBAL', 'GIT_CONFIG_SYSTEM', 'GIT_CONFIG_NOSYSTEM', 'GIT_CONFIG_COUNT', 'GIT_ATTR_NOSYSTEM')
$saved = @{}
foreach ($name in $variables) { $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process') }
try {
  $null = New-Item -ItemType Directory -Path $seed, $target -Force
  foreach ($name in @('HOME', 'USERPROFILE')) { [Environment]::SetEnvironmentVariable($name, $target, 'Process') }
  foreach ($pair in @(@('APPDATA', 'AppData/Roaming'), @('LOCALAPPDATA', 'AppData/Local'), @('XDG_CONFIG_HOME', '.config'), @('XDG_CACHE_HOME', '.cache'), @('XDG_STATE_HOME', '.local/state'))) {
    $directory = Join-Path $target $pair[1]
    $null = New-Item -ItemType Directory -Path $directory -Force
    [Environment]::SetEnvironmentVariable($pair[0], $directory, 'Process')
  }
  $emptyConfig = Join-Path $fixtureRoot 'empty.gitconfig'
  [IO.File]::WriteAllText($emptyConfig, '')
  $env:GIT_CONFIG_GLOBAL = $emptyConfig
  $env:GIT_CONFIG_SYSTEM = $emptyConfig
  $env:GIT_CONFIG_NOSYSTEM = '1'
  $env:GIT_CONFIG_COUNT = '0'
  $env:GIT_ATTR_NOSYSTEM = '1'
  # Snapshot actual files, not the caller's Git index/HEAD. This also lets the
  # current fixture test an immutable pre-fix tree with no parent attributes.
  foreach ($relative in @('.chezmoiroot', 'home/.chezmoi.toml.tmpl', 'home/.chezmoidata/hosts.toml', 'home/.chezmoidata/credentials.toml', 'home/.chezmoidata/windows-apps.json')) {
    $destination = Join-Path $seed $relative
    $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($destination)) -Force
    Copy-Item -LiteralPath (Join-Path $RepositoryRoot $relative) -Destination $destination
  }
  $assetRelative = 'home/.chezmoitemplates/windows-apps'
  $null = New-Item -ItemType Directory -Path (Join-Path $seed 'home/.chezmoitemplates') -Force
  Copy-Item -LiteralPath (Join-Path $RepositoryRoot $assetRelative) -Destination (Join-Path $seed $assetRelative) -Recurse -Force
  foreach ($relative in @('.gitattributes', 'home/.gitattributes', 'home/.chezmoitemplates/.gitattributes')) {
    if (Test-Path -LiteralPath (Join-Path $RepositoryRoot $relative)) {
      Copy-Item -LiteralPath (Join-Path $RepositoryRoot $relative) -Destination (Join-Path $seed $relative)
    }
  }
  # Stage without normalization to preserve the supplied tree's canonical bytes;
  # checkout conversion happens only in the real disposable clone below.
  $null = Invoke-CheckoutNative git @('-c', 'core.autocrlf=false', 'init', '-q', $seed)
  $null = Invoke-CheckoutNative git @('-C', $seed, '-c', 'core.autocrlf=false', '-c', "core.attributesFile=$emptyConfig", 'add', '--all')
  $null = Invoke-CheckoutNative git @('-C', $seed, '-c', 'user.name=Checkout Fixture', '-c', 'user.email=fixture@example.invalid', '-c', 'commit.gpgSign=false', 'commit', '-qm', 'Snapshot supplied checkout source')
  $null = Invoke-CheckoutNative git @('-c', 'core.autocrlf=true', '-c', "core.attributesFile=$emptyConfig", 'clone', '--no-local', '-q', $seed, $clone)
  $hostsBytes = [IO.File]::ReadAllBytes((Join-Path $clone 'home/.chezmoidata/hosts.toml'))
  Assert-Checkout (-not ($hostsBytes -contains [byte]13)) 'autocrlf=true clone converted ordinary text to CRLF; the repository eol policy must keep LF'
  if ($Case -ne 'Interpreter') {
    $metadata = ([IO.File]::ReadAllText((Join-Path $clone 'home/.chezmoidata/windows-apps.json')) | ConvertFrom-Json).windowsApps
    $assets = Join-Path $clone $assetRelative
    $pins = @(@{ Path = $metadata.zed.path; Hash = $metadata.zed.sha256 }, @{ Path = $metadata.zed.license.path; Hash = $metadata.zed.license.sha256 }, @{ Path = $metadata.zen.license.path; Hash = $metadata.zen.license.sha256 })
    foreach ($file in $metadata.zen.files.PSObject.Properties) { $pins += @{ Path = ('zen/' + $file.Name); Hash = $file.Value.sha256 } }
    foreach ($pin in $pins) {
      Assert-Checkout ((Get-FileHash -LiteralPath (Join-Path $assets $pin.Path) -Algorithm SHA256).Hash -ieq $pin.Hash) "autocrlf=true clone changed pinned asset bytes: $($pin.Path)"
    }
    foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $seed $assetRelative) -Recurse -File -Force)) {
      $relative = $file.FullName.Substring($seed.Length + 1).Replace('\', '/')
      $actual = (Get-FileHash -LiteralPath (Join-Path $clone $relative) -Algorithm SHA256).Hash
      Assert-Checkout ($actual -ceq (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash) "autocrlf=true clone changed included file bytes: $relative"
      $attribute = Invoke-CheckoutNative git @('-C', $clone, '-c', "core.attributesFile=$emptyConfig", 'check-attr', 'text', '--', $relative)
      Assert-Checkout ($attribute.EndsWith(': text: unset')) "nearest attributes must disable text conversion: $relative"
    }
  }
  $config = Join-Path $fixtureRoot 'init.toml'
  $overridePath = Join-Path $fixtureRoot 'override.json'
  [IO.File]::WriteAllText($overridePath, (@{ chezmoi = @{ os = 'windows'; homeDir = $target } } | ConvertTo-Json -Depth 10), (New-Object Text.UTF8Encoding($false)))
  $chezmoiArguments = @('--no-tty', '--force', '--refresh-externals=never', '--source', $clone, '--destination', $target, '--config', $config, '--persistent-state', (Join-Path $fixtureRoot 'state.boltdb'), '--override-data-file', $overridePath)
  if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) {
    # init ignores override-data OS; promptStringOnce requires actual init.
    # Only the disposable clone's template receives a Windows-context prefix.
    $prefix = '{{- $_ := set .chezmoi "os" "windows" -}}{{- $_ := set .chezmoi "homeDir" ' + ($target | ConvertTo-Json -Compress) + ' -}}'
    [IO.File]::WriteAllText((Join-Path $clone 'home/.chezmoi.toml.tmpl'), ($prefix + [IO.File]::ReadAllText((Join-Path $RepositoryRoot 'home/.chezmoi.toml.tmpl'))), (New-Object Text.UTF8Encoding($false)))
  }
  $null = Invoke-CheckoutNative chezmoi ($chezmoiArguments + @('init', '--promptString', 'host=korolev'))
  $persisted = Invoke-CheckoutNative chezmoi ($chezmoiArguments + @('dump-config', '--format=json')) | ConvertFrom-Json
  Assert-Checkout ($persisted.interpreters.ps1.command -ceq 'powershell.exe') 'rendered Windows init must select in-box powershell.exe without a pwsh bootstrap dependency'
  Assert-Checkout (($persisted.interpreters.ps1.args -join '|') -ceq '-NoLogo|-NoProfile|-NonInteractive|-ExecutionPolicy|Bypass|-File') 'rendered Windows init interpreter arguments drifted'
  Write-Output 'checkout-regressions: real autocrlf=true clone preserves all included bytes and pinned Zed/Zen hashes; rendered init selects Windows PowerShell'
} finally {
  foreach ($name in $variables) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
  if (Test-Path -LiteralPath $fixtureRoot) { Remove-Item -LiteralPath $fixtureRoot -Recurse -Force }
}
