BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\Workstation.psm1') -Force
}

Describe 'WinGet snapshot and installation' {
    InModuleScope Workstation {
        BeforeEach {
            $resource = @{ name = 'tool'; kind = 'winget'; id = 'Vendor.Tool'; scope = 'user'; versionPolicy = 'present' }
            $context = @{ Installed = @{}; WingetChanged = $false }
            Mock Invoke-WorkstationNative { '' }
            Mock Update-WorkstationProcessPath {}
        }

        It 'parses one localized batch including Pandoc without a scope filter' {
            $data = @{ applications = @($resource, @{ kind = 'winget'; id = 'JohnMacFarlane.Pandoc' }) }
            Mock Invoke-WorkstationNative { "Name Id Version Verfugbar Quelle`n----------------------------------------`nTool Vendor.Tool 2.0 3.0 winget`nPandoc JohnMacFarlane.Pandoc 3.12.1 winget" }
            $snapshot = Get-WorkstationWingetSnapshot -Data $data
            $snapshot['Vendor.Tool'] | Should -Be '2.0'
            $snapshot['JohnMacFarlane.Pandoc'] | Should -Be '3.12.1'
            Should -Invoke Invoke-WorkstationNative -Times 1 -Exactly -ParameterFilter { $Arguments[0] -eq 'list' -and $Arguments -notcontains '--scope' -and $Arguments -notcontains '--upgrade-available' }
        }

        It 'rejects duplicate installed records rather than selecting one' {
            Mock Invoke-WorkstationNative { "Name Id Version`n--------------------------`nTool Vendor.Tool 2.0`nOther Vendor.Tool 2.1" }
            { Get-WorkstationWingetSnapshot -Data @{ applications = @($resource) } } | Should -Throw '*Ambiguous*'
        }

        It 'rejects truncated declared ids and an unrecognized snapshot' {
            Mock Invoke-WorkstationNative { "Name Id Version`n--------------------------`nTool Vendor.To... 2.0" }
            { Get-WorkstationWingetSnapshot -Data @{ applications = @($resource) } } | Should -Throw '*Truncated*'
            Mock Invoke-WorkstationNative { 'not a table' }
            { Get-WorkstationWingetSnapshot -Data @{ applications = @($resource) } } | Should -Throw '*separator*'
        }

        It 'accepts existing present applications without querying upgrades' {
            $context.Installed['Vendor.Tool'] = '9.0'
            Test-WorkstationWinget -Resource $resource -Context $context | Should -BeTrue
            Set-WorkstationWinget -Resource $resource -Context $context
            Should -Invoke Invoke-WorkstationNative -Times 0 -Exactly
        }

        It 'installs explicitly in user scope without competing dependencies' {
            Set-WorkstationWinget -Resource $resource -Context $context
            Should -Invoke Invoke-WorkstationNative -Times 1 -Exactly -ParameterFilter {
                $Command -eq 'winget' -and $Arguments[0] -eq 'install' -and
                $Arguments[$Arguments.IndexOf('--scope') + 1] -eq 'user' -and
                $Arguments -contains '--skip-dependencies' -and $Arguments -notcontains '--version'
            }
            $context.WingetChanged | Should -BeTrue
        }

        It 'uses the exact reviewed machine installer override' {
            $resource.id = 'Docker.DockerDesktop'
            $resource.scope = 'machine'
            $resource.installArguments = 'install --quiet --backend=wsl-2 --no-windows-containers'
            Set-WorkstationWinget -Resource $resource -Context $context
            Should -Invoke Invoke-WorkstationNative -Times 1 -Exactly -ParameterFilter {
                $Arguments[$Arguments.IndexOf('--scope') + 1] -eq 'machine' -and
                $Arguments[$Arguments.IndexOf('--override') + 1] -eq 'install --quiet --backend=wsl-2 --no-windows-containers'
            }
        }

        It 'reports a newer pin as drift and refuses downgrade' {
            $resource.versionPolicy = 'pinned'
            $resource.version = '1.3.13'
            $resource.executable = 'bun.exe'
            $context.Installed['Vendor.Tool'] = '1.3.13'
            Mock Resolve-WorkstationExecutable { 'C:\tools\bun.exe' }
            Mock Get-WorkstationExecutableVersion { '1.4.0' }
            Test-WorkstationWinget -Resource $resource -Context $context | Should -BeFalse
            { Set-WorkstationWinget -Resource $resource -Context $context } | Should -Throw '*Refusing downgrade*'
            Should -Invoke Invoke-WorkstationNative -Times 0 -Exactly
        }

        It 'requests a required consumer pin when upgrading an older installation' {
            $resource.versionPolicy = 'pinned'
            $resource.version = '1.3.13'
            $context.Installed['Vendor.Tool'] = '1.3.12'
            Set-WorkstationWinget -Resource $resource -Context $context
            Should -Invoke Invoke-WorkstationNative -Times 1 -Exactly -ParameterFilter { $Arguments[$Arguments.IndexOf('--version') + 1] -eq '1.3.13' }
        }

        It 'refuses to install a competing Visual C++ runtime' {
            $resource.requiresVCRuntime = $true
            Mock Get-ItemProperty { $null }
            { Set-WorkstationWinget -Resource $resource -Context $context } | Should -Throw '*Ask IT*'
            Should -Invoke Invoke-WorkstationNative -Times 0 -Exactly
        }
    }
}

