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
    name = "keyboard-layout-startup";
    keyPath = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run";
    valueName = "ReNeo";
    valueData.ExpandString = ''"%LOCALAPPDATA%\\Microsoft\\WinGet\\Packages\\Rojetto.ReNeo.neo2_Microsoft.Winget.Source_8wekyb3d8bbwe\\ReNeo\\reneo.exe"'';
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
    name = "taskbar-auto-hide";
    properties = {
      testScript = ''
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
        $bytes = (Get-ItemProperty -Path $path -Name Settings).Settings
        return ($bytes[8] -eq 3)
      '';
      setScript = ''
        $path = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3'
        $bytes = (Get-ItemProperty -Path $path -Name Settings).Settings
        $bytes[8] = 3
        Set-ItemProperty -Path $path -Name Settings -Value $bytes
        Stop-Process -Name explorer -Force
      '';
    };
    metadata.description = "Enable taskbar auto-hide while preserving the rest of its binary settings";
  }
]
