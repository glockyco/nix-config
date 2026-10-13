BeforeDiscovery {
  Import-Module (Join-Path $PSScriptRoot '../Workstation.psm1') -Force
}

Describe 'Workstation delivery safety and convergence' {
  InModuleScope Workstation {
    BeforeEach {
      $script:directory = Join-Path $TestDrive 'application'
      $script:context = @{ Installed = @{}; Data = @{ applications = @(@{ id = 'OpenJS.NodeJS.LTS'; executable = 'node.exe'; kind = 'winget'; scope = 'user' }) } }
      Mock Get-WorkstationApplicationDirectory { $script:directory }
      Mock Test-WorkstationUserPath { $true }
      Mock Set-WorkstationUserPath {}
      Mock Invoke-WebRequest { throw 'Unexpected download' }
      Mock New-Item {}
      Mock New-ItemProperty {}
      Mock Remove-Item {}
      Mock Move-Item {}
      Mock Copy-Item {}
      Mock Stop-Process {}
      Mock Start-Process {}
      Mock Get-Process { [Diagnostics.Process]::new() }
      Mock Register-WorkstationFont {}
    }

    Context 'Reviewed archives' {
      BeforeEach {
        $script:resource = @{ id = 'Example.Archive'; kind = 'archive'; executable = 'tool.exe'; releaseVersion = '7.1.2-33'; versionSource = 'command'; versionArgs = @('--version'); archiveKind = 'zip'; payload = '.'; url = 'https://example.test/archive.zip'; sha256 = 'reviewed' }
        Mock Test-Path { $true }
        Mock Invoke-WorkstationNative { 'Example 7.1.2-33' }
      }

      It 'accepts a newer four-component hyphenated executable without downloads or writes' {
        Mock Invoke-WorkstationNative { 'Example 7.1.2-34 Q16-HDRI' }
        Test-WorkstationArchive -Resource $script:resource -Context $script:context | Should -BeTrue
        Set-WorkstationArchive -Resource $script:resource -Context $script:context
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke New-Item -Times 0 -Exactly
        Should -Invoke Move-Item -Times 0 -Exactly
        Should -Invoke Set-WorkstationUserPath -Times 0 -Exactly
        Should -Invoke Stop-Process -Times 0 -Exactly
      }

      It 'reports a missing executable as drift without creating even temporary output' {
        Mock Test-Path { $false }
        Test-WorkstationArchive -Resource $script:resource -Context $script:context | Should -BeFalse
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke New-Item -Times 0 -Exactly
        Should -Invoke Invoke-WorkstationNative -Times 0 -Exactly
        Should -Invoke Set-WorkstationUserPath -Times 0 -Exactly
      }

      It 'repairs only PATH when the installed payload is already accepted' {
        Mock Test-WorkstationUserPath { $false }
        Test-WorkstationArchive -Resource $script:resource -Context $script:context | Should -BeFalse
        Set-WorkstationArchive -Resource $script:resource -Context $script:context
        Should -Invoke Set-WorkstationUserPath -Times 1 -Exactly -ParameterFilter { $Directory -eq $script:directory }
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke Move-Item -Times 0 -Exactly
      }

      It 'rejects an unreadable installed version instead of overwriting it' {
        Mock Invoke-WorkstationNative { 'unrecognized version' }
        { Set-WorkstationArchive -Resource $script:resource -Context $script:context } | Should -Throw '*cannot establish executable version*'
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke Move-Item -Times 0 -Exactly
      }

      It 'verifies the download hash before extraction or process termination' {
        $script:resource.process = 'AltSnap'
        Mock Test-WorkstationArchivePayload { $false }
        Mock Test-Path { $false }
        Mock Invoke-WebRequest {}
        Mock Test-WorkstationFileHash { $false }
        Mock Expand-WorkstationArchive {}
        { Set-WorkstationArchive -Resource $script:resource -Context $script:context } | Should -Throw '*archive checksum mismatch*'
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly
        Should -Invoke Expand-WorkstationArchive -Times 0 -Exactly
        Should -Invoke Stop-Process -Times 0 -Exactly
        Should -Invoke Move-Item -Times 0 -Exactly
      }


      It 'keeps the previous install when committing a verified staged payload' {
        Mock Test-WorkstationArchivePayload { $Directory -ne $script:directory }
        Mock Test-Path { $LiteralPath -eq $script:directory }
        Mock Save-WorkstationDownload {}
        Mock Expand-WorkstationArchive {}
        Set-WorkstationArchive -Resource $script:resource -Context $script:context
        Should -Invoke Move-Item -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $script:directory -and $Destination -like "$script:directory.previous-*" }
        Should -Invoke Move-Item -Times 1 -Exactly -ParameterFilter { $Destination -eq $script:directory }
        Should -Invoke Remove-Item -Times 0 -Exactly -ParameterFilter { $LiteralPath -like '*.previous-*' }
      }

      It 'restores the old directory from retained recovery data if promotion fails' {
        $script:previousMoved = $false
        Mock Test-WorkstationArchivePayload { $Directory -ne $script:directory }
        Mock Test-Path { $LiteralPath -eq $script:directory -and -not $script:previousMoved }
        Mock Save-WorkstationDownload {}
        Mock Expand-WorkstationArchive {}
        Mock Move-Item {
          if ($LiteralPath -eq $script:directory) { $script:previousMoved = $true }
          if ($Destination -eq $script:directory) { throw 'promotion failed' }
        }
        { Set-WorkstationArchive -Resource $script:resource -Context $script:context } | Should -Throw '*promotion failed*'
        Should -Invoke Copy-Item -Times 1 -Exactly -ParameterFilter { $LiteralPath -like "$script:directory.previous-*" -and $Destination -eq $script:directory }
        Should -Invoke Remove-Item -Times 0 -Exactly -ParameterFilter { $LiteralPath -like '*.previous-*' }
      }

      It 'copies only AltSnap owned binaries into a preserved installation and stops only after verification' {
        $script:resource.ownedFiles = @{ 'AltSnap.exe' = 'exe-hash'; 'hooks.dll' = 'dll-hash' }
        $script:resource.executable = 'AltSnap.exe'
        $script:resource.preserveFiles = @('AltSnap.ini')
        $script:resource.process = 'AltSnap'
        $script:verified = $false
        Mock Test-WorkstationArchivePayload {
          if ($Directory -ne $script:directory) { $script:verified = $true; return $true }
          return $false
        }
        Mock Test-Path { $LiteralPath -eq $script:directory }
        Mock Save-WorkstationDownload {}
        Mock Expand-WorkstationArchive {}
        Mock Test-WorkstationFileHash { $true }
        Mock Stop-Process { if (-not $script:verified) { throw 'stopped before verification' } }
        Set-WorkstationArchive -Resource $script:resource -Context $script:context
        Should -Invoke Copy-Item -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $script:directory -and $Recurse }
        Should -Invoke Copy-Item -Times 2 -Exactly -ParameterFilter { $LiteralPath -like '*expanded*' -and $Force -and (Split-Path -Leaf $LiteralPath) -in @('AltSnap.exe', 'hooks.dll') }
        Should -Invoke Copy-Item -Times 0 -Exactly -ParameterFilter { $LiteralPath -like '*expanded*AltSnap.ini' }
        Should -Invoke Stop-Process -Times 1 -Exactly
        Should -Invoke Start-Process -Times 1 -Exactly
      }

      It 'accepts exact owned hashes without launching the executable or stopping the application' {
        $script:resource.ownedFiles = @{ 'AltSnap.exe' = 'exe-hash'; 'hooks.dll' = 'dll-hash' }
        $script:resource.executable = 'AltSnap.exe'
        $script:resource.process = 'AltSnap'
        Mock Test-WorkstationFileHash { $true }
        Test-WorkstationArchive -Resource $script:resource -Context $script:context | Should -BeTrue
        Set-WorkstationArchive -Resource $script:resource -Context $script:context
        Should -Invoke Invoke-WorkstationNative -Times 0 -Exactly
        Should -Invoke Stop-Process -Times 0 -Exactly
        Should -Invoke Copy-Item -Times 0 -Exactly
      }

      It 'accepts newer AltSnap bytes but refuses replacement when its owned DLL is absent' {
        $script:resource.ownedFiles = @{ 'AltSnap.exe' = 'exe-hash'; 'hooks.dll' = 'dll-hash' }
        $script:resource.executable = 'AltSnap.exe'
        Mock Test-WorkstationFileHash { $false }
        Mock Invoke-WorkstationNative { 'AltSnap 7.1.2-34' }
        Test-WorkstationArchive -Resource $script:resource -Context $script:context | Should -BeTrue
        Mock Test-Path { $LiteralPath -notlike '*hooks.dll' }
        { Set-WorkstationArchive -Resource $script:resource -Context $script:context } | Should -Throw '*refusing replacement of newer installed version*'
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke Stop-Process -Times 0 -Exactly
      }
    }

    Context 'Reviewed gallery modules' {
      BeforeEach {
        # TestDrive persists across tests in a context, so each test gets its own module root.
        $script:moduleRoot = Join-Path $TestDrive ('Modules-' + [guid]::NewGuid().ToString('N'))
        $script:resource = @{ id = 'Example.Module'; kind = 'psmodule'; releaseVersion = '2.7.12'; url = 'https://www.powershellgallery.com/api/v2/package/Example.Module/2.7.12'; sha256 = 'reviewed' }
        $script:destination = Join-Path $script:moduleRoot 'Example.Module\2.7.12'
        Mock Get-WorkstationModuleRoot { $script:moduleRoot }
        Mock Expand-Archive { throw 'Unexpected extraction' }
        function script:Write-ExampleModule([string]$Directory, [string]$Version) {
          [void][IO.Directory]::CreateDirectory($Directory)
          [IO.File]::WriteAllText((Join-Path $Directory 'Example.Module.psd1'), "@{ ModuleVersion = '$Version' }")
        }
      }

      It 'reports a missing module as drift without downloading or writing' {
        Test-WorkstationPsModule -Resource $script:resource -Context $script:context | Should -BeFalse
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke New-Item -Times 0 -Exactly
      }

      It 'reports an older module as drift' {
        Write-ExampleModule (Join-Path $script:moduleRoot 'Example.Module\2.7.0') '2.7.0'
        Test-WorkstationPsModule -Resource $script:resource -Context $script:context | Should -BeFalse
      }

      It 'ignores a version folder whose manifest disagrees with it' {
        Write-ExampleModule (Join-Path $script:moduleRoot 'Example.Module\2.8.0') '2.6.0'
        Test-WorkstationPsModule -Resource $script:resource -Context $script:context | Should -BeFalse
      }

      It 'accepts a newer module without downloads, writes or PATH changes' {
        Write-ExampleModule (Join-Path $script:moduleRoot 'Example.Module\2.7.0') '2.7.0'
        Write-ExampleModule (Join-Path $script:moduleRoot 'Example.Module\2.8.0') '2.8.0'
        Test-WorkstationPsModule -Resource $script:resource -Context $script:context | Should -BeTrue
        Set-WorkstationPsModule -Resource $script:resource -Context $script:context
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke Move-Item -Times 0 -Exactly
        Should -Invoke Set-WorkstationUserPath -Times 0 -Exactly
      }

      It 'refuses an existing destination without a matching manifest before downloading' {
        [void][IO.Directory]::CreateDirectory($script:destination)
        { Set-WorkstationPsModule -Resource $script:resource -Context $script:context } | Should -Throw '*Owner review is required*'
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
      }

      It 'verifies the package hash before extraction' {
        Mock Invoke-WebRequest {}
        Mock Test-WorkstationFileHash { $false }
        { Set-WorkstationPsModule -Resource $script:resource -Context $script:context } | Should -Throw '*archive checksum mismatch*'
        Should -Invoke Invoke-WebRequest -Times 1 -Exactly
        Should -Invoke Expand-Archive -Times 0 -Exactly
        Should -Invoke Move-Item -Times 0 -Exactly
      }

      It 'rejects a package whose manifest version differs from the declaration' {
        Mock Save-WorkstationDownload {}
        Mock Expand-Archive { Write-ExampleModule $DestinationPath '2.7.11' }
        { Set-WorkstationPsModule -Resource $script:resource -Context $script:context } | Should -Throw '*manifest version 2.7.11 differs*'
        Should -Invoke Move-Item -Times 0 -Exactly
      }

      It 'strips NuGet packaging entries and promotes the verified module beside older versions' {
        Write-ExampleModule (Join-Path $script:moduleRoot 'Example.Module\2.7.0') '2.7.0'
        Mock Save-WorkstationDownload {}
        Mock Expand-Archive {
          Write-ExampleModule $DestinationPath '2.7.12'
          foreach ($directory in @('_rels', 'package')) { [void][IO.Directory]::CreateDirectory((Join-Path $DestinationPath $directory)) }
          foreach ($file in @('[Content_Types].xml', 'Example.Module.nuspec')) { [IO.File]::WriteAllText((Join-Path $DestinationPath $file), '') }
        }
        Set-WorkstationPsModule -Resource $script:resource -Context $script:context
        Should -Invoke Remove-Item -Times 4 -Exactly -ParameterFilter { (Split-Path -Leaf $LiteralPath) -in @('_rels', 'package', '[Content_Types].xml', 'Example.Module.nuspec') }
        Should -Invoke Move-Item -Times 1 -Exactly -ParameterFilter { $Destination -eq $script:destination }
        Should -Invoke Remove-Item -Times 0 -Exactly -ParameterFilter { $LiteralPath -like '*2.7.0*' }
        Should -Invoke Set-WorkstationUserPath -Times 0 -Exactly
      }
    }

    Context 'Integrity-locked npm closure' {
      BeforeEach {
        $script:node = Join-Path $TestDrive 'node\node.exe'
        $script:resource = @{ id = '@fission-ai/openspec'; kind = 'npm'; versionPolicy = 'pinned'; version = '1.14.0'; nodeId = 'OpenJS.NodeJS.LTS'; source = 'npm' }
        Mock Resolve-WorkstationExecutable { $script:node }
        Mock Get-WorkstationNpmLockHash { 'reviewed-lock' }
        Mock Test-Path { $true }
        Mock Get-Content { 'reviewed-lock' }
        Mock Invoke-WorkstationNative {}
      }

      It 'accepts the closure installed from the current lock without running npm' {
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeTrue
        Set-WorkstationNpm -Resource $script:resource -Context $script:context
        Should -Invoke Invoke-WorkstationNative -Times 0 -Exactly
        Should -Invoke New-Item -Times 0 -Exactly
      }

      It 'reports drift when the installed closure came from another lock or has no marker' {
        Mock Get-Content { 'previous-lock' }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
        Mock Test-Path { $LiteralPath -notlike '*.workstation-lock.sha256' }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
      }

      It 'reports missing Node or adjacent npm as drift' {
        Mock Resolve-WorkstationExecutable { $null }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
        Mock Resolve-WorkstationExecutable { $script:node }
        Mock Test-Path { $LiteralPath -notlike '*npm.cmd' }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
      }

      It 'repairs only PATH when the closure matches the lock' {
        Mock Test-WorkstationUserPath { $false }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
        Set-WorkstationNpm -Resource $script:resource -Context $script:context
        Should -Invoke Set-WorkstationUserPath -Times 1 -Exactly
        Should -Invoke Invoke-WorkstationNative -Times 0 -Exactly
      }

      It 'installs the repository lock with npm ci in staging and promotes it with a marker' {
        Mock Get-Content { 'previous-lock' }
        Mock New-Item { [void][IO.Directory]::CreateDirectory($Path) }
        Set-WorkstationNpm -Resource $script:resource -Context $script:context
        Should -Invoke Copy-Item -Times 2 -Exactly -ParameterFilter { $Destination -like "$script:directory.installing-*" }
        Should -Invoke Invoke-WorkstationNative -Times 1 -Exactly -ParameterFilter {
          $Command -eq (Join-Path (Split-Path -Parent $script:node) 'npm.cmd') -and
          $Arguments[0] -eq 'ci' -and $Arguments[2] -like "$script:directory.installing-*" -and
          ($Arguments[3..5] -join '|') -eq '--ignore-scripts|--no-audit|--no-fund'
        }
        Should -Invoke Move-Item -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $script:directory -and $Destination -like '*.previous-*' }
        Should -Invoke Move-Item -Times 1 -Exactly -ParameterFilter { $Destination -eq $script:directory }
        Should -Invoke Set-WorkstationUserPath -Times 1 -Exactly
        $marker = @(Get-ChildItem -LiteralPath $TestDrive -Recurse -Filter '.workstation-lock.sha256')
        $marker.Count | Should -Be 1
        [IO.File]::ReadAllText($marker[0].FullName) | Should -Be 'reviewed-lock'
      }

      It 'propagates npm failure without touching the existing closure or PATH' {
        Mock Get-Content { 'previous-lock' }
        Mock New-Item { [void][IO.Directory]::CreateDirectory($Path) }
        Mock Invoke-WorkstationNative { throw 'npm exited 1' }
        { Set-WorkstationNpm -Resource $script:resource -Context $script:context } | Should -Throw '*npm exited 1*'
        Should -Invoke Move-Item -Times 0 -Exactly
        Should -Invoke Set-WorkstationUserPath -Times 0 -Exactly
      }
    }

    Context 'Non-destructive user fonts' {
      BeforeEach {
        $script:resource = @{ id = 'Example.Font'; kind = 'font'; archiveKind = 'zip'; url = 'https://example.test/fonts.zip'; sha256 = 'archive'; fonts = @{ 'Regular.ttf' = @{ registryName = 'Example NF (TrueType)'; sha256 = 'face' }; 'Bold.ttf' = @{ registryName = 'Example NF Bold (TrueType)'; sha256 = 'bold-face' } } }
        $script:fontDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
        $script:fontRegistry = [pscustomobject]@{
          'Example NF (TrueType)' = (Join-Path $script:fontDirectory 'Regular.ttf')
          'Example NF Bold (TrueType)' = (Join-Path $script:fontDirectory 'Bold.ttf')
          'Unrelated Font (TrueType)' = 'unrelated.ttf'
        }
        Mock Get-ItemProperty { $script:fontRegistry }
        Mock Get-WorkstationFontFamilies { @('Example NF') }
        Mock Test-Path { $true }
        Mock Test-WorkstationFileHash { $true }
        Mock Remove-ItemProperty { throw 'No registry deletion is permitted' }
      }

      It 'validates existing bytes, registration and loaded family without downloading or writing' {
        Test-WorkstationFont -Resource $script:resource -Context $script:context | Should -BeTrue
        Set-WorkstationFont -Resource $script:resource -Context $script:context
        Should -Invoke Test-WorkstationFileHash -Times 4 -Exactly
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke New-ItemProperty -Times 0 -Exactly
        Should -Invoke Register-WorkstationFont -Times 0 -Exactly
      }

      It 'refuses different existing bytes before download, registration or replacement' {
        Mock Test-WorkstationFileHash { $false }
        { Set-WorkstationFont -Resource $script:resource -Context $script:context } | Should -Throw '*existing font bytes differ*'
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke Copy-Item -Times 0 -Exactly
        Should -Invoke New-ItemProperty -Times 0 -Exactly
      }

      It 'refuses a conflicting registration instead of overwriting it' {
        $script:fontRegistry.'Example NF (TrueType)' = 'C:\Other\Regular.ttf'
        { Set-WorkstationFont -Resource $script:resource -Context $script:context } | Should -Throw '*registration conflicts*'
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke New-ItemProperty -Times 0 -Exactly
      }

      It 'repairs absent registration and loads matching existing faces without downloading' {
        Mock Get-ItemProperty { $null }
        Set-WorkstationFont -Resource $script:resource -Context $script:context
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke Copy-Item -Times 0 -Exactly
        Should -Invoke New-ItemProperty -Times 2 -Exactly -ParameterFilter { $LiteralPath -like 'HKCU:*' -and $PropertyType -eq 'String' -and $Name -in @('Example NF (TrueType)', 'Example NF Bold (TrueType)') }
        Should -Invoke Register-WorkstationFont -Times 2 -Exactly
        Should -Invoke Remove-ItemProperty -Times 0 -Exactly
        Should -Invoke Remove-Item -Times 0 -Exactly -ParameterFilter { $LiteralPath -like '*Microsoft\Windows\Fonts*' }
      }

      It 'checks every extracted face before copying any missing face and preserves unrelated fonts' {
        Mock Get-ItemProperty { $null }
        Mock Test-Path { $false }
        Mock Save-WorkstationDownload {}
        Mock Expand-WorkstationArchive {}
        Mock Test-WorkstationFileHash { $Path -notlike '*Bold.ttf' }
        { Set-WorkstationFont -Resource $script:resource -Context $script:context } | Should -Throw '*extracted font checksum mismatch*'
        Should -Invoke Copy-Item -Times 0 -Exactly
        Should -Invoke New-ItemProperty -Times 0 -Exactly
        Should -Invoke Remove-ItemProperty -Times 0 -Exactly
      }

      It 'installs only missing reviewed faces and registers them through HKCU and the native loader' {
        Mock Get-ItemProperty { $null }
        Mock Test-Path { $false }
        Mock Save-WorkstationDownload {}
        Mock Expand-WorkstationArchive {}
        Set-WorkstationFont -Resource $script:resource -Context $script:context
        Should -Invoke Copy-Item -Times 2 -Exactly -ParameterFilter { -not $Force -and (Split-Path -Leaf $LiteralPath) -in @('Regular.ttf', 'Bold.ttf') }
        Should -Invoke New-ItemProperty -Times 2 -Exactly -ParameterFilter { $LiteralPath -eq 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts' }
        Should -Invoke Register-WorkstationFont -Times 2 -Exactly
        Should -Invoke Remove-ItemProperty -Times 0 -Exactly
      }
    }
  }
}
