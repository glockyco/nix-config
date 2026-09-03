{ pkgs, shared }:

let
  wslGit = {
    version = "1.3.1";
    url = "https://github.com/andy-5/wslgit/releases/download/v1.3.1/wslgit.zip";
    archiveSha256 = "88c0ad4c41c9fdcc522436fe7d0c808b192c2e47671816eb067a4d9740bc6807";
    executableSha256 = "f41ca507009b42871c0d55eaab24b41d821d5eb36e109e56e0cbba5020eded58";
    forkIntegrationSha256 = "cf0fde2c68c9bf891353dcc4f148a0fb3a1dd88b121d7d3e3b4c8577d71b9546";
  };
  wslGitJson = builtins.toJSON wslGit;

  zedThemeUrl = "https://raw.githubusercontent.com/catppuccin/zed/b54cb81708d06912d50e6bb9fd2fd2103b9dda25/themes/catppuccin-mauve.json";
  zedThemeSha256 = "2dccb9fb3ff888e646407b4f84d400304553e0d9a9688ac75d0f9fcd3f8bdf6a";
  zedThemeSource = pkgs.fetchurl {
    url = zedThemeUrl;
    hash = "sha256-Lcy5+z/4iOZGQHtPhNQAMEVT4NmpaIrHXQ+fzT+L32o=";
  };

  zedSettings =
    (shared.zedSettings {
      ompCommand = "C:\\Windows\\System32\\wsl.exe";
      fontFamily = "JetBrainsMonoNL NF";
      ompArgs = [
        "--distribution"
        "NixOS"
        "--cd"
        "~"
        "--"
        "omp"
        "acp"
      ];
    })
    // {
      languages.Nix.language_servers = [
        "nixd"
        "!nil"
      ];
      lsp.nixd.binary = {
        path = "nixd";
        ignore_system_version = false;
      };
    };

  powerToysSettings = {
    startup = true;
    run_elevated = false;
    enable_quick_access = false;
    enabled = {
      FancyZones = false;
      "Image Resizer" = false;
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

  reneoSettings = {
    standaloneLayout = "Neo";
    standaloneMode = true;
  };

  catppuccinMocha = {
    name = "Catppuccin Mocha";
    cursorColor = "#F5E0DC";
    selectionBackground = "#585B70";
    background = "#1E1E2E";
    foreground = "#CDD6F4";
    black = "#45475A";
    red = "#F38BA8";
    green = "#A6E3A1";
    yellow = "#F9E2AF";
    blue = "#89B4FA";
    purple = "#F5C2E7";
    cyan = "#94E2D5";
    white = "#BAC2DE";
    brightBlack = "#585B70";
    brightRed = "#F38BA8";
    brightGreen = "#A6E3A1";
    brightYellow = "#F9E2AF";
    brightBlue = "#89B4FA";
    brightPurple = "#F5C2E7";
    brightCyan = "#94E2D5";
    brightWhite = "#A6ADC8";
  };

  terminalSettings = {
    defaultProfileName = "NixOS";
    scheme = catppuccinMocha;
    settings = {
      copyFormatting = "none";
      copyOnSelect = false;
      profiles.defaults = {
        colorScheme = "Catppuccin Mocha";
        font.face = "JetBrainsMonoNL NF";
      };
    };
  };

  zenPolicies = {
    policies = builtins.removeAttrs shared.zenPolicies [ "EnterprisePoliciesEnabled" ];
  };

  terminalSpecificationJson = builtins.toJSON terminalSettings;

  jsonFiles = {
    "fork-wslgit.json" = wslGitJson;
    "zed-catppuccin-theme.json" = builtins.readFile zedThemeSource;
    "power-toys-settings.json" = builtins.toJSON powerToysSettings;
    "reneo-settings.json" = builtins.toJSON reneoSettings;
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
          $bytes = [IO.File]::ReadAllBytes($path)
          if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xef -and $bytes[1] -eq 0xbb -and $bytes[2] -eq 0xbf) { return $false }
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
          $json = $actual | ConvertTo-Json -Depth 100
          [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false))
          ${afterSet}
        '';
      };
      metadata = { inherit description; };
    };

  forkWslGitResource = {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "fork-wslgit";
    dependsOn = [ "package-git-client" ];
    properties = {
      testScript = ''
        $specification = '${wslGitJson}' | ConvertFrom-Json
        $root = Join-Path $env:LOCALAPPDATA 'wslgit'
        $executablePaths = @(
          (Join-Path $root 'cmd\wslgit.exe'),
          (Join-Path $root 'cmd\git.exe'),
          (Join-Path $root 'bin\git.exe')
        )
        foreach ($path in $executablePaths) {
          if (-not (Test-Path -LiteralPath $path)) { return $false }
          if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $specification.executableSha256) { return $false }
        }
        $integration = Join-Path $root 'bin\Fork.RI'
        if (-not (Test-Path -LiteralPath $integration)) { return $false }
        if ((Get-FileHash -LiteralPath $integration -Algorithm SHA256).Hash.ToLowerInvariant() -ne $specification.forkIntegrationSha256) { return $false }
        $systemWslHash = (Get-FileHash -LiteralPath (Join-Path $env:SystemRoot 'System32\wsl.exe') -Algorithm SHA256).Hash
        foreach ($name in @('sh.exe', 'bash.exe')) {
          $path = Join-Path $root "bin\$name"
          if (-not (Test-Path -LiteralPath $path)) { return $false }
          if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $systemWslHash) { return $false }
        }
        if ([Environment]::GetEnvironmentVariable('WSLGIT_DEFAULT_DIST', 'User') -ne 'NixOS') { return $false }
        $settingsPath = Join-Path $env:LOCALAPPDATA 'Fork\settings.json'
        if (-not (Test-Path -LiteralPath $settingsPath)) { return $false }
        try {
          $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
        } catch {
          return $false
        }
        return $settings.GitInstancePath -eq (Join-Path $root 'bin\git.exe')
      '';
      setScript = ''
        $specification = '${wslGitJson}' | ConvertFrom-Json
        $archive = Join-Path $env:TEMP "wslgit-$($specification.version).zip"
        $expanded = Join-Path $env:TEMP "wslgit-$($specification.version)"
        $root = Join-Path $env:LOCALAPPDATA 'wslgit'
        Get-Process -Name Fork -ErrorAction SilentlyContinue | Stop-Process
        try {
          Invoke-WebRequest -Uri $specification.url -OutFile $archive -UseBasicParsing
          if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $specification.archiveSha256) { throw 'wslgit archive checksum mismatch' }
          Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
          Add-Type -AssemblyName System.IO.Compression.FileSystem
          [IO.Compression.ZipFile]::ExtractToDirectory($archive, $expanded)
          Remove-Item -LiteralPath $root -Recurse -Force -ErrorAction SilentlyContinue
          New-Item -ItemType Directory -Path (Join-Path $root 'cmd') -Force | Out-Null
          New-Item -ItemType Directory -Path (Join-Path $root 'bin') -Force | Out-Null
          Copy-Item -LiteralPath (Join-Path $expanded 'wslgit\cmd\wslgit.exe') -Destination (Join-Path $root 'cmd\wslgit.exe')
          Copy-Item -LiteralPath (Join-Path $expanded 'wslgit\cmd\wslgit.exe') -Destination (Join-Path $root 'cmd\git.exe')
          Copy-Item -LiteralPath (Join-Path $expanded 'wslgit\cmd\wslgit.exe') -Destination (Join-Path $root 'bin\git.exe')
          Copy-Item -LiteralPath (Join-Path $expanded 'wslgit\cmd\Fork.RI') -Destination (Join-Path $root 'bin\Fork.RI')
          Copy-Item -LiteralPath (Join-Path $env:SystemRoot 'System32\wsl.exe') -Destination (Join-Path $root 'bin\sh.exe')
          Copy-Item -LiteralPath (Join-Path $env:SystemRoot 'System32\wsl.exe') -Destination (Join-Path $root 'bin\bash.exe')
          [Environment]::SetEnvironmentVariable('WSLGIT_DEFAULT_DIST', 'NixOS', 'User')

          $settingsPath = Join-Path $env:LOCALAPPDATA 'Fork\settings.json'
          New-Item -ItemType Directory -Path (Split-Path -Parent $settingsPath) -Force | Out-Null
          try {
            $settings = if (Test-Path -LiteralPath $settingsPath) { Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json } else { $null }
          } catch {
            $settings = $null
          }
          if ($null -eq $settings) { $settings = [PSCustomObject]@{} }
          $gitPath = Join-Path $root 'bin\git.exe'
          if ($null -eq $settings.PSObject.Properties['GitInstancePath']) {
            $settings | Add-Member -NotePropertyName GitInstancePath -NotePropertyValue $gitPath
          } else {
            $settings.GitInstancePath = $gitPath
          }
          $json = $settings | ConvertTo-Json -Depth 100
          [IO.File]::WriteAllText($settingsPath, $json, [Text.UTF8Encoding]::new($false))
        } finally {
          Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
          Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Process (Join-Path $env:LOCALAPPDATA 'Fork\current\Fork.exe')
      '';
    };
    metadata.description = "Install pinned wslgit and make Fork execute Git inside NixOS";
  };

  zedThemeResource = {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "zed-catppuccin-theme";
    dependsOn = [ "package-editor" ];
    properties = {
      testScript = ''
        $path = Join-Path $env:APPDATA 'Zed\themes\catppuccin-mauve.json'
        if (-not (Test-Path -LiteralPath $path)) { return $false }
        return (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -eq '${zedThemeSha256}'
      '';
      setScript = ''
        $path = Join-Path $env:APPDATA 'Zed\themes\catppuccin-mauve.json'
        $temporary = Join-Path $env:TEMP 'zed-catppuccin-mauve.json'
        try {
          Invoke-WebRequest -Uri '${zedThemeUrl}' -OutFile $temporary -UseBasicParsing
          if ((Get-FileHash -LiteralPath $temporary -Algorithm SHA256).Hash.ToLowerInvariant() -ne '${zedThemeSha256}') { throw 'Zed Catppuccin theme checksum mismatch' }
          New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
          Move-Item -LiteralPath $temporary -Destination $path -Force
        } finally {
          Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
        }
      '';
    };
    metadata.description = "Install the pinned Catppuccin theme for Zed";
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
        $bytes = [IO.File]::ReadAllBytes($path)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xef -and $bytes[1] -eq 0xbb -and $bytes[2] -eq 0xbf) { return $false }
        $actual = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $specification = '${terminalSpecificationJson}' | ConvertFrom-Json
        $profile = $actual.profiles.list | Where-Object name -eq $specification.defaultProfileName | Select-Object -First 1
        if ($null -eq $profile -or $actual.defaultProfile -ne $profile.guid) { return $false }
        $scheme = $actual.schemes | Where-Object name -eq $specification.scheme.name | Select-Object -First 1
        if ($null -eq $scheme -or -not (Test-Subset $scheme $specification.scheme)) { return $false }
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
        $actual.schemes = @($actual.schemes | Where-Object name -ne $specification.scheme.name) + @($specification.scheme)
        Merge-Object $actual $specification.settings
        $json = $actual | ConvertTo-Json -Depth 100
        [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false))
      '';
    };
    metadata.description = "Converge Windows Terminal settings while preserving generated profiles";
  };
