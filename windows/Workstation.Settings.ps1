$script:WorkstationSettingsNativeApi = $null

function Assert-WorkstationUserRegistryPath {
    param([Parameter(Mandatory)][string] $Path)
    if ($Path -notmatch '^HKCU:\\') { throw "Settings may write only HKCU: $Path" }
}

function Get-WorkstationRegistryValue {
    param([Parameter(Mandatory)][string] $Path, [Parameter(Mandatory)][string] $ValueName)
    if (-not (Test-Path -LiteralPath $Path -ErrorAction Stop)) {
        return @{ KeyExists = $false; Exists = $false; Type = $null; Value = $null }
    }
    $key = Get-Item -LiteralPath $Path -ErrorAction Stop
    if ($key.GetValueNames() -notcontains $ValueName) {
        return @{ KeyExists = $true; Exists = $false; Type = $null; Value = $null }
    }
    return @{
        KeyExists = $true
        Exists = $true
        Type = $key.GetValueKind($ValueName).ToString()
        Value = $key.GetValue($ValueName, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
    }
}

function Test-WorkstationRegistryState {
    param([hashtable] $Resource, [hashtable] $State)
    if ($Resource.ensure -eq 'absent') { return -not $State.Exists }
    if (-not $State.Exists -or $State.Type -cne $Resource.type) { return $false }
    return $State.Value -ceq $Resource.value
}

function Test-WorkstationRegistry {
    param([hashtable] $Resource)
    Assert-WorkstationUserRegistryPath -Path $Resource.path
    $state = Get-WorkstationRegistryValue -Path $Resource.path -ValueName $Resource.valueName
    return Test-WorkstationRegistryState -Resource $Resource -State $state
}

function Set-WorkstationRegistry {
    param([hashtable] $Resource)
    Assert-WorkstationUserRegistryPath -Path $Resource.path
    $state = Get-WorkstationRegistryValue -Path $Resource.path -ValueName $Resource.valueName
    if (Test-WorkstationRegistryState -Resource $Resource -State $state) { return }
    if ($Resource.ensure -eq 'absent') {
        Remove-ItemProperty -LiteralPath $Resource.path -Name $Resource.valueName -ErrorAction Stop
        return
    }
    if (-not $state.KeyExists) { New-Item -Path $Resource.path -Force -ErrorAction Stop | Out-Null }
    New-ItemProperty -LiteralPath $Resource.path -Name $Resource.valueName -Value $Resource.value -PropertyType $Resource.type -Force -ErrorAction Stop | Out-Null
}

function Get-WorkstationLanguageState {
    return @{
        Languages = Get-WinUserLanguageList -ErrorAction Stop
        Override = Get-WinUILanguageOverride -ErrorAction Stop
    }
}

function Set-WorkstationUserLanguageList {
    param([Parameter(Mandatory)] $LanguageList)
    # Keep the International cmdlet's native collection binding at the boundary.
    Set-WinUserLanguageList -LanguageList $LanguageList -Force -ErrorAction Stop
}

function Test-WorkstationLanguageList {
    param([hashtable] $Resource, $Languages)
    if ($Languages.Count -ne $Resource.languages.Count) { return $false }
    for ($index = 0; $index -lt $Resource.languages.Count; $index++) {
        if ($Languages[$index].LanguageTag -ne $Resource.languages[$index]) { return $false }
    }
    $display = @($Languages | Where-Object LanguageTag -EQ $Resource.ui)
    return $display.Count -eq 1 -and $display[0].InputMethodTips.Count -eq 0
}

function Test-WorkstationLanguage {
    param([hashtable] $Resource)
    $state = Get-WorkstationLanguageState
    return (Test-WorkstationLanguageList -Resource $Resource -Languages $state.Languages) -and
        $null -ne $state.Override -and $state.Override.Name -eq $Resource.ui
}

function Set-WorkstationLanguage {
    param([hashtable] $Resource)
    $state = Get-WorkstationLanguageState
    if (-not (Test-WorkstationLanguageList -Resource $Resource -Languages $state.Languages)) {
        # Validate both German entries before changing the language list.
        $preserved = @{}
        foreach ($tag in $Resource.languages) {
            if ($tag -eq $Resource.ui) { continue }
            $retained = @($state.Languages | Where-Object LanguageTag -EQ $tag)
            if ($retained.Count -ne 1) { throw "The user language list must contain exactly one $tag entry" }
            $preserved[$tag] = @($retained[0].InputMethodTips)
        }
        $desired = New-WinUserLanguageList -Language $Resource.languages[0] -ErrorAction Stop
        for ($index = 1; $index -lt $Resource.languages.Count; $index++) { $desired.Add($Resource.languages[$index]) }
        foreach ($language in $desired) {
            $language.InputMethodTips.Clear()
            if ($language.LanguageTag -eq $Resource.ui) {
                # Windows discards this German placeholder rather than restoring the UK keyboard.
                $language.InputMethodTips.Add('0407:b0000407')
            } else {
                foreach ($tip in $preserved[$language.LanguageTag]) { $language.InputMethodTips.Add($tip) }
            }
        }
        Set-WorkstationUserLanguageList -LanguageList $desired
    }
    if ($null -eq $state.Override -or $state.Override.Name -ne $Resource.ui) {
        Set-WinUILanguageOverride -Language $Resource.ui -ErrorAction Stop
    }
}

function Get-WorkstationInputState {
    param([hashtable] $Resource)
    return @{
        NeoInstalled = Test-Path -LiteralPath $Resource.neoRegistryPath -ErrorAction Stop
        Languages = Get-WinUserLanguageList -ErrorAction Stop
        Override = Get-WinDefaultInputMethodOverride -ErrorAction Stop
    }
}

function Test-WorkstationInputOrder {
    param([hashtable] $Resource, $Languages)
    $german = @($Languages | Where-Object LanguageTag -EQ 'de-DE')
    if ($german.Count -ne 1 -or $german[0].InputMethodTips.Count -lt $Resource.ordered.Count) { return $false }
    for ($index = 0; $index -lt $Resource.ordered.Count; $index++) {
        if ($german[0].InputMethodTips[$index] -ne $Resource.ordered[$index]) { return $false }
    }
    return $true
}

function Test-WorkstationInputMethods {
    param([hashtable] $Resource)
    $state = Get-WorkstationInputState -Resource $Resource
    return $state.NeoInstalled -and (Test-WorkstationInputOrder -Resource $Resource -Languages $state.Languages) -and
        $null -ne $state.Override -and $state.Override.InputMethodTip -eq $Resource.default
}

function Set-WorkstationInputMethods {
    param([hashtable] $Resource)
    $state = Get-WorkstationInputState -Resource $Resource
    if (-not $state.NeoInstalled) {
        throw 'Run windows/apply-kbdneo.ps1 as Administrator and restart Windows before applying input methods'
    }
    if (-not (Test-WorkstationInputOrder -Resource $Resource -Languages $state.Languages)) {
        $german = @($state.Languages | Where-Object LanguageTag -EQ 'de-DE')
        if ($german.Count -ne 1) { throw 'The user language list must contain exactly one de-DE entry' }
        $ordered = @($Resource.ordered) + @($german[0].InputMethodTips | Where-Object { $Resource.ordered -notcontains $_ })
        $german[0].InputMethodTips.Clear()
        foreach ($tip in $ordered) { $german[0].InputMethodTips.Add($tip) }
        foreach ($language in $state.Languages) {
            if ($language.LanguageTag -eq 'en-GB' -and $language.InputMethodTips.Count -eq 0) {
                # The placeholder is discarded by Windows when it commits this list.
                $language.InputMethodTips.Add('0407:b0000407')
            }
        }
        Set-WorkstationUserLanguageList -LanguageList $state.Languages
    }
    if ($null -eq $state.Override -or $state.Override.InputMethodTip -ne $Resource.default) {
        Set-WinDefaultInputMethodOverride -InputTip $Resource.default -ErrorAction Stop
    }
}

function Get-WorkstationSettingsNativeApi {
    if ($null -eq $script:WorkstationSettingsNativeApi) {
        $script:WorkstationSettingsNativeApi = 'Workstation.SettingsNativeApi' -as [type]
        if ($null -eq $script:WorkstationSettingsNativeApi) {
            $script:WorkstationSettingsNativeApi = Add-Type -Namespace Workstation -Name SettingsNativeApi -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "SystemParametersInfoW", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = true)]
[return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)]
public static extern bool SetWallpaper(uint action, uint parameter, string value, uint flags);
[System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "SystemParametersInfoW", SetLastError = true)]
[return: System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)]
public static extern bool ClientAreaAnimation(uint action, uint parameter, [System.Runtime.InteropServices.MarshalAs(System.Runtime.InteropServices.UnmanagedType.Bool)] ref bool value, uint flags);
[System.Runtime.InteropServices.DllImport("user32.dll", EntryPoint = "SendMessageTimeoutW", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = true)]
public static extern System.IntPtr SendMessageTimeout(System.IntPtr window, uint message, System.UIntPtr wParam, string lParam, uint flags, uint timeout, out System.UIntPtr result);
'@ -PassThru -ErrorAction Stop
        }
    }
    return $script:WorkstationSettingsNativeApi
}

