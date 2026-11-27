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
            $xml.Task.Settings.ExecutionTimeLimit | Should -BeExactly 'PT50M'
            $xml.Task.Actions.Exec.Command | Should -BeExactly (Join-Path $env:SystemRoot 'System32\conhost.exe')
            $xml.Task.Actions.Exec.Arguments | Should -BeExactly ('--headless "' + (Join-Path $PSHOME 'pwsh.exe') + '" -NoProfile -NonInteractive -File "' + $script:runner + '"')
            $xml.Task.Actions.Exec.Arguments | Should -Match ([regex]::Escape($script:runner))
        }

        It 'skips an identical task and runner' {
            Test-WorkstationSetting -Resource $script:resource | Should -BeTrue
            Set-WorkstationSetting -Resource $script:resource
            Should -Invoke Register-ScheduledTask -Times 0 -Exactly
        }

        It 'repairs the old direct PowerShell action' {
            [xml]$xml = $script:desired
            $xml.Task.Actions.Exec.Command = Join-Path $PSHOME 'pwsh.exe'
            $xml.Task.Actions.Exec.Arguments = '-NoProfile -NonInteractive -WindowStyle Hidden -File "' + $script:runner + '"'
            $script:installed = $xml.OuterXml
            Test-WorkstationSetting -Resource $script:resource | Should -BeFalse
            Set-WorkstationSetting -Resource $script:resource
            Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter { $Xml -ceq $script:desired }
            $script:installed = $script:desired
            Test-WorkstationSetting -Resource $script:resource | Should -BeTrue
        }

        It 'accepts scheduler default elision and account-name normalization but rejects disabled tasks' {
            $account = [Security.SecurityElement]::Escape([Security.Principal.WindowsIdentity]::GetCurrent().Name)
            [xml]$xml = $script:desired
            $sid = $xml.Task.Triggers.LogonTrigger.UserId
            $script:installed = $script:desired.Replace('<Enabled>true</Enabled>', '').Replace('<StopAtDurationEnd>false</StopAtDurationEnd>', '').Replace('<RunLevel>LeastPrivilege</RunLevel>', '')
            $script:installed = $script:installed.Replace("<UserId>$sid</UserId></LogonTrigger>", "<UserId>$account</UserId></LogonTrigger>")
            Test-WorkstationSetting -Resource $script:resource | Should -BeTrue
            $script:installed = $script:installed.Replace('<Settings>', '<Settings><Enabled>false</Enabled>')
            Test-WorkstationSetting -Resource $script:resource | Should -BeFalse
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
        $script:listing = @'
Configured Marketplaces:

  glockyco  glockyco/omp-agent-setup
  glockyco-booking  glockyco/omp-booking
  obsidian-skills  kepano/obsidian-skills
  glockyco-workbench  glockyco/obsidian-workbench
'@
        $script:expectedCommands = @(
            'git ls-remote --exit-code https://github.com/glockyco/omp-agent-setup HEAD'
            'git ls-remote --exit-code https://github.com/glockyco/omp-booking HEAD'
            'git ls-remote --exit-code https://github.com/glockyco/obsidian-workbench HEAD'
            'git ls-remote --exit-code https://github.com/kepano/obsidian-skills HEAD'
            'omp plugin marketplace list'
            'omp plugin marketplace update glockyco'
            'omp plugin upgrade --scope user personal@glockyco'
            'omp plugin marketplace update glockyco-booking'
            'omp plugin upgrade --scope user booking@glockyco-booking'
            'omp plugin marketplace update glockyco-workbench'
            'omp plugin upgrade --scope user workbench@glockyco-workbench'
            'omp plugin marketplace update obsidian-skills'
            'omp plugin upgrade --scope user obsidian@obsidian-skills'
        )
        @'
[
  {"plugin":"personal@glockyco","marketplace":"glockyco","source":"glockyco/omp-agent-setup"},
  {"plugin":"booking@glockyco-booking","marketplace":"glockyco-booking","source":"glockyco/omp-booking"},
  {"plugin":"workbench@glockyco-workbench","marketplace":"glockyco-workbench","source":"glockyco/obsidian-workbench"},
  {"plugin":"obsidian@obsidian-skills","marketplace":"obsidian-skills","source":"kepano/obsidian-skills"}
]
'@ | Set-Content -LiteralPath (Join-Path $TestDrive 'omp-plugins.json')
    }
    BeforeEach {
        $script:originalPath = $env:PATH
        $script:commands = [Collections.Generic.List[string]]::new()
        $script:results = @{}
        $script:messages = [Collections.Generic.List[string]]::new()
        Mock Write-PluginUpdateLog { $script:messages.Add($Message) }
        Mock Start-Sleep {}
        Mock Invoke-PluginUpdateCommand {
            $call = "$Command $($Arguments -join ' ')"
            $script:commands.Add($call)
            if ($script:results.ContainsKey($call) -and $script:results[$call].Count) {
                return $script:results[$call].Dequeue()
            }
            if ($call -ceq 'omp plugin marketplace list') {
                return @{ Code = 0; Stdout = $script:listing; Stderr = '' }
            }
            return @{ Code = 0; Stdout = 'already up to date'; Stderr = '' }
        }
    }
    AfterEach { $env:PATH = $script:originalPath }

    It 'checks sources and refreshes and upgrades all four plugins in declaration order' {
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 0
        ($script:commands -join "`n") | Should -BeExactly ($script:expectedCommands -join "`n")
        $script:messages[-1] | Should -BeExactly 'Personal plugin update succeeded'
    }

    It 'skips only the upgrade of the marketplace whose refresh fails' {
        $script:results['omp plugin marketplace update glockyco-booking'] = [Collections.Queue]::new(@(@{ Code = 1; Stdout = ''; Stderr = 'network failure' }))
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 1
        ($script:commands -join "`n") | Should -BeExactly (($script:expectedCommands | Where-Object { $_ -notlike '*upgrade* booking@*' }) -join "`n")
        Should -Invoke Start-Sleep -Times 0 -Exactly
        $script:messages | Should -Contain 'Marketplace glockyco-booking refresh exited 1'
    }

    It 'retries a temporary EPERM once before upgrading its plugin' {
        $refresh = 'omp plugin marketplace update glockyco-booking'
        $script:results[$refresh] = [Collections.Queue]::new(@(@{ Code = 1; Stdout = ''; Stderr = 'EPERM: handle held' }))
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 0
        Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Seconds -eq 15 }
        $script:commands[7] | Should -BeExactly $refresh
        $script:commands[8] | Should -BeExactly $refresh
        $script:commands[9] | Should -BeExactly 'omp plugin upgrade --scope user booking@glockyco-booking'
    }

    It 'stops after four locked marketplace attempts and continues with other plugins' {
        $refresh = 'omp plugin marketplace update glockyco-booking'
        $script:results[$refresh] = [Collections.Queue]::new(@(@{ Code = 1; Stdout = 'EPERM: handle held'; Stderr = '' }) * 4)
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 1
        Should -Invoke Start-Sleep -Times 3 -Exactly -ParameterFilter { $Seconds -eq 15 }
        @($script:commands | Where-Object { $_ -ceq $refresh }).Count | Should -Be 4
        $script:commands | Should -Not -Contain 'omp plugin upgrade --scope user booking@glockyco-booking'
        $script:commands[-1] | Should -BeExactly 'omp plugin upgrade --scope user obsidian@obsidian-skills'
    }

    It 'logs a failed sign-in check before refreshing without blocking upgrades' {
        $script:results[$script:expectedCommands[1]] = [Collections.Queue]::new(@(@{ Code = 1; Stdout = ''; Stderr = 'sign-in required' }))
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 0
        $script:messages[1] | Should -BeExactly 'Git cannot read https://github.com/glockyco/omp-booking: run gh auth login -h github.com --web'
        ($script:commands -join "`n") | Should -BeExactly ($script:expectedCommands -join "`n")
    }

    It 'reports an SSH-registered marketplace without changing it or skipping its upgrade' {
        $sshListing = $script:listing.Replace('glockyco/omp-booking', 'git@github.com:glockyco/omp-booking.git')
        $script:results['omp plugin marketplace list'] = [Collections.Queue]::new(@(@{ Code = 0; Stdout = $sshListing; Stderr = '' }))
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 0
        $script:messages | Should -Contain 'Marketplace glockyco-booking is registered as git@github.com:glockyco/omp-booking.git, declared glockyco/omp-booking: run omp plugin marketplace remove glockyco-booking && omp plugin marketplace add glockyco/omp-booking'
        ($script:commands -join "`n") | Should -BeExactly ($script:expectedCommands -join "`n")
    }

    It 'fails a missing marketplace and skips its refresh and upgrade' {
        $partialListing = $script:listing -replace '(?m)^  glockyco-booking[^\r\n]*', ''
        $script:results['omp plugin marketplace list'] = [Collections.Queue]::new(@(@{ Code = 0; Stdout = $partialListing; Stderr = '' }))
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 1
        $script:messages | Should -Contain 'Marketplace glockyco-booking is not registered: run omp plugin marketplace add glockyco/omp-booking'
        ($script:commands -join "`n") | Should -BeExactly (($script:expectedCommands | Where-Object { $_ -cnotmatch 'omp plugin .*glockyco-booking' }) -join "`n")
    }

    It 'fails all plugins when no marketplaces are registered' {
        $emptyListing = "No marketplaces configured`n`nAdd one with: omp plugin marketplace add <source>"
        $script:results['omp plugin marketplace list'] = [Collections.Queue]::new(@(@{ Code = 0; Stdout = $emptyListing; Stderr = '' }))
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 1
        @($script:messages | Where-Object { $_ -like 'Marketplace * is not registered:*' }).Count | Should -Be 4
        ($script:commands -join "`n") | Should -BeExactly ($script:expectedCommands[0..4] -join "`n")
    }

    It 'continues without source checks if the listing cannot be read' {
        $script:results['omp plugin marketplace list'] = [Collections.Queue]::new(@(@{ Code = 0; Stdout = "Configured Marketplaces:`nunexpected data"; Stderr = '' }))
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 0
        $script:messages | Should -Contain 'Cannot read omp plugin marketplace list'
        ($script:commands -join "`n") | Should -BeExactly ($script:expectedCommands -join "`n")
    }

    It 'reports a failed upgrade and continues' {
        $script:results['omp plugin upgrade --scope user booking@glockyco-booking'] = [Collections.Queue]::new(@(@{ Code = 1; Stdout = ''; Stderr = 'upgrade failure' }))
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 1
        $script:messages | Should -Contain 'Plugin booking@glockyco-booking upgrade exited 1'
        ($script:commands -join "`n") | Should -BeExactly ($script:expectedCommands -join "`n")
    }

    It 'skips a timed-out refresh without retrying and continues' {
        $script:results['omp plugin marketplace update glockyco-booking'] = [Collections.Queue]::new(@(@{ Code = 124; Stdout = ''; Stderr = '' }))
        Invoke-PersonalPluginUpdate -Directory $TestDrive | Should -Be 1
        ($script:commands -join "`n") | Should -BeExactly (($script:expectedCommands | Where-Object { $_ -notlike '*upgrade* booking@*' }) -join "`n")
        Should -Invoke Start-Sleep -Times 0 -Exactly
    }
}

