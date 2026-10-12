BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../Workstation.psm1') -Force
    $script:windowsDirectory = Split-Path $PSScriptRoot -Parent
}

Describe 'Workstation declaration invariants' {
    InModuleScope Workstation {
        BeforeAll {
            $script:declarationDirectory = Split-Path (Get-Module Workstation).Path -Parent
        }

        BeforeEach {
            $script:data = Get-Content -LiteralPath (Join-Path $script:declarationDirectory 'workstation.json') -Raw | ConvertFrom-Json -AsHashtable
            $script:managedPath = Join-Path $script:declarationDirectory 'managed-applications.json'
        }

        It 'accepts the complete 34 application and 27 setting inventory' {
            $script:data.applications.Count | Should -Be 34
            $script:data.settings.Count | Should -Be 27
            @($script:data.applications | Where-Object kind -EQ 'winget').Count | Should -Be 26
            @($script:data.applications | Where-Object kind -EQ 'archive').Count | Should -Be 6
            @($script:data.applications | Where-Object kind -EQ 'npm').Count | Should -Be 1
            @($script:data.applications | Where-Object kind -EQ 'font').Count | Should -Be 1
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Not -Throw
        }

        It 'rejects resource-name collisions across applications and settings case-insensitively' {
            $script:data.settings[0].name = $script:data.applications[0].name.ToUpperInvariant()
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*Duplicate resource name*'
        }

        It 'rejects duplicate application ids case-insensitively' {
            $script:data.applications[1].id = $script:data.applications[0].id.ToUpperInvariant()
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*Duplicate application id*'
        }

        It 'allows machine scope only for the three approved WinGet installers' {
            $script:data.applications[0].scope = 'machine'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*Unapproved machine application*'
        }

        It 'does not allow an archive to impersonate an approved machine installer' {
            $zen = $script:data.applications | Where-Object id -EQ 'Zen-Team.Zen-Browser'
            $zen.kind = 'archive'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*Unapproved machine application*'
        }

        It 'requires the reviewed Docker installer arguments without implicit license consent or a service' {
            $docker = $script:data.applications | Where-Object id -EQ 'Docker.DockerDesktop'
            $docker.installArguments += ' --accept-license'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*Docker Desktop*exactly*'
        }

        It 'rejects installer overrides that could bypass another package scope' {
            $script:data.applications[0].installArguments = '/ALLUSERS'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*only for Docker Desktop*'
        }

        It 'rejects centrally managed applications using the audit rather than a duplicated id list' {
            $managed = Get-Content -LiteralPath $script:managedPath -Raw | ConvertFrom-Json -AsHashtable
            $script:data.applications[0].id = $managed.identifiers[0].ToUpperInvariant()
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*centrally managed*'
        }

        It 'fails closed when the managed audit cannot be read' {
            { Assert-WorkstationData -Data $script:data -ManagedPath (Join-Path $TestDrive 'missing-audit.json') } | Should -Throw
        }

        It 'rejects machine registry writes while permitting only the exact read-only Neo prerequisite' {
            $script:data.settings[0].path = 'HKLM:\Software\Example'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*only HKCU*'
        }

        It 'rejects prohibited registry surfaces' -ForEach @(
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store' }
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband' }
            @{ Path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice' }
            @{ Path = 'HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice' }
            @{ Path = 'HKCU:\Software\Classes\.pdf' }
            @{ Path = 'HKCU:\Software\Classes\Example\shell\open\command' }
        ) {
            $script:data.settings[0].path = $Path
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*Prohibited registry surface*'
        }

        It 'does not permit generic registry writes to the taskbar visibility buffer' {
            $script:data.settings[0].path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*typed taskbarVisibility*'
        }

        It 'restricts the typed taskbar setting to Settings byte 8 equal to 2' {
            $taskbar = $script:data.settings | Where-Object kind -EQ 'taskbarVisibility'
            $taskbar.index = 9
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*only StuckRects3 Settings byte 8 to 2*'
        }

        It 'requires a named consumer for any pin' {
            $script:data.applications[0].versionPolicy = 'pinned'
            $script:data.applications[0].version = '1.0.0'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*named consumer*'
        }

        It 'keeps the Bun consumer pin aligned with omp-agent-setup' {
            $bun = $script:data.applications | Where-Object id -EQ 'Oven-sh.Bun'
            $bun.consumer = 'unrelated consumer'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*Bun must name*'
        }

        It 'keeps the OpenSpec consumer pin aligned with the reusable workflow' {
            $npm = $script:data.applications | Where-Object kind -EQ 'npm'
            $npm.consumer = 'unrelated consumer'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*OpenSpec must name*'
        }

        It 'derives mutable consumer versions from data and accepts synchronized manifest and lock updates' {
            $bun = $script:data.applications | Where-Object id -EQ 'Oven-sh.Bun'
            $bun.version = '9.8.7'
            $npm = $script:data.applications | Where-Object kind -EQ 'npm'
            $npm.version = '9.8.7'
            $npm.manifest.dependencies[$npm.id] = $npm.version
            $npm.lock.packages[''].dependencies[$npm.id] = $npm.version
            $npm.lock.packages["node_modules/$($npm.id)"].version = $npm.version
            $npm.packages[$npm.id].version = $npm.version
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Not -Throw
        }

        It 'rejects an OpenSpec consumer version that differs from the manifest and integrity lock' {
            $npm = $script:data.applications | Where-Object kind -EQ 'npm'
            $npm.version = '9.8.7'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*manifest and integrity lock*'
        }

        It 'requires every stable workstation role' {
            $script:data.applications = @($script:data.applications | Where-Object id -NE 'ZedIndustries.Zed')
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*Missing required application role*editor*'
        }

        It 'rejects duplicate and reassigned role ownership' {
            $script:data.applications[0].roles += 'browser'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*unexpected owner*browser*'
            $script:data.applications[0].roles = @('editor', 'editor')
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*Duplicate application role*editor*'
        }

        It 'requires the declared Node runtime before the npm closure' {
            $node = $script:data.applications | Where-Object id -EQ 'OpenJS.NodeJS.LTS'
            $script:data.applications = @($script:data.applications | Where-Object id -NE 'OpenJS.NodeJS.LTS') + @($node)
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*Node runtime must precede*'
        }

        It 'rejects rooted and traversing installation paths before writes' -ForEach @(
            @{ Field = 'directory'; Path = '..\outside' }
            @{ Field = 'directory'; Path = 'C:\Windows' }
            @{ Field = 'directory'; Path = '\\server\share' }
            @{ Field = 'directory'; Path = 'Programs\.. \outside' }
            @{ Field = 'executable'; Path = '../outside.exe' }
            @{ Field = 'executable'; Path = '\outside.exe' }
            @{ Field = 'payload'; Path = 'payload\..\outside' }
        ) {
            $archive = $script:data.applications | Where-Object id -EQ 'AltSnap.AltSnap'
            $archive[$Field] = $Path
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*safe relative path*'
        }

        It 'rejects a machine filesystem destination root' {
            $archive = $script:data.applications | Where-Object id -EQ 'AltSnap.AltSnap'
            $archive.root = 'WINDIR'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*approved user environment root*'
        }

        It 'keeps archive-owned and preserved files within their installation directory' {
            $archive = $script:data.applications | Where-Object id -EQ 'AltSnap.AltSnap'
            $owned = $archive.ownedFiles
            $archive.ownedFiles = @{ '..\outside.exe' = ('a' * 64) }
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*safe relative path*'
            $archive.ownedFiles = $owned
            $archive.preserveFiles = @('..\outside.ini')
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*safe relative path*'
        }

        It 'keeps font names in the user font directory and npm wrappers in their closure' {
            $font = $script:data.applications | Where-Object kind -EQ 'font'
            $faces = $font.fonts
            $font.fonts = @{ '..\outside.ttf' = @{} }
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*safe relative path*'
            $font.fonts = $faces
            $npm = $script:data.applications | Where-Object kind -EQ 'npm'
            $npm.packages[$npm.id].bin['openspec'] = '..\outside.js'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*safe relative path*'
        }

        It 'rejects Neo first/default and a changed driver prerequisite path' {
            $input = $script:data.settings | Where-Object kind -EQ 'inputMethods'
            $input.ordered = @('0407:b0000407', '0407:00000407')
            $input.default = '0407:b0000407'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*QWERTZ first/default*'
            $input.ordered = @('0407:00000407', '0407:b0000407')
            $input.default = '0407:00000407'
            $input.neoRegistryPath = 'HKLM:\Software\Example'
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*read-only driver prerequisite*'
        }

        It 'requires language convergence before input ordering' {
            $language = $script:data.settings | Where-Object kind -EQ 'language'
            $script:data.settings = @($script:data.settings | Where-Object kind -NE 'language') + @($language)
            { Assert-WorkstationData -Data $script:data -ManagedPath $script:managedPath } | Should -Throw '*language setting must precede*'
        }
    }
}

Describe 'Workstation built-in JSON schema' {
    BeforeAll {
        $script:schema = Get-Content -LiteralPath (Join-Path $script:windowsDirectory 'workstation.schema.json') -Raw
        $script:json = Get-Content -LiteralPath (Join-Path $script:windowsDirectory 'workstation.json') -Raw
    }

    It 'accepts the reviewed declaration with Test-Json' {
        Test-Json -Json $script:json -Schema $script:schema -ErrorAction Stop | Should -BeTrue
    }

    It 'requires typed present registry data and prohibits fields on absent declarations' -ForEach @(
        @{ Resource = @{ name = 'invalid'; kind = 'registry'; path = 'HKCU:\Software\Example'; valueName = 'Example'; ensure = 'present' } }
        @{ Resource = @{ name = 'invalid'; kind = 'registry'; path = 'HKCU:\Software\Example'; valueName = 'Example'; ensure = 'present'; type = 'DWord'; value = '1' } }
        @{ Resource = @{ name = 'invalid'; kind = 'registry'; path = 'HKCU:\Software\Example'; valueName = 'Example'; ensure = 'absent'; type = 'String'; value = 'old' } }
    ) {
        $data = ConvertFrom-Json -InputObject $script:json -AsHashtable
        $data.settings[0] = $Resource
        Test-Json -Json (ConvertTo-Json -InputObject $data -Depth 100) -Schema $script:schema -ErrorAction SilentlyContinue | Should -BeFalse
    }

    It 'rejects unknown executable setting kinds and fields' {
        $data = ConvertFrom-Json -InputObject $script:json -AsHashtable
        $data.settings[0].script = 'Set-ItemProperty HKLM:\Software\Example -Name Example -Value 1'
        Test-Json -Json (ConvertTo-Json -InputObject $data -Depth 100) -Schema $script:schema -ErrorAction SilentlyContinue | Should -BeFalse
        $data.settings[0] = @{ name = 'invalid'; kind = 'script'; script = 'anything' }
        Test-Json -Json (ConvertTo-Json -InputObject $data -Depth 100) -Schema $script:schema -ErrorAction SilentlyContinue | Should -BeFalse
    }
}
