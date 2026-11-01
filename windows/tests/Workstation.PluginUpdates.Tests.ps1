BeforeDiscovery {
    Import-Module (Join-Path $PSScriptRoot '../Workstation.psm1') -Force
}

Describe 'Personal plugin scheduled task convergence' {
    InModuleScope Workstation {
        BeforeAll {
            $script:resource = @{ kind = 'personalPluginUpdate'; taskName = 'OMP personal plugin upgrade' }
        }
        BeforeEach {
            $script:source = Join-Path $TestDrive 'source.ps1'
            $script:runner = Join-Path $TestDrive 'installed.ps1'
            Set-Content $script:source 'runner'
            Copy-Item $script:source $script:runner
            Mock Get-WorkstationPluginUpdatePaths { @{ Source = $script:source; Runner = $script:runner } }
            $script:desired = Get-WorkstationPluginUpdateTaskXml
            $script:installed = $script:desired
            Mock Get-ScheduledTask { [pscustomobject]@{ TaskName = $script:resource.taskName } }
            Mock Export-ScheduledTask { $script:installed }
            Mock Register-ScheduledTask {}
        }

        It 'requires interactive unelevated logon and hourly execution with bounded runtime' {
            [xml]$xml = $script:desired
            $xml.Task.Principals.Principal.LogonType | Should -BeExactly 'InteractiveToken'
            $xml.Task.Principals.Principal.RunLevel | Should -BeExactly 'LeastPrivilege'
            $xml.Task.Triggers.LogonTrigger.UserId | Should -BeExactly $xml.Task.Principals.Principal.UserId
            $xml.Task.Triggers.TimeTrigger.Repetition.Interval | Should -BeExactly 'PT1H'
            $xml.Task.Settings.MultipleInstancesPolicy | Should -BeExactly 'IgnoreNew'
            $xml.Task.Settings.ExecutionTimeLimit | Should -BeExactly 'PT15M'
            $xml.Task.Actions.Exec.Arguments | Should -Match ([regex]::Escape($script:runner))
        }

        It 'skips an identical task and runner' {
            Test-WorkstationSetting -Resource $script:resource | Should -BeTrue
            Set-WorkstationSetting -Resource $script:resource
            Should -Invoke Register-ScheduledTask -Times 0 -Exactly
        }

        It 'repairs noninteractive execution and installs the current runner' {
            $script:installed = $script:desired.Replace('InteractiveToken', 'S4U')
            Test-WorkstationSetting -Resource $script:resource | Should -BeFalse
            Set-WorkstationSetting -Resource $script:resource
            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter { $Xml -match 'InteractiveToken' }
            (Get-Content $script:runner -Raw) | Should -BeExactly (Get-Content $script:source -Raw)
        }

        It 'detects changed runner contents and extra triggers' {
            Set-Content $script:runner 'old'
            Test-WorkstationSetting -Resource $script:resource | Should -BeFalse
            Copy-Item $script:source $script:runner
            $script:installed = $script:desired.Replace('</Triggers>', '<BootTrigger><Enabled>true</Enabled></BootTrigger></Triggers>')
            Test-WorkstationSetting -Resource $script:resource | Should -BeFalse
        }
    }
}

Describe 'Personal plugin update runner' {
    BeforeAll {
        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '../personal-plugin-upgrade.ps1'), [ref]$tokens, [ref]$errors)
        foreach ($function in $ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
            . ([scriptblock]::Create($function.Extent.Text))
        }
    }
    BeforeEach {
        $script:originalPath = $env:PATH
        Mock Get-Command { [pscustomobject]@{ Source = 'omp.exe' } } -ParameterFilter { $Name -eq 'omp' }
        Mock Write-PluginUpdateLog {}
        Mock Start-Sleep {}
        Mock Invoke-PluginUpdateCommand { @{ Code = 0; Output = 'already up to date' } }
    }
    AfterEach { $env:PATH = $script:originalPath }

    It 'refreshes the named marketplace before upgrading only the user personal plugin' {
        Invoke-PersonalPluginUpdate | Should -Be 0
        Should -Invoke Invoke-PluginUpdateCommand -Times 1 -Exactly -ParameterFilter { ($Arguments -join ' ') -ceq 'plugin marketplace update glockyco' }
        Should -Invoke Invoke-PluginUpdateCommand -Times 1 -Exactly -ParameterFilter { ($Arguments -join ' ') -ceq 'plugin upgrade --scope user personal@glockyco' }
        Should -Invoke Write-PluginUpdateLog -Times 1 -Exactly -ParameterFilter { $Message -eq 'Personal plugin update succeeded' }
    }

    It 'retries a temporary EPERM and then upgrades' {
        $script:attempts = 0
        Mock Invoke-PluginUpdateCommand {
            $script:attempts++
            if ($script:attempts -eq 1) { return @{ Code = 1; Output = 'EPERM: handle held' } }
            return @{ Code = 0; Output = 'up to date' }
        }
        Invoke-PersonalPluginUpdate | Should -Be 0
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 15 }
        Should -Invoke Invoke-PluginUpdateCommand -Times 3 -Exactly
    }

    It 'stops after four locked marketplace attempts without upgrading' {
        Mock Invoke-PluginUpdateCommand { @{ Code = 1; Output = 'EPERM: handle held' } }
        Invoke-PersonalPluginUpdate | Should -Be 1
        Should -Invoke Start-Sleep -Times 3 -Exactly
        Should -Invoke Invoke-PluginUpdateCommand -Times 4 -Exactly
        Should -Invoke Invoke-PluginUpdateCommand -Times 0 -Exactly -ParameterFilter { $Arguments -contains 'upgrade' }
        Should -Invoke Write-PluginUpdateLog -Times 1 -Exactly -ParameterFilter { $Message -like 'Personal plugin update failed:*' }
    }

    It 'does not retry other failures or upgrade after them' {
        Mock Invoke-PluginUpdateCommand { @{ Code = 1; Output = 'network failure' } }
        Invoke-PersonalPluginUpdate | Should -Be 1
        Should -Invoke Start-Sleep -Times 0 -Exactly
        Should -Invoke Invoke-PluginUpdateCommand -Times 1 -Exactly
    }

    It 'reports a failed upgrade' {
        Mock Invoke-PluginUpdateCommand { @{ Code = 1; Output = 'upgrade failure' } } -ParameterFilter { $Arguments -contains 'upgrade' }
        Invoke-PersonalPluginUpdate | Should -Be 1
        Should -Invoke Write-PluginUpdateLog -Times 1 -Exactly -ParameterFilter { $Message -like '*Personal plugin upgrade exited 1*' }
    }
}