function Get-WorkstationAnimationEnabled {
    $native = Get-WorkstationSettingsNativeApi
    $enabled = $false
    if (-not $native::ClientAreaAnimation(0x1042, 0, [ref]$enabled, 0)) {
        throw [System.ComponentModel.Win32Exception]::new([System.Runtime.InteropServices.Marshal]::GetLastWin32Error(), 'Could not read Windows animation effects')
    }
    return $enabled
}

function Set-WorkstationAnimationEnabled {
    param([bool] $Enabled)
    $native = Get-WorkstationSettingsNativeApi
    if (-not $native::ClientAreaAnimation(0x1043, 0, [ref]$Enabled, 3)) {
        throw [System.ComponentModel.Win32Exception]::new([System.Runtime.InteropServices.Marshal]::GetLastWin32Error(), 'Could not apply Windows animation effects')
    }
}

function Set-WorkstationWallpaper {
    param([string] $Path)
    $native = Get-WorkstationSettingsNativeApi
    if (-not $native::SetWallpaper(20, 0, $Path, 3)) {
        throw [System.ComponentModel.Win32Exception]::new([System.Runtime.InteropServices.Marshal]::GetLastWin32Error(), 'Could not apply the Windows dark wallpaper')
    }
}

function Send-WorkstationAppearanceNotification {
    $native = Get-WorkstationSettingsNativeApi
    $result = [UIntPtr]::Zero
    if ($native::SendMessageTimeout([IntPtr]0xffff, 0x001a, [UIntPtr]::Zero, 'ImmersiveColorSet', 0x0002, 5000, [ref]$result) -eq [IntPtr]::Zero) {
        throw [System.ComponentModel.Win32Exception]::new([System.Runtime.InteropServices.Marshal]::GetLastWin32Error(), 'Could not notify Windows of appearance changes')
    }
}