in

{
  files = jsonFiles;

  resources = [
    forkWslGitResource
    zedThemeResource
    terminalResource
    (mergeJsonScript {
      name = "zed-settings";
      description = "Converge Zed settings while preserving interface state";
      destination = "Join-Path $env:APPDATA 'Zed\\settings.json'";
      desired = zedSettings;
      dependsOn = [
        "package-editor"
        "package-terminal-font"
        "zed-catppuccin-theme"
      ];
    })
    (mergeJsonScript {
      name = "reneo-settings";
      description = "Select the Neo2 layout while preserving ReNeo state";
      destination = "Join-Path $env:LOCALAPPDATA 'Microsoft\\WinGet\\Packages\\Rojetto.ReNeo.neo2_Microsoft.Winget.Source_8wekyb3d8bbwe\\ReNeo\\config.json'";
      desired = reneoSettings;
      dependsOn = [ "package-keyboard-layout" ];
      beforeSet = ''
        $packagePath = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\Rojetto.ReNeo.neo2_Microsoft.Winget.Source_8wekyb3d8bbwe\ReNeo\*'
        Get-Process -Name reneo -ErrorAction SilentlyContinue | Where-Object { $_.Path -like $packagePath } | Stop-Process
      '';
      afterSet = ''
        Start-Process (Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Packages\Rojetto.ReNeo.neo2_Microsoft.Winget.Source_8wekyb3d8bbwe\ReNeo\reneo.exe')
      '';
    })
    (mergeJsonScript {
      name = "power-toys-settings";
      description = "Enable only Command Palette and Grab And Move in PowerToys";
      destination = "Join-Path $env:LOCALAPPDATA 'Microsoft\\PowerToys\\settings.json'";
      desired = powerToysSettings;
      dependsOn = [ "package-launcher" ];
      beforeSet = ''
        $processes = Get-Process -Name 'PowerToys*' -ErrorAction SilentlyContinue
        $processes | Stop-Process -Force
        $processes | Wait-Process -Timeout 10 -ErrorAction SilentlyContinue
      '';
      afterSet = ''
        Start-Process (Join-Path $env:LOCALAPPDATA 'PowerToys\PowerToys.exe')
      '';
    })
  ];

  inherit
    powerToysSettings
    reneoSettings
    terminalSettings
    zedSettings
    zenPolicies
    ;
}
