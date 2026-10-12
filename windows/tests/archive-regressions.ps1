[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$RepositoryRoot)
$ErrorActionPreference = 'Stop'
. (Join-Path $RepositoryRoot 'windows/dev/bootstrap.ps1') -RepositoryRoot $RepositoryRoot
$originalProcess = (Get-Item Function:Invoke-NativeProcess).ScriptBlock
$temp = Join-Path ([IO.Path]::GetTempPath()) ('inbox tar with spaces ' + [Guid]::NewGuid().ToString('N'))
$oldPath = $env:PATH
try {
    $shadow = Join-Path $temp 'shadow'
    $input = Join-Path $temp 'input'
    $output = Join-Path $temp 'output'
    $null = New-Item -ItemType Directory -Path $shadow, $input -Force
    $shadowTar = Join-Path $shadow 'tar.exe'
    [IO.File]::WriteAllText($shadowTar, 'This fake PATH tar must never execute.')
    $inboxTar = Join-Path $env:SystemRoot 'System32/tar.exe'
    $env:PATH = $shadow + [IO.Path]::PathSeparator + $oldPath
    $resolvedTar = @(Get-Command tar.exe -CommandType Application)[0].Source
    if ($resolvedTar -cne $shadowTar) { throw "The regression did not put fake tar first on PATH: expected '$shadowTar', found '$resolvedTar'" }
    $payload = [Text.Encoding]::UTF8.GetBytes("fixture payload`n")
    [IO.File]::WriteAllBytes((Join-Path $input 'file.txt'), $payload)
    $archive = Join-Path $temp 'fixture.tar.gz'
        $created = & $originalProcess -Command $inboxTar -Arguments @('-czf', $archive, '-C', $input, 'file.txt')
        if ($created.ExitCode -ne 0) { throw "Cannot create isolated archive: $($created.Output)" }
    $tarCalls = New-Object 'Collections.Generic.List[string]'
    function Invoke-NativeProcess {
        param([string]$Command, [string[]]$Arguments)
        if ($Command -cne $inboxTar) { throw "PATH shadow tar must never run: $Command" }
        $tarCalls.Add($Command)
        return & $originalProcess -Command $Command -Arguments $Arguments
    }
    Expand-NativeArtifact -Artifact ([pscustomobject]@{ kind = 'tar'; file = 'fixture.tar.gz' }) -Path $archive -Destination $output
    if ($tarCalls.Count -ne 2) { throw 'Archive inspection and extraction did not both use inbox tar' }
    if ([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $output 'file.txt'))) -cne [Convert]::ToBase64String($payload)) { throw 'Inbox tar extraction did not preserve payload bytes' }
    Write-Output 'PASS Windows inbox tar archive extraction with fake PATH tar first'
        # A real 7z payload exercises only the engine's private archive extractor.
        # The fixture executable contains text and is never invoked.
        $imageArchive = Join-Path $temp 'ImageMagick fixture.7z'
        [IO.File]::WriteAllBytes((Join-Path $input 'magick.exe'), $payload)
        $created = & $originalProcess -Command $inboxTar -Arguments @('--format=7zip', '-cf', $imageArchive, '-C', $input, 'magick.exe')
        if ($created.ExitCode -ne 0) { throw "Cannot create isolated 7z archive: $($created.Output)" }
        $signature = [IO.File]::ReadAllBytes($imageArchive)
        if ([Convert]::ToBase64String($signature[0..5]) -cne 'N3q8rycc') { throw 'ImageMagick fixture is not an actual 7z archive' }
        $module = Import-Module (Join-Path $RepositoryRoot 'windows/Workstation.psm1') -Force -PassThru
        try {
            $imageOutput = Join-Path $temp 'ImageMagick extracted'
            $null = New-Item -ItemType Directory -Path $imageOutput -Force
            & $module {
                param([string]$Archive, [string]$Destination)
                Expand-WorkstationArchive -Resource @{ archiveKind = '7z' } -Archive $Archive -Destination $Destination
            } $imageArchive $imageOutput
            if ([Convert]::ToBase64String([IO.File]::ReadAllBytes((Join-Path $imageOutput 'magick.exe'))) -cne [Convert]::ToBase64String($payload)) {
                throw 'Workstation actual 7z extraction did not preserve payload bytes'
            }
        } finally { Remove-Module $module }
        Write-Output 'PASS Workstation actual 7z extraction with absolute inbox tar and fake PATH tar first'
} finally {
    $env:PATH = $oldPath
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