function Get-WorkstationAppearanceRegistryResources {
    foreach ($name in @('AppsUseLightTheme', 'SystemUsesLightTheme', 'EnableTransparency')) {
        @{
            path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
            valueName = $name
            ensure = 'present'
            type = 'DWord'
            value = 0
        }
    }
}

function Resolve-WorkstationWallpaperPath {
    param([hashtable] $Resource)
    return [Environment]::ExpandEnvironmentVariables($Resource.wallpaper)
}

function Test-WorkstationWallpaper {
    param([hashtable] $Resource)
    $state = Get-WorkstationRegistryValue -Path 'HKCU:\Control Panel\Desktop' -ValueName 'WallPaper'
    return $state.Exists -and $state.Value -ieq (Resolve-WorkstationWallpaperPath -Resource $Resource)
}

function Test-WorkstationAppearance {
    param([hashtable] $Resource)
    $desired = $true
    foreach ($registry in Get-WorkstationAppearanceRegistryResources) {
        if (-not (Test-WorkstationRegistry -Resource $registry)) { $desired = $false }
    }
    # Active theme files are not part of acceptance. Dark flags and wallpaper are authoritative.
    $wallpaperDesired = Test-WorkstationWallpaper -Resource $Resource
    return $desired -and $wallpaperDesired
}

