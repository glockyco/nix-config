[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
. (Join-Path $RepositoryRoot 'windows/dev/bootstrap.ps1') -RepositoryRoot $RepositoryRoot
$originalProcess = (Get-Item Function:Invoke-NativeProcess).ScriptBlock
$temp = Join-Path ([IO.Path]::GetTempPath()) ('inbox tar with spaces ' + [Guid]::NewGuid().ToString('N'))
$oldPath = $env:PATH
$oldSystemRoot = $env:SystemRoot
$nativeWindows = [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
try {
    $shadow = Join-Path $temp 'shadow'
    $input = Join-Path $temp 'input'
    $output = Join-Path $temp 'output'
    $null = New-Item -ItemType Directory -Path $shadow, $input -Force
    $shadowTar = Join-Path $shadow 'tar.exe'
    [IO.File]::WriteAllText($shadowTar, 'This fake PATH tar must never execute.')
    if (-not $nativeWindows) {
        & chmod +x $shadowTar
        if ($LASTEXITCODE -ne 0) { throw 'Cannot make the isolated shadow command discoverable' }
        $env:SystemRoot = Join-Path $temp 'windows'
        $null = New-Item -ItemType Directory -Path (Join-Path $env:SystemRoot 'System32') -Force
        [IO.File]::WriteAllText((Join-Path $env:SystemRoot 'System32/tar.exe'), 'inbox tar process double')
    }
    $inboxTar = Join-Path $env:SystemRoot 'System32/tar.exe'
    $env:PATH = $shadow + [IO.Path]::PathSeparator + $oldPath
    $resolvedTar = @(Get-Command tar.exe -CommandType Application)[0].Source
    if ($resolvedTar -cne $shadowTar) { throw "The regression did not put fake tar first on PATH: expected '$shadowTar', found '$resolvedTar'" }
    $payload = [Text.Encoding]::UTF8.GetBytes("fixture payload`n")
    [IO.File]::WriteAllBytes((Join-Path $input 'file.txt'), $payload)
    $archive = Join-Path $temp 'fixture.tar.gz'
    if ($nativeWindows) {
        $created = & $originalProcess -Command $inboxTar -Arguments @('-czf', $archive, '-C', $input, 'file.txt')
        if ($created.ExitCode -ne 0) { throw "Cannot create isolated archive: $($created.Output)" }
    } else { [IO.File]::WriteAllText($archive, 'tar process double archive') }
    $tarCalls = New-Object 'Collections.Generic.List[string]'
    function Invoke-NativeProcess {
        param([string]$Command, [string[]]$Arguments)
        if ($Command -cne $inboxTar) { throw "PATH shadow tar must never run: $Command" }
        $tarCalls.Add($Command)
        if ($nativeWindows) { return & $originalProcess -Command $Command -Arguments $Arguments }
        if ($Arguments[0] -eq '-xzf') { [IO.File]::WriteAllBytes((Join-Path $Arguments[3] 'file.txt'), $payload) }
        return [pscustomobject]@{ ExitCode = 0; Output = 'file.txt' }
    }
    Expand-NativeArtifact -Artifact ([pscustomobject]@{ kind = 'tar'; file = 'fixture.tar.gz' }) -Path $archive -Destination $output
    if ($tarCalls.Count -ne 2) { throw 'Archive inspection and extraction did not both use inbox tar' }
    if ([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $output 'file.txt'))) -cne [Convert]::ToBase64String($payload)) { throw 'Inbox tar extraction did not preserve payload bytes' }
    Write-Output 'PASS Windows inbox tar archive extraction with fake PATH tar first'
    if ($nativeWindows) {
        # A real 7z payload exercises the shipped ImageMagick extractor, not a ZIP
        # renamed to .7z. Only extraction uses native code; no tool is installed/run.
        $imageArchive = Join-Path $temp 'ImageMagick fixture.7z'
        [IO.File]::WriteAllBytes((Join-Path $input 'magick.exe'), $payload)
        $created = & $originalProcess -Command $inboxTar -Arguments @('--format=7zip', '-cf', $imageArchive, '-C', $input, 'magick.exe')
        if ($created.ExitCode -ne 0) { throw "Cannot create isolated 7z archive: $($created.Output)" }
        $signature = [IO.File]::ReadAllBytes($imageArchive)
        if ([Convert]::ToBase64String($signature[0..5]) -cne 'N3q8rycc') { throw 'ImageMagick fixture is not an actual 7z archive' }
        . (Join-Path $RepositoryRoot 'windows/tests/native-contract.ps1')
        . (Join-Path $RepositoryRoot 'windows/tests/installer-doubles.ps1')
        $document = [IO.File]::ReadAllText((Join-Path $RepositoryRoot 'windows/configuration.winget')) | ConvertFrom-Json
        $imageResources = @($document.resources | Where-Object { $_.metadata.application.id -eq 'ImageMagick.ImageMagick' })
        Assert-Contract ($imageResources.Count -eq 1) 'ImageMagick actual 7z fixture: required archive resource is missing or ambiguous'
        Invoke-InstallerFixture -Resource $imageResources[0] -Scenario 'missing' -Root $temp -ArchivePath $imageArchive
        Write-Output 'PASS ImageMagick actual 7z extraction with absolute inbox tar and fake PATH tar first'
    }
} finally {
    $env:PATH = $oldPath
    $env:SystemRoot = $oldSystemRoot
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
