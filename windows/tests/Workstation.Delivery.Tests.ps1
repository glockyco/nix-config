BeforeAll {
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

      It 'extracts 7z only through the absolute inbox tar executable' {
        $script:resource.archiveKind = '7z'
        Expand-WorkstationArchive -Resource $script:resource -Archive 'C:\temporary\payload.7z' -Destination 'C:\temporary\expanded'
        Should -Invoke Invoke-WorkstationNative -Times 1 -Exactly -ParameterFilter {
          $Command -eq (Join-Path $env:SystemRoot 'System32\tar.exe') -and
          ($Arguments -join '|') -eq '-xf|C:\temporary\payload.7z|-C|C:\temporary\expanded'
        }
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

    Context 'Integrity-locked npm closure' {
      BeforeEach {
        $script:node = Join-Path $TestDrive 'node\node.exe'
        $script:resource = @{
          id = '@fission-ai/openspec'; kind = 'npm'; versionPolicy = 'pinned'; version = '1.14.0'; nodeId = 'OpenJS.NodeJS.LTS'
          manifest = @{ name = 'tools'; private = $true; dependencies = @{ '@fission-ai/openspec' = '1.14.0' } }
          lock = @{ lockfileVersion = 3; packages = @{ '' = @{ name = 'tools' }; 'node_modules/@fission-ai/openspec' = @{ version = '1.14.0'; integrity = 'sha512-reviewed' }; 'node_modules/dependency' = @{ version = '2.0.0'; integrity = 'sha512-transitive' } } }
          packages = @{ '@fission-ai/openspec' = @{ version = '1.14.0'; integrity = 'sha512-reviewed'; bin = @{ openspec = 'bin/openspec.js' } } }
        }
        Mock Resolve-WorkstationExecutable { $script:node }
        Mock Test-Path { $true }
        Mock Read-WorkstationJsonFile {
          if ($Path -eq (Join-Path $script:directory 'package.json')) { return $script:resource.manifest }
          if ($Path -eq (Join-Path $script:directory 'package-lock.json')) { return $script:resource.lock }
          if ($Path.Replace('\', '/') -like '*dependency/package.json') { return @{ version = '2.0.0' } }
          return @{ version = '1.14.0'; bin = @{ openspec = 'bin/openspec.js' } }
        }
        Mock Get-Content { '../@fission-ai/openspec/bin/openspec.js' }
        Mock Invoke-WorkstationNative { '1.14.0' }
      }

      It 'checks the complete lock, all installed closure manifests, bin targets and Windows wrappers' {
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeTrue
        Should -Invoke Read-WorkstationJsonFile -Times 1 -Exactly -ParameterFilter { $Path.Replace('\', '/') -like '*dependency/package.json' }
        Should -Invoke Get-Content -Times 3 -Exactly
        Should -Invoke Invoke-WorkstationNative -Times 1 -Exactly -ParameterFilter { $Command -eq $script:node -and $Arguments[0].Replace('\', '/') -like '*bin/openspec.js' -and $Arguments[1] -eq '--version' }
        Should -Invoke Invoke-WebRequest -Times 0 -Exactly
        Should -Invoke New-Item -Times 0 -Exactly
        Should -Invoke Set-WorkstationUserPath -Times 0 -Exactly
      }

      It 'reports a changed transitive integrity lock as drift' {
        Mock Read-WorkstationJsonFile {
          if ($Path -like '*package-lock.json') { return @{ lockfileVersion = 3; packages = @{} } }
          return $script:resource.manifest
        }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
        Should -Invoke Invoke-WorkstationNative -Times 0 -Exactly
        Should -Invoke New-Item -Times 0 -Exactly
      }

      It 'reports a missing PowerShell wrapper and a misdirected wrapper as drift' {
        Mock Test-Path { $LiteralPath -notlike '*openspec.ps1' }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
        Mock Test-Path { $true }
        Mock Get-Content { '../wrong-package/bin/tool.js' }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
      }

      It 'reports missing Node or adjacent npm as drift without writes' {
        Mock Resolve-WorkstationExecutable { $null }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
        Mock Resolve-WorkstationExecutable { $script:node }
        Mock Test-Path { $LiteralPath -notlike '*npm.cmd' }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
        Should -Invoke New-Item -Times 0 -Exactly
        Should -Invoke Set-WorkstationUserPath -Times 0 -Exactly
      }

      It 'refuses a newer pinned OpenSpec before creating staging files or invoking npm ci' {
        Mock Test-WorkstationNpmPayload { $false }
        Mock Read-WorkstationJsonFile { @{ version = '1.15.0' } }
        { Set-WorkstationNpm -Resource $script:resource -Context $script:context } | Should -Throw '*refusing downgrade*1.15.0*'
        Should -Invoke New-Item -Times 0 -Exactly
        Should -Invoke Invoke-WorkstationNative -Times 0 -Exactly
        Should -Invoke Move-Item -Times 0 -Exactly
      }

      It 'does not reinstall a valid closure when only the user PATH entry is absent' {
        Mock Test-WorkstationUserPath { $false }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeFalse
        Set-WorkstationNpm -Resource $script:resource -Context $script:context
        Should -Invoke Set-WorkstationUserPath -Times 1 -Exactly
        Should -Invoke Invoke-WorkstationNative -Times 0 -Exactly -ParameterFilter { $Arguments[0] -eq 'ci' }
        Should -Invoke New-Item -Times 0 -Exactly
      }

      It 'installs into staging with adjacent npm ci and promotes only a verified closure' {
        Mock Test-Path { $LiteralPath -like '*npm.cmd' -or $LiteralPath -eq $script:directory }
        Mock Test-WorkstationNpmPayload { $Directory -ne $script:directory }
        Mock New-Item { [void][IO.Directory]::CreateDirectory($Path) }
        Mock Invoke-WorkstationNative {
          $prefix = $Arguments[2]
          (Read-WorkstationJsonFile -Path (Join-Path $prefix 'package.json')).name | Should -Be 'tools'
          (Get-Content -LiteralPath (Join-Path $prefix 'package-lock.json') -Raw | ConvertFrom-Json -AsHashtable).lockfileVersion | Should -Be 3
        }
        # Only staging files inside TestDrive use the actual filesystem.
        Mock Read-WorkstationJsonFile { Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json -AsHashtable }
        Mock Get-Content { [IO.File]::ReadAllText($LiteralPath) }
        Set-WorkstationNpm -Resource $script:resource -Context $script:context
        Should -Invoke Invoke-WorkstationNative -Times 1 -Exactly -ParameterFilter {
          $Command -eq (Join-Path (Split-Path -Parent $script:node) 'npm.cmd') -and
          $Arguments[0] -eq 'ci' -and $Arguments[1] -eq '--prefix' -and
          $Arguments[2] -like "$script:directory.installing-*" -and
          ($Arguments[3..5] -join '|') -eq '--ignore-scripts|--no-audit|--no-fund'
        }
        Should -Invoke Move-Item -Times 1 -Exactly -ParameterFilter { $LiteralPath -eq $script:directory -and $Destination -like '*.previous-*' }
        Should -Invoke Move-Item -Times 1 -Exactly -ParameterFilter { $Destination -eq $script:directory }
        Should -Invoke Remove-Item -Times 0 -Exactly -ParameterFilter { $LiteralPath -like '*.previous-*' }
      }

      It 'propagates npm failure without touching the existing closure or PATH' {
        Mock Test-Path { $LiteralPath -like '*npm.cmd' -or $LiteralPath -eq $script:directory }
        Mock Test-WorkstationNpmPayload { $false }
        Mock New-Item { [void][IO.Directory]::CreateDirectory($Path) }
        Mock Invoke-WorkstationNative { throw 'npm exited 1' }
        { Set-WorkstationNpm -Resource $script:resource -Context $script:context } | Should -Throw '*npm exited 1*'
        Should -Invoke Move-Item -Times 0 -Exactly
        Should -Invoke Set-WorkstationUserPath -Times 0 -Exactly
      }

      It 'omits only explicitly incompatible optional dependencies from manifest checks' {
        $script:resource.lock.packages['node_modules/platform-darwin'] = @{ version = '1.0.0'; optional = $true; os = @('darwin') }
        Mock Test-Path { $LiteralPath -notlike '*platform-darwin*' }
        Test-WorkstationNpm -Resource $script:resource -Context $script:context | Should -BeTrue
        Should -Invoke Read-WorkstationJsonFile -Times 0 -Exactly -ParameterFilter { $Path -like '*platform-darwin*' }
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