function Set-WorkstationAppearance {
    param([hashtable] $Resource)
    $changed = $false
    foreach ($registry in Get-WorkstationAppearanceRegistryResources) {
        if (-not (Test-WorkstationRegistry -Resource $registry)) {
            Set-WorkstationRegistry -Resource $registry
            $changed = $true
        }
    }
    if (-not (Test-WorkstationWallpaper -Resource $Resource)) {
        Set-WorkstationWallpaper -Path (Resolve-WorkstationWallpaperPath -Resource $Resource)
        $changed = $true
    }
    if ($changed) { Send-WorkstationAppearanceNotification }
}

function Get-WorkstationTaskbarBytes {
    param([hashtable] $Resource)
    Assert-WorkstationUserRegistryPath -Path $Resource.path
    $state = Get-WorkstationRegistryValue -Path $Resource.path -ValueName $Resource.valueName
    if (-not $state.Exists -or $state.Type -ne 'Binary' -or $state.Value -isnot [byte[]] -or $state.Value.Length -le $Resource.index) {
        throw 'Taskbar Settings must be a binary registry value containing byte 8'
    }
    return ,$state.Value
}

function Test-WorkstationTaskbarVisibility {
    param([hashtable] $Resource)
    $bytes = Get-WorkstationTaskbarBytes -Resource $Resource
    return $bytes[$Resource.index] -eq $Resource.value
}

function Set-WorkstationTaskbarVisibility {
    param([hashtable] $Resource)
    $bytes = Get-WorkstationTaskbarBytes -Resource $Resource
    if ($bytes[$Resource.index] -eq $Resource.value) { return }
    # Clone the provider's buffer so only the persisted replacement is changed.
    $bytes = [byte[]]$bytes.Clone()
    $bytes[$Resource.index] = [byte]$Resource.value
    Set-ItemProperty -LiteralPath $Resource.path -Name $Resource.valueName -Value $bytes -ErrorAction Stop
    Stop-Process -Name explorer -Force -ErrorAction Stop
}

function Test-WorkstationSetting {
    param([Parameter(Mandatory)][hashtable] $Resource)
    switch ($Resource.kind) {
        'registry' { return Test-WorkstationRegistry -Resource $Resource }
        'language' { return Test-WorkstationLanguage -Resource $Resource }
        'inputMethods' { return Test-WorkstationInputMethods -Resource $Resource }
        'appearance' { return Test-WorkstationAppearance -Resource $Resource }
        'animation' { return (Get-WorkstationAnimationEnabled) -eq $Resource.enabled }
        'taskbarVisibility' { return Test-WorkstationTaskbarVisibility -Resource $Resource }
        default { throw "Unknown setting kind: $($Resource.kind)" }
    }
}

function Set-WorkstationSetting {
    param([Parameter(Mandatory)][hashtable] $Resource)
    switch ($Resource.kind) {
        'registry' { Set-WorkstationRegistry -Resource $Resource }
        'language' { Set-WorkstationLanguage -Resource $Resource }
        'inputMethods' { Set-WorkstationInputMethods -Resource $Resource }
        'appearance' { Set-WorkstationAppearance -Resource $Resource }
        'animation' {
            if ((Get-WorkstationAnimationEnabled) -ne $Resource.enabled) { Set-WorkstationAnimationEnabled -Enabled $Resource.enabled }
        }
        'taskbarVisibility' { Set-WorkstationTaskbarVisibility -Resource $Resource }
        default { throw "Unknown setting kind: $($Resource.kind)" }
    }
}