Describe 'Portable resolution and user PATH' {
    InModuleScope Workstation {
        It 'finds nested executables under the selected package root with empty Links' {
            Mock Test-Path { $true } -ParameterFilter { $LiteralPath -like '*Microsoft\WinGet\Packages\Vendor.Tool_*' }
            Mock Get-ChildItem { [pscustomobject]@{ FullName = 'C:\Packages\nested\tool.exe' } }
            $resource = @{ id = 'Vendor.Tool'; executable = 'tool.exe'; installerType = 'zip' }
            Resolve-WorkstationExecutable -Resource $resource | Should -Be 'C:\Packages\nested\tool.exe'
            Should -Invoke Get-ChildItem -Times 1 -Exactly -ParameterFilter { $LiteralPath -like '*Vendor.Tool_Microsoft.Winget.Source_8wekyb3d8bbwe' -and $Recurse -and $File }
        }

        It 'fails ambiguous portable roots' {
            Mock Test-Path { $true }
            Mock Get-ChildItem { @([pscustomobject]@{ FullName = 'C:\one\tool.exe' }, [pscustomobject]@{ FullName = 'C:\two\tool.exe' }) }
            { Resolve-WorkstationExecutable -Resource @{ id = 'Vendor.Tool'; executable = 'tool.exe'; installerType = 'zip' } } | Should -Throw '*Ambiguous*'
        }

        It 'resolves one PATH-preferred application when multiple installations are discoverable' {
            Mock Test-Path { $false }
            Mock Get-Command { @([pscustomobject]@{ Source = 'C:\first\tool.exe' }, [pscustomobject]@{ Source = 'C:\second\tool.exe' }) }
            Resolve-WorkstationExecutable -Resource @{ id = 'Vendor.Tool'; executable = 'tool.exe' } | Should -Be 'C:\first\tool.exe'
        }

        It 'preserves PATH on a no-op and appends a missing directory once' {
            Mock Get-WorkstationUserPath { 'C:\existing;C:\TOOLS\' }
            Mock Set-WorkstationPersistedUserPath {}
            Mock Update-WorkstationProcessPath {}
            Set-WorkstationUserPath -Directory 'C:\tools'
            Should -Invoke Set-WorkstationPersistedUserPath -Times 0 -Exactly
            Set-WorkstationUserPath -Directory 'C:\new'
            Should -Invoke Set-WorkstationPersistedUserPath -Times 1 -Exactly -ParameterFilter { $Value -eq 'C:\existing;C:\TOOLS\;C:\new' }
        }

        It 'compares ImageMagick fourth release components' {
            Compare-WorkstationVersion -Actual '7.1.2-7' -Desired '7.1.2-6' | Should -BeGreaterThan 0
            Compare-WorkstationVersion -Actual '7.1.2.6' -Desired '7.1.2-6' | Should -Be 0
        }
    }
}

Describe 'Read-only and apply orchestration against mocks' {
    InModuleScope Workstation {
        BeforeEach {
            $script:resources = @(
                @{ name = 'one'; kind = 'winget'; id = 'Vendor.One' },
                @{ name = 'two'; kind = 'winget'; id = 'Vendor.Two' }
            )
            Mock Read-WorkstationData { @{ applications = $script:resources; settings = @(@{ name = 'setting'; kind = 'registry' }) } }
            Mock Test-WorkstationElevated { $false }
            Mock Get-WorkstationWingetSnapshot { @{ 'Vendor.One' = '1.0'; 'Vendor.Two' = '1.0' } }
            Mock Test-WorkstationApplication { $true }
            Mock Test-WorkstationSetting { $true }
            Mock Set-WorkstationApplication {}
            Mock Set-WorkstationSetting {}
            Mock Write-Host {}
        }

        It 'returns zero for desired dry run with one snapshot and no writes' {
            Invoke-Workstation -DryRun | Should -Be 0
            Should -Invoke Get-WorkstationWingetSnapshot -Times 1 -Exactly
            Should -Invoke Set-WorkstationApplication -Times 0 -Exactly
            Should -Invoke Set-WorkstationSetting -Times 0 -Exactly
            Should -Invoke Write-Host -Times 3 -Exactly -ParameterFilter { $Object -like 'desired:*' }
        }

        It 'reports all dry-run drift and exits one without setting or refreshing' {
            Mock Test-WorkstationApplication { $false }
            Mock Test-WorkstationSetting { $false }
            Invoke-Workstation -DryRun | Should -Be 1
            Should -Invoke Write-Host -Times 3 -Exactly -ParameterFilter { $Object -like 'drift:*' }
            Should -Invoke Get-WorkstationWingetSnapshot -Times 1 -Exactly
            Should -Invoke Set-WorkstationApplication -Times 0 -Exactly
            Should -Invoke Set-WorkstationSetting -Times 0 -Exactly
        }

        It 'keeps a no-op apply to one snapshot with no setters' {
            Invoke-Workstation -Apply | Should -Be 0
            Should -Invoke Get-WorkstationWingetSnapshot -Times 1 -Exactly
            Should -Invoke Set-WorkstationApplication -Times 0 -Exactly
            Should -Invoke Set-WorkstationSetting -Times 0 -Exactly
        }

        It 'refreshes just once after all changed packages and verifies each' {
            Mock Test-WorkstationApplication { $false }
            Mock Set-WorkstationApplication { $Context.WingetChanged = $true }
            Mock Test-WorkstationWinget { $true }
            Invoke-Workstation -Apply | Should -Be 0
            Should -Invoke Get-WorkstationWingetSnapshot -Times 2 -Exactly
            Should -Invoke Set-WorkstationApplication -Times 2 -Exactly
            Should -Invoke Test-WorkstationWinget -Times 2 -Exactly
        }

        It 'distinguishes validation errors and refuses elevated execution before discovery' {
            Mock Test-WorkstationElevated { $true }
            Invoke-Workstation -DryRun | Should -Be 2
            Should -Invoke Read-WorkstationData -Times 0 -Exactly
            Should -Invoke Get-WorkstationWingetSnapshot -Times 0 -Exactly
        }

        It 'fails an apply postcondition without moving on to settings' {
            Mock Test-WorkstationApplication { $false }
            Mock Set-WorkstationApplication { $Context.WingetChanged = $true }
            Mock Test-WorkstationWinget { $false }
            Invoke-Workstation -Apply | Should -Be 2
            Should -Invoke Set-WorkstationSetting -Times 0 -Exactly
        }

        It 'stops at native failure without retry' {
            Mock Test-WorkstationApplication { $false }
            Mock Set-WorkstationApplication { throw 'installer exited 9' }
            Invoke-Workstation -Apply | Should -Be 2
            Should -Invoke Set-WorkstationApplication -Times 1 -Exactly
        }
    }
}

Describe 'Native invocation exit handling' {
    InModuleScope Workstation {
        It 'accepts stderr diagnostics when the exit code is zero' {
            $hostExe = (Get-Process -Id $PID).Path
            Invoke-WorkstationNative -Command $hostExe -Arguments @('-NoProfile', '-Command', '[Console]::Error.WriteLine("npm notice"); Write-Output "ok"; exit 0') | Should -Be 'ok'
        }

        It 'propagates a nonzero native exit and missing commands' {
            $hostExe = (Get-Process -Id $PID).Path
            { Invoke-WorkstationNative -Command $hostExe -Arguments @('-NoProfile', '-Command', 'exit 7') } | Should -Throw '*exited 7*'
            { Invoke-WorkstationNative -Command 'not-a-real-workstation-command.exe' } | Should -Throw
        }
    }
}
