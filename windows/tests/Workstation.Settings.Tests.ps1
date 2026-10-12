BeforeDiscovery {
    Import-Module (Join-Path $PSScriptRoot '../Workstation.psm1') -Force
}

Describe 'Workstation settings convergence' {
    InModuleScope Workstation {
        BeforeAll {
            function New-TestLanguage {
                param([string] $Tag, [string[]] $Tips = @())
                $tipsList = [System.Collections.Generic.List[string]]::new()
                foreach ($tip in $Tips) { $tipsList.Add($tip) }
                return [pscustomobject]@{ LanguageTag = $Tag; InputMethodTips = $tipsList }
            }
        }

        Context 'Typed and absent registry values' {
            BeforeEach {
                $script:registryResource = @{ kind = 'registry'; path = 'HKCU:\Control Panel\Keyboard'; valueName = 'KeyboardDelay'; ensure = 'present'; type = 'String'; value = '0' }
                Mock New-Item {}
                Mock New-ItemProperty {}
                Mock Remove-ItemProperty {}
            }

            It 'detects a wrong type and writes the declared type without replacing the key' {
                Mock Get-WorkstationRegistryValue { @{ KeyExists = $true; Exists = $true; Type = 'DWord'; Value = 0 } }
                Test-WorkstationSetting -Resource $script:registryResource | Should -BeFalse
                Set-WorkstationSetting -Resource $script:registryResource
                Should -Invoke New-ItemProperty -Times 1 -Exactly -ParameterFilter { $PropertyType -eq 'String' -and $Value -ceq '0' -and $Name -eq 'KeyboardDelay' }
                Should -Invoke New-Item -Times 0 -Exactly
                Should -Invoke Remove-ItemProperty -Times 0 -Exactly
            }

            It 'creates a missing key and leaves environment variables unexpanded in ExpandString data' {
                $script:registryResource.type = 'ExpandString'
                $script:registryResource.value = '%APPDATA%\AltSnap\AltSnap.exe'
                Mock Get-WorkstationRegistryValue { @{ KeyExists = $false; Exists = $false; Type = $null; Value = $null } }
                Set-WorkstationSetting -Resource $script:registryResource
                Should -Invoke New-Item -Times 1 -Exactly
                Should -Invoke New-ItemProperty -Times 1 -Exactly -ParameterFilter { $PropertyType -eq 'ExpandString' -and $Value -ceq '%APPDATA%\AltSnap\AltSnap.exe' }
            }

            It 'does nothing when the exact value and type already match' {
                Mock Get-WorkstationRegistryValue { @{ KeyExists = $true; Exists = $true; Type = 'String'; Value = '0' } }
                Test-WorkstationSetting -Resource $script:registryResource | Should -BeTrue
                Set-WorkstationSetting -Resource $script:registryResource
                Should -Invoke New-ItemProperty -Times 0 -Exactly
            }

            It 'removes only the declared absent value and skips an already absent value' {
                $script:registryResource.ensure = 'absent'
                Mock Get-WorkstationRegistryValue { @{ KeyExists = $true; Exists = $true; Type = 'String'; Value = 'old' } }
                Set-WorkstationSetting -Resource $script:registryResource
                Should -Invoke Remove-ItemProperty -Times 1 -Exactly -ParameterFilter { $Name -eq 'KeyboardDelay' -and $LiteralPath -eq 'HKCU:\Control Panel\Keyboard' }
                Mock Get-WorkstationRegistryValue { @{ KeyExists = $false; Exists = $false; Type = $null; Value = $null } }
                Test-WorkstationSetting -Resource $script:registryResource | Should -BeTrue
                Set-WorkstationSetting -Resource $script:registryResource
                Should -Invoke Remove-ItemProperty -Times 1 -Exactly
                Should -Invoke New-ItemProperty -Times 0 -Exactly
            }

            It 'reads raw unexpanded registry data and its exact kind' {
                $script:key = [pscustomobject]@{}
                $script:key | Add-Member ScriptMethod GetValueNames { @('KeyboardDelay') }
                $script:key | Add-Member ScriptMethod GetValueKind { param($Name) [Microsoft.Win32.RegistryValueKind]::ExpandString }
                $script:key | Add-Member ScriptMethod GetValue {
                    param($Name, $Default, $Options)
                    if ($Options -ne [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) { throw 'Expected raw registry reads' }
                    '%APPDATA%\AltSnap\AltSnap.exe'
                }
                Mock Test-Path { $true }
                Mock Get-Item { $script:key }
                $state = Get-WorkstationRegistryValue -Path $script:registryResource.path -ValueName 'KeyboardDelay'
                $state.Type | Should -BeExactly 'ExpandString'
                $state.Value | Should -BeExactly '%APPDATA%\AltSnap\AltSnap.exe'
            }
        }

        Context 'Language and input retention' {
            BeforeEach {
                $script:languages = [System.Collections.Generic.List[object]]::new()
                $script:languages.Add((New-TestLanguage 'de-DE' @('0407:b0000407', '0407:00000407', '0407:00010407')))
                $script:languages.Add((New-TestLanguage 'de-AT' @('0c07:00000407', '0c07:00010407')))
                $script:languages.Add((New-TestLanguage 'en-GB' @('0809:00000809')))
                $script:languageResource = @{ kind = 'language'; languages = @('en-GB', 'de-DE', 'de-AT'); ui = 'en-GB' }
                $script:inputResource = @{ kind = 'inputMethods'; ordered = @('0407:00000407', '0407:b0000407'); default = '0407:00000407'; neoRegistryPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\b0000407' }
                Mock Set-WorkstationUserLanguageList {}
                Mock Set-WinUILanguageOverride {}
                Mock Set-WinDefaultInputMethodOverride {}
            }

            It 'preserves German and Austrian tips and uses the English placeholder only during writes' {
                Mock Get-WorkstationLanguageState { @{ Languages = $script:languages; Override = $null } }
                # Model the Windows collection's tag-to-language conversion without loading International.
                Mock New-WinUserLanguageList {
                    $list = New-Object System.Collections.ArrayList
                    $null = $list.Add((New-TestLanguage 'en-GB' @('0809:00000809')))
                    Add-Member -InputObject $list -MemberType ScriptMethod -Name Add -Force -Value { param($Tag) $this.Insert($this.Count, (New-TestLanguage $Tag)) }
                    return ,$list
                }
                Set-WorkstationSetting -Resource $script:languageResource
                Should -Invoke Set-WorkstationUserLanguageList -Times 1 -Exactly -ParameterFilter {
                    $LanguageList[0].LanguageTag -eq 'en-GB' -and ($LanguageList[0].InputMethodTips -join ',') -eq '0407:b0000407' -and
                    ($LanguageList[1].InputMethodTips -join ',') -eq '0407:b0000407,0407:00000407,0407:00010407' -and
                    ($LanguageList[2].InputMethodTips -join ',') -eq '0c07:00000407,0c07:00010407'
                }
                Should -Invoke Set-WinUILanguageOverride -Times 1 -Exactly -ParameterFilter { $Language -eq 'en-GB' }
            }

            It 'rejects missing retained languages before any write' {
                Mock Get-WorkstationLanguageState { @{ Languages = @((New-TestLanguage 'en-GB')); Override = $null } }
                { Set-WorkstationSetting -Resource $script:languageResource } | Should -Throw '*de-DE*'
                Should -Invoke Set-WorkstationUserLanguageList -Times 0 -Exactly
                Should -Invoke Set-WinUILanguageOverride -Times 0 -Exactly
            }

            It 'accepts English UI without English input and performs no language write' {
                $script:languages = @((New-TestLanguage 'en-GB'), (New-TestLanguage 'de-DE' @('0407:00000407')), (New-TestLanguage 'de-AT' @('0c07:00000407')))
                Mock Get-WorkstationLanguageState { @{ Languages = $script:languages; Override = [pscustomobject]@{ Name = 'en-GB' } } }
                Test-WorkstationSetting -Resource $script:languageResource | Should -BeTrue
                Set-WorkstationSetting -Resource $script:languageResource
                Should -Invoke Set-WorkstationUserLanguageList -Times 0 -Exactly
                Should -Invoke Set-WinUILanguageOverride -Times 0 -Exactly
            }

            It 'places QWERTZ first/default and Neo second while retaining extra German and all Austrian tips' {
                $script:languages[2].InputMethodTips.Clear()
                Mock Get-WorkstationInputState { @{ NeoInstalled = $true; Languages = $script:languages; Override = $null } }
                Set-WorkstationSetting -Resource $script:inputResource
                ($script:languages[0].InputMethodTips -join ',') | Should -BeExactly '0407:00000407,0407:b0000407,0407:00010407'
                ($script:languages[1].InputMethodTips -join ',') | Should -BeExactly '0c07:00000407,0c07:00010407'
                ($script:languages[2].InputMethodTips -join ',') | Should -BeExactly '0407:b0000407'
                Should -Invoke Set-WorkstationUserLanguageList -Times 1 -Exactly
                Should -Invoke Set-WinDefaultInputMethodOverride -Times 1 -Exactly -ParameterFilter { $InputTip -eq '0407:00000407' }
            }

            It 'refuses input changes until the owner installs and restarts the native Neo driver' {
                Mock Get-WorkstationInputState { @{ NeoInstalled = $false; Languages = $script:languages; Override = $null } }
                Test-WorkstationSetting -Resource $script:inputResource | Should -BeFalse
                { Set-WorkstationSetting -Resource $script:inputResource } | Should -Throw '*apply-kbdneo.ps1*Administrator*restart*'
                Should -Invoke Set-WorkstationUserLanguageList -Times 0 -Exactly
                Should -Invoke Set-WinDefaultInputMethodOverride -Times 0 -Exactly
            }

            It 'skips an already ordered and defaulted input list' {
                $script:languages[0].InputMethodTips.Clear()
                $script:languages[0].InputMethodTips.Add('0407:00000407')
                $script:languages[0].InputMethodTips.Add('0407:b0000407')
                Mock Get-WorkstationInputState { @{ NeoInstalled = $true; Languages = $script:languages; Override = [pscustomobject]@{ InputMethodTip = '0407:00000407' } } }
                Test-WorkstationSetting -Resource $script:inputResource | Should -BeTrue
                Set-WorkstationSetting -Resource $script:inputResource
                Should -Invoke Set-WorkstationUserLanguageList -Times 0 -Exactly
                Should -Invoke Set-WinDefaultInputMethodOverride -Times 0 -Exactly
            }
        }

        Context 'Appearance and animation' {

            It 'accepts generated Custom.theme without reading or changing the active theme path' {
                Mock Get-WorkstationRegistryValue {
                    if ($ValueName -eq 'CurrentTheme') { throw 'The generated theme path must not be read' }
                    if ($ValueName -eq 'WallPaper') { return @{ Exists = $true; Type = 'String'; Value = 'C:\Windows\Web\Wallpaper\Windows\img19.jpg' } }
                    return @{ KeyExists = $true; Exists = $true; Type = 'DWord'; Value = 0 }
                }
                Mock Resolve-WorkstationWallpaperPath { 'C:\Windows\Web\Wallpaper\Windows\img19.jpg' }
                Mock Set-WorkstationRegistry {}
                Mock Set-WorkstationWallpaper {}
                Mock Send-WorkstationAppearanceNotification {}
                $resource = @{ kind = 'appearance'; wallpaper = '%WINDIR%\Web\Wallpaper\Windows\img19.jpg' }
                Test-WorkstationSetting -Resource $resource | Should -BeTrue
                Set-WorkstationSetting -Resource $resource
                Should -Invoke Set-WorkstationRegistry -Times 0 -Exactly
                Should -Invoke Set-WorkstationWallpaper -Times 0 -Exactly
                Should -Invoke Send-WorkstationAppearanceNotification -Times 0 -Exactly
            }

            It 'changes only drifted dark flags and wallpaper and broadcasts once' {
                Mock Test-WorkstationRegistry { $Resource.valueName -ne 'EnableTransparency' }
                Mock Test-WorkstationWallpaper { $false }
                Mock Resolve-WorkstationWallpaperPath { 'C:\Windows\Web\Wallpaper\Windows\img19.jpg' }
                Mock Set-WorkstationRegistry {}
                Mock Set-WorkstationWallpaper {}
                Mock Send-WorkstationAppearanceNotification {}
                Set-WorkstationSetting -Resource @{ kind = 'appearance'; wallpaper = '%WINDIR%\Web\Wallpaper\Windows\img19.jpg' }
                Should -Invoke Set-WorkstationRegistry -Times 1 -Exactly -ParameterFilter { $Resource.valueName -eq 'EnableTransparency' -and $Resource.value -eq 0 }
                Should -Invoke Set-WorkstationWallpaper -Times 1 -Exactly
                Should -Invoke Send-WorkstationAppearanceNotification -Times 1 -Exactly
            }

            It 'sets disabled animation once and skips a desired native state' {
                Mock Get-WorkstationAnimationEnabled { $true }
                Mock Set-WorkstationAnimationEnabled {}
                $resource = @{ kind = 'animation'; enabled = $false }
                Test-WorkstationSetting -Resource $resource | Should -BeFalse
                Set-WorkstationSetting -Resource $resource
                Should -Invoke Set-WorkstationAnimationEnabled -Times 1 -Exactly -ParameterFilter { -not $Enabled }
                Mock Get-WorkstationAnimationEnabled { $false }
                Test-WorkstationSetting -Resource $resource | Should -BeTrue
                Set-WorkstationSetting -Resource $resource
                Should -Invoke Set-WorkstationAnimationEnabled -Times 1 -Exactly
            }
        }

        Context 'Typed taskbar visibility' {
            BeforeEach {
                $script:taskbarResource = @{ kind = 'taskbarVisibility'; path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'; valueName = 'Settings'; index = 8; value = 2 }
                $script:taskbarBytes = [byte[]](0..31)
                Mock Get-WorkstationRegistryValue { @{ Exists = $true; Type = 'Binary'; Value = $script:taskbarBytes } }
                Mock Set-ItemProperty {}
                Mock Stop-Process {}
            }

            It 'changes only byte 8 using a replacement buffer and restarts Explorer once' {
                Test-WorkstationSetting -Resource $script:taskbarResource | Should -BeFalse
                Set-WorkstationSetting -Resource $script:taskbarResource
                Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'Settings' -and $LiteralPath -eq $script:taskbarResource.path -and $Value[8] -eq 2 -and
                    ($Value[0..7] -join ',') -eq '0,1,2,3,4,5,6,7' -and ($Value[9..31] -join ',') -eq ((9..31) -join ',')
                }
                ($script:taskbarBytes -join ',') | Should -BeExactly ((0..31) -join ',')
                Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter { $Name -eq 'explorer' -and $Force }
            }

            It 'never writes or restarts Explorer for already visible taskbar state' {
                $script:taskbarBytes[8] = 2
                Test-WorkstationSetting -Resource $script:taskbarResource | Should -BeTrue
                Set-WorkstationSetting -Resource $script:taskbarResource
                Should -Invoke Set-ItemProperty -Times 0 -Exactly
                Should -Invoke Stop-Process -Times 0 -Exactly
            }

            It 'rejects a missing or wrongly typed taskbar value before writes' {
                Mock Get-WorkstationRegistryValue { @{ Exists = $false; Type = $null; Value = $null } }
                { Set-WorkstationSetting -Resource $script:taskbarResource } | Should -Throw '*binary*'
                Mock Get-WorkstationRegistryValue { @{ Exists = $true; Type = 'DWord'; Value = 2 } }
                { Set-WorkstationSetting -Resource $script:taskbarResource } | Should -Throw '*binary*'
                Should -Invoke Set-ItemProperty -Times 0 -Exactly
                Should -Invoke Stop-Process -Times 0 -Exactly
            }
        }
    }
}
