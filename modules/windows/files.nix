{ shared }:

let
  zedSettings = shared.zedSettings {
    ompCommand = "C:\\Windows\\System32\\wsl.exe";
    ompArgs = [
      "--distribution"
      "NixOS"
      "--cd"
      "~"
      "--"
      "omp"
      "acp"
    ];
  };

  powerToysSettings = {
    startup = true;
    run_elevated = false;
    enabled = {
      FancyZones = false;
      "Image Resizer" = false;
      "File Explorer" = false;
      "File Explorer Preview" = false;
      "Shortcut Guide" = false;
      PowerRename = false;
      "Keyboard Manager" = false;
      "PowerToys Run" = false;
      ColorPicker = false;
      CropAndLock = false;
      Awake = false;
      MouseWithoutBorders = false;
      FindMyMouse = false;
      AltWindowCycle = false;
      MouseHighlighter = false;
      MouseJump = false;
      AlwaysOnTop = false;
      MousePointerCrosshairs = false;
      QuickAccent = false;
      TextExtractor = false;
      AdvancedPaste = false;
      "Measure Tool" = false;
      Hosts = false;
      "File Locksmith" = false;
      Peek = false;
      RegistryPreview = false;
      CmdNotFound = false;
      EnvironmentVariables = false;
      NewPlus = false;
      Workspaces = false;
      CmdPal = true;
      ZoomIt = false;
      CursorWrap = false;
      LightSwitch = false;
      PowerDisplay = false;
      GrabAndMove = true;
    };
  };

  terminalSettings = {
    defaultProfileName = "NixOS";
    settings = {
      copyFormatting = "none";
      copyOnSelect = false;
      profiles.defaults.font.face = "JetBrainsMonoNL Nerd Font";
    };
  };

  zenPolicies = {
    policies = builtins.removeAttrs shared.zenPolicies [ "EnterprisePoliciesEnabled" ];
  };

  terminalSpecificationJson = builtins.toJSON terminalSettings;

  jsonFiles = {
    "power-toys-settings.json" = builtins.toJSON powerToysSettings;
    "terminal-settings.json" = builtins.toJSON terminalSettings;
    "zed-settings.json" = builtins.toJSON zedSettings;
    "zen-policies.json" = builtins.toJSON zenPolicies;
  };

  mergeJsonScript =
    {
      name,
      description,
      destination,
      desired,
      dependsOn,
      beforeSet ? "",
      afterSet ? "",
    }:
    let
      desiredJson = builtins.toJSON desired;
    in
    {
      type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
      inherit name dependsOn;
      properties = {
        testScript = ''
          function Test-Subset($actual, $desired) {
            foreach ($property in $desired.PSObject.Properties) {
              $actualProperty = $actual.PSObject.Properties[$property.Name]
              if ($null -eq $actualProperty) { return $false }
              if ($property.Value -is [PSCustomObject]) {
                if (-not ($actualProperty.Value -is [PSCustomObject])) { return $false }
                if (-not (Test-Subset $actualProperty.Value $property.Value)) { return $false }
              } elseif (($property.Value | ConvertTo-Json -Depth 100 -Compress) -ne ($actualProperty.Value | ConvertTo-Json -Depth 100 -Compress)) {
                return $false
              }
            }
            return $true
          }

          $path = ${destination}
          if (-not (Test-Path -LiteralPath $path)) { return $false }
          try {
            $actual = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
          } catch {
            return $false
          }
          if ($null -eq $actual) { return $false }
          $desired = '${desiredJson}' | ConvertFrom-Json
          return Test-Subset $actual $desired
        '';
        setScript = ''
          function Merge-Object($actual, $desired) {
            foreach ($property in $desired.PSObject.Properties) {
              $actualProperty = $actual.PSObject.Properties[$property.Name]
              if ($property.Value -is [PSCustomObject] -and $null -ne $actualProperty -and $actualProperty.Value -is [PSCustomObject]) {
                Merge-Object $actualProperty.Value $property.Value
              } elseif ($null -eq $actualProperty) {
                $actual | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value
              } else {
                $actualProperty.Value = $property.Value
              }
            }
          }

          ${beforeSet}
          $path = ${destination}
          $directory = Split-Path -Parent $path
          New-Item -ItemType Directory -Path $directory -Force | Out-Null
          try {
            $actual = if (Test-Path -LiteralPath $path) { Get-Content -LiteralPath $path -Raw | ConvertFrom-Json } else { $null }
          } catch {
            $actual = $null
          }
          if ($null -eq $actual) { $actual = [PSCustomObject]@{} }
          $desired = '${desiredJson}' | ConvertFrom-Json
          Merge-Object $actual $desired
          $actual | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $path -Encoding utf8
          ${afterSet}
        '';
      };
      metadata = { inherit description; };
    };

  terminalResource = {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "windows-terminal-settings";
    dependsOn = [
      "package-terminal"
      "package-terminal-font"
    ];
    properties = {
      testScript = ''
        function Test-Subset($actual, $desired) {
          foreach ($property in $desired.PSObject.Properties) {
            $actualProperty = $actual.PSObject.Properties[$property.Name]
            if ($null -eq $actualProperty) { return $false }
            if ($property.Value -is [PSCustomObject]) {
              if (-not ($actualProperty.Value -is [PSCustomObject])) { return $false }
              if (-not (Test-Subset $actualProperty.Value $property.Value)) { return $false }
            } elseif (($property.Value | ConvertTo-Json -Depth 100 -Compress) -ne ($actualProperty.Value | ConvertTo-Json -Depth 100 -Compress)) {
              return $false
            }
          }
          return $true
        }

        $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
        if (-not (Test-Path -LiteralPath $path)) { return $false }
        $actual = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $specification = '${terminalSpecificationJson}' | ConvertFrom-Json
        $profile = $actual.profiles.list | Where-Object name -eq $specification.defaultProfileName | Select-Object -First 1
        if ($null -eq $profile -or $actual.defaultProfile -ne $profile.guid) { return $false }
        return Test-Subset $actual $specification.settings
      '';
      setScript = ''
        function Merge-Object($actual, $desired) {
          foreach ($property in $desired.PSObject.Properties) {
            $actualProperty = $actual.PSObject.Properties[$property.Name]
            if ($property.Value -is [PSCustomObject] -and $null -ne $actualProperty -and $actualProperty.Value -is [PSCustomObject]) {
              Merge-Object $actualProperty.Value $property.Value
            } elseif ($null -eq $actualProperty) {
              $actual | Add-Member -NotePropertyName $property.Name -NotePropertyValue $property.Value
            } else {
              $actualProperty.Value = $property.Value
            }
          }
        }

        $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
        $actual = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $specification = '${terminalSpecificationJson}' | ConvertFrom-Json
        $profile = $actual.profiles.list | Where-Object name -eq $specification.defaultProfileName | Select-Object -First 1
        if ($null -eq $profile) { throw "Windows Terminal has no $($specification.defaultProfileName) profile" }
        $actual.defaultProfile = $profile.guid
        Merge-Object $actual $specification.settings
        $actual | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $path -Encoding utf8
      '';
    };
    metadata.description = "Converge Windows Terminal settings while preserving generated profiles";
  };
in

{
  files = jsonFiles;

  resources = [
    terminalResource
    (mergeJsonScript {
      name = "zed-settings";
      description = "Converge Zed settings while preserving interface state";
      destination = "Join-Path $env:APPDATA 'Zed\\settings.json'";
      desired = zedSettings;
      dependsOn = [
        "package-editor"
        "package-terminal-font"
      ];
    })
    (mergeJsonScript {
      name = "power-toys-settings";
      description = "Enable only Command Palette and Grab And Move in PowerToys";
      destination = "Join-Path $env:LOCALAPPDATA 'Microsoft\\PowerToys\\settings.json'";
      desired = powerToysSettings;
      dependsOn = [ "package-launcher" ];
      beforeSet = ''
        Get-Process -Name 'PowerToys*' -ErrorAction SilentlyContinue | Stop-Process -Force
      '';
      afterSet = ''
        Start-Process (Join-Path $env:LOCALAPPDATA 'PowerToys\PowerToys.exe')
      '';
    })
  ];

  inherit
    powerToysSettings
    terminalSettings
    zedSettings
    zenPolicies
    ;
}