Describe 'Personal plugin update process' {
    BeforeAll {
        $tokens = $null
        $errors = $null
        $ast = [Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot '../personal-plugin-upgrade.ps1'), [ref]$tokens, [ref]$errors)
        foreach ($function in $ast.FindAll({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] }, $false)) {
            . ([scriptblock]::Create($function.Extent.Text))
        }
    }

    It 'closes stdin and kills the process tree at the command deadline' {
        $inputWriter = [IO.StringWriter]::new()
        $reader = [IO.StringReader]::new('')
        $script:process = [pscustomobject]@{
            StartInfo = [Diagnostics.ProcessStartInfo]::new()
            StandardInput = $inputWriter
            StandardOutput = $reader
            StandardError = $reader
            WaitMilliseconds = 0
            KilledTree = $false
            Disposed = $false
        }
        $script:process | Add-Member ScriptMethod Start { return $true }
        $script:process | Add-Member ScriptMethod WaitForExit { param($milliseconds) $this.WaitMilliseconds = $milliseconds; return $false }
        $script:process | Add-Member ScriptMethod Kill { param($tree) $this.KilledTree = $tree }
        $script:process | Add-Member ScriptMethod Dispose { $this.Disposed = $true }
        Mock New-Object { $script:process } -ParameterFilter { $TypeName -eq 'System.Diagnostics.Process' }
        Mock Get-Command { [pscustomobject]@{ Source = 'omp.exe' } } -ParameterFilter { $Name -eq 'omp' }
        Mock Write-PluginUpdateLog {}
        $result = Invoke-PluginUpdateCommand -Command omp -Arguments @('plugin', 'marketplace', 'update', 'glockyco')
        $result.Code | Should -Be 124
        $script:process.WaitMilliseconds | Should -Be 300000
        $script:process.KilledTree | Should -BeTrue
        $script:process.Disposed | Should -BeTrue
        { $inputWriter.Write('probe') } | Should -Throw
        $script:process.StartInfo.Environment['GIT_TERMINAL_PROMPT'] | Should -BeExactly '0'
        $script:process.StartInfo.Environment['GIT_SSH_COMMAND'] | Should -BeExactly 'ssh -o BatchMode=yes'
        Should -Invoke Write-PluginUpdateLog -Times 1 -Exactly -ParameterFilter { $Message -ceq 'omp plugin marketplace update glockyco timed out after 300 seconds' }
    }
}
