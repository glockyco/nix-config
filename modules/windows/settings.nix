let
  registry =
    {
      name,
      keyPath,
      valueName,
      valueData,
      description,
    }:
    {
      type = "Microsoft.Windows/Registry";
      inherit name;
      properties = {
        inherit keyPath valueData valueName;
        _exist = true;
      };
      metadata = { inherit description; };
    };
in

[
  (registry {
    name = "keyboard-repeat-delay";
    keyPath = "HKCU\\Control Panel\\Keyboard";
    valueName = "KeyboardDelay";
    valueData.String = "0";
    description = "Use the shortest Windows keyboard repeat delay";
  })
  (registry {
    name = "keyboard-repeat-rate";
    keyPath = "HKCU\\Control Panel\\Keyboard";
    valueName = "KeyboardSpeed";
    valueData.String = "31";
    description = "Use the fastest Windows keyboard repeat rate";
  })
  (registry {
    name = "explorer-show-extensions";
    keyPath = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced";
    valueName = "HideFileExt";
    valueData.DWord = 0;
    description = "Show file-name extensions in File Explorer";
  })
  (registry {
    name = "explorer-show-hidden-files";
    keyPath = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced";
    valueName = "Hidden";
    valueData.DWord = 1;
    description = "Show hidden files in File Explorer";
  })
  (registry {
    name = "explorer-general-folder-template";
    keyPath = "HKCU\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\Bags\\AllFolders\\Shell";
    valueName = "FolderType";
    valueData.String = "NotSpecified";
    description = "Use one general File Explorer folder template";
  })
  (registry {
    name = "explorer-details-view";
    keyPath = "HKCU\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\Bags\\AllFolders\\Shell";
    valueName = "Mode";
    valueData.DWord = 4;
    description = "Use the details view in File Explorer";
  })
  (registry {
    name = "explorer-details-layout";
    keyPath = "HKCU\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\Bags\\AllFolders\\Shell";
    valueName = "LogicalViewMode";
    valueData.DWord = 1;
    description = "Use the details layout in File Explorer";
  })
  (registry {
    name = "explorer-name-sort";
    keyPath = "HKCU\\Software\\Classes\\Local Settings\\Software\\Microsoft\\Windows\\Shell\\Bags\\AllFolders\\Shell";
    valueName = "Sort";
    valueData.String = "prop:System.ItemNameDisplay;";
    description = "Sort File Explorer folders by item name";
  })
  (registry {
    name = "region-short-time";
    keyPath = "HKCU\\Control Panel\\International";
    valueName = "sShortTime";
    valueData.String = "HH:mm";
    description = "Use 24-hour short times";
  })
  (registry {
    name = "region-long-time";
    keyPath = "HKCU\\Control Panel\\International";
    valueName = "sTimeFormat";
    valueData.String = "HH:mm:ss";
    description = "Use 24-hour long times";
  })
  (registry {
    name = "region-metric-units";
    keyPath = "HKCU\\Control Panel\\International";
    valueName = "iMeasure";
    valueData.String = "0";
    description = "Use metric measurements and Celsius";
  })
  (registry {
    name = "window-snapping";
    keyPath = "HKCU\\Control Panel\\Desktop";
    valueName = "WindowArrangementActive";
    valueData.String = "1";
    description = "Enable window snapping";
  })
  (registry {
    name = "snap-assist";
    keyPath = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced";
    valueName = "SnapAssist";
    valueData.DWord = 1;
    description = "Suggest adjacent windows after snapping";
  })
  (registry {
    name = "snap-fill";
    keyPath = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced";
    valueName = "SnapFill";
    valueData.DWord = 1;
    description = "Resize adjacent snapped windows together";
  })
  (registry {
    name = "snap-bar";
    keyPath = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced";
    valueName = "Snapbar";
    valueData.DWord = 1;
    description = "Show snap layouts when dragging a window to the screen top";
  })
  (registry {
    name = "snap-layout-flyout";
    keyPath = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Advanced";
    valueName = "EnableSnapAssistFlyout";
    valueData.DWord = 1;
    description = "Show snap layouts over a maximize button";
  })
  (registry {
    name = "window-tool-startup";
    keyPath = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run";
    valueName = "AltSnap";
    valueData.ExpandString = ''"%APPDATA%\AltSnap\AltSnap.exe"'';
    description = "Start AltSnap for the interactive user at logon";
  })
  {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "native-neo-input-method";
    properties = {
      testScript = ''
        $inputTip = '0407:b0000407'
        $override = Get-WinDefaultInputMethodOverride
        $registered = $false
        foreach ($language in Get-WinUserLanguageList) {
          if ($language.InputMethodTips -contains $inputTip) { $registered = $true }
        }
        return $registered -and $null -ne $override -and $override.InputMethodTip -eq $inputTip
      '';
      setScript = ''
        $inputTip = '0407:b0000407'
        if (-not (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\b0000407')) {
          throw 'Run apply-kbdneo.ps1 as Administrator and restart Windows before applying the WinGet document'
        }
        $languages = Get-WinUserLanguageList
        $german = @($languages | Where-Object LanguageTag -eq 'de-DE')
        if ($german.Count -ne 1) { throw 'The user language list must contain exactly one de-DE entry' }
        if ($german[0].InputMethodTips -notcontains $inputTip) {
          $german[0].InputMethodTips.Add($inputTip)
          Set-WinUserLanguageList -LanguageList $languages -Force
        }
        Set-WinDefaultInputMethodOverride -InputTip $inputTip
      '';
    };
    metadata.description = "Select the native Neo2 layout for the interactive user";
  }
  (registry {
    name = "keyboard-layout-startup";
    keyPath = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run";
    valueName = "ReNeo";
    valueData.ExpandString = ''"%LOCALAPPDATA%\Microsoft\WinGet\Packages\Rojetto.ReNeo.neo2_Microsoft.Winget.Source_8wekyb3d8bbwe\ReNeo\reneo.exe"'';
    description = "Start the Neo2 keyboard layout for the interactive user at logon";
  })
  (registry {
    name = "screenshot-folder";
    keyPath = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders";
    valueName = "{B7BEDE81-DF94-4682-A7D8-57A52620B86F}";
    valueData.ExpandString = "%USERPROFILE%\\Pictures\\Screenshots";
    description = "Store screenshots under the user Pictures directory";
  })
  {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "windows-dark-appearance";
    properties = {
      testScript = ''
        $personalize = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -ErrorAction SilentlyContinue
        $themes = Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes' -ErrorAction SilentlyContinue
        $desktop = Get-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -ErrorAction SilentlyContinue
        $theme = Join-Path $env:WINDIR 'Resources\Themes\dark.theme'
        $wallpaper = Join-Path $env:WINDIR 'Web\Wallpaper\Windows\img19.jpg'
        return $personalize.AppsUseLightTheme -eq 0 `
          -and $personalize.SystemUsesLightTheme -eq 0 `
          -and $personalize.EnableTransparency -eq 1 `
          -and $themes.CurrentTheme -ieq $theme `
          -and $desktop.WallPaper -ieq $wallpaper
      '';
      setScript = ''
        $personalizePath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        $themesPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes'
        $theme = Join-Path $env:WINDIR 'Resources\Themes\dark.theme'
        $wallpaper = Join-Path $env:WINDIR 'Web\Wallpaper\Windows\img19.jpg'
        New-Item -Path $personalizePath -Force | Out-Null
        New-Item -Path $themesPath -Force | Out-Null
        New-ItemProperty -Path $personalizePath -Name AppsUseLightTheme -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $personalizePath -Name SystemUsesLightTheme -Value 0 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $personalizePath -Name EnableTransparency -Value 1 -PropertyType DWord -Force | Out-Null
        New-ItemProperty -Path $themesPath -Name CurrentTheme -Value $theme -PropertyType String -Force | Out-Null
        $native = Add-Type -Namespace WindowsConfiguration -Name AppearanceApi -MemberDefinition @'
          [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = true)]
          public static extern bool SystemParametersInfo(uint action, uint parameter, string value, uint flags);
          [System.Runtime.InteropServices.DllImport("user32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode, SetLastError = true)]
          public static extern System.IntPtr SendMessageTimeout(System.IntPtr window, uint message, System.UIntPtr wParam, string lParam, uint flags, uint timeout, out System.UIntPtr result);
        '@ -PassThru
        if (-not $native::SystemParametersInfo(20, 0, $wallpaper, 3)) { throw 'Could not apply the Windows dark wallpaper' }
        $broadcastResult = [UIntPtr]::Zero
        [void]$native::SendMessageTimeout([IntPtr]0xffff, 0x001a, [UIntPtr]::Zero, 'ImmersiveColorSet', 0x0002, 5000, [ref]$broadcastResult)
      '';
    };
    metadata.description = "Apply the built-in Windows dark theme and Bloom wallpaper";
  }
  {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "taskbar-visible";
    properties = {
      testScript = ''
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
        $bytes = (Get-ItemProperty -Path $path -Name Settings).Settings
        return ($bytes[8] -eq 2)
      '';
      setScript = ''
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
        $bytes = (Get-ItemProperty -Path $path -Name Settings).Settings
        $bytes[8] = 2
        Set-ItemProperty -Path $path -Name Settings -Value $bytes
        Stop-Process -Name explorer -Force
      '';
    };
    metadata.description = "Keep the taskbar visible while preserving the rest of its binary settings";
  }
]
