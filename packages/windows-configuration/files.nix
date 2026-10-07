{
  lib,
  pkgs,
  shared,
  byRole,
  applicationMetadata,
  powershell,
}:

let
  altSnapApplication = byRole "window-tool";
  reneoApplication = byRole "keyboard-layout";
  altSnapPackage = {
    inherit (altSnapApplication) version;
  }
  // altSnapApplication.release;
  altSnapPackageJson = builtins.toJSON altSnapPackage;

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
    hash = builtins.convertHash {
      hash = zedThemeSha256;
      hashAlgo = "sha256";
      toHashFormat = "sri";
    };
  };

  zenTheme = {
    commit = "c855685442c6040c4dda9c8d3ddc7b708de1cbaa";
    flavor = "Mocha";
    accent = "Mauve";
    preference = {
      name = "toolkit.legacyUserProfileCustomizations.stylesheets";
      value = true;
    };
    files = {
      "userChrome.css" = {
        url = "https://raw.githubusercontent.com/catppuccin/zen-browser/c855685442c6040c4dda9c8d3ddc7b708de1cbaa/themes/Mocha/Mauve/userChrome.css";
        sha256 = "98ba97510bf2ecd8636686238242cb0f2e43552e2bb93c520818ed89da92189b";
      };
      "userContent.css" = {
        url = "https://raw.githubusercontent.com/catppuccin/zen-browser/c855685442c6040c4dda9c8d3ddc7b708de1cbaa/themes/Mocha/Mauve/userContent.css";
        sha256 = "297a3c45e624792892482ab45552625b2765e6d44947e878fe5c5731eb7cd44a";
      };
      "zen-logo.svg" = {
        url = "https://raw.githubusercontent.com/catppuccin/zen-browser/c855685442c6040c4dda9c8d3ddc7b708de1cbaa/themes/Mocha/Mauve/zen-logo-mocha.svg";
        sha256 = "b41be8bf6c8659c532a0b1b984488696073adb31aec7a089211d4f4a7ecd9a83";
      };
    };
  };
  zenThemeSources = builtins.mapAttrs (
    _: file:
    pkgs.fetchurl {
      inherit (file) url;
      hash = builtins.convertHash {
        hash = file.sha256;
        hashAlgo = "sha256";
        toHashFormat = "sri";
      };
    }
  ) zenTheme.files;
  zenThemeJson = builtins.toJSON zenTheme;

  zedSettings =
    (shared.zedSettings {
      fontFamily = "JetBrainsMonoNL NF";
    })
    // {
      languages.Nix.language_servers = [
        "nixd"
        "!nil"
      ];
      lsp = {
        nixd.binary = {
          path = "nixd";
          ignore_system_version = false;
        };
        texlab.settings.texlab.build.onSave = true;
      };
    };

  zedControlBindings = {
    "ctrl-a" = "editor::SelectAll";
    "ctrl-b" = "workspace::ToggleLeftDock";
    "ctrl-c" = "editor::Copy";
    "ctrl-d" = [
      "editor::SelectNext"
      { replace_newest = false; }
    ];
    "ctrl-e" = "file_finder::Toggle";
    "ctrl-f" = "buffer_search::Deploy";
    "ctrl-g" = "go_to_line::Toggle";
    "ctrl-h" = "buffer_search::DeployReplace";
    "ctrl-i" = "editor::ShowSignatureHelp";
    "ctrl-j" = "workspace::ToggleBottomDock";
    "ctrl-l" = "editor::SelectLine";
    "ctrl-n" = "workspace::NewFile";
    "ctrl-o" = "workspace::OpenFiles";
    "ctrl-p" = "file_finder::Toggle";
    "ctrl-q" = "zed::Quit";
    "ctrl-r" = "projects::OpenRecent";
    "ctrl-s" = "workspace::Save";
    "ctrl-t" = "project_symbols::Toggle";
    "ctrl-v" = "editor::Paste";
    "ctrl-w" = [
      "pane::CloseActiveItem"
      { close_pinned = false; }
    ];
    "ctrl-x" = "editor::Cut";
    "ctrl-y" = "editor::Redo";
    "ctrl-z" = "editor::Undo";
  };
  zedKeymap = [
    {
      context = "Editor && mode == full";
      bindings = builtins.mapAttrs (_: _: null) zedControlBindings // {
        "ctrl-[" = null;
        "ctrl-]" = null;
        "ctrl-^" = null;
        "ctrl-k" = null;
        "ctrl-m" = null;
        "ctrl-u" = null;
      };
    }
    {
      context = "Editor && mode == full";
      bindings = zedControlBindings;
    }
  ];
  zedKeymapJson = builtins.toJSON zedKeymap;

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
      GrabAndMove = false;
    };
  };

  altSnapSettings.General = {
    Aero = "1";
    SmartAero = "1";
    AutoSnap = "2";
    AeroHoffset = "50";
    AeroVoffset = "50";
  };

  reneoSettings = {
    standaloneLayout = "Neo";
    standaloneMode = true;
  };
  reneoPackageDirectory = "Microsoft\\WinGet\\Packages\\${reneoApplication.id}_Microsoft.Winget.Source_8wekyb3d8bbwe\\ReNeo";
  reneoElevationLauncher = ''
    $ErrorActionPreference = 'Stop'
    $path = Join-Path $env:LOCALAPPDATA '${reneoPackageDirectory}\reneo.exe'
    if (-not (Test-Path -LiteralPath $path)) { throw "ReNeo is not installed at $path" }
    if (@(Get-Process -Name reneo -ErrorAction SilentlyContinue).Count -gt 0) { exit 0 }
    Start-Process -FilePath $path -Verb RunAs
  '';

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
    policies = shared.zenPolicies;
  };

  jsonFiles = {
    "altsnap-settings.json" = builtins.toJSON altSnapSettings;
    "fork-wslgit.json" = wslGitJson;
    "zed-keymap.json" = zedKeymapJson;
    "power-toys-settings.json" = builtins.toJSON powerToysSettings;
    "terminal-settings.json" = builtins.toJSON terminalSettings;
    "zed-settings.json" = builtins.toJSON zedSettings;
    "zen-catppuccin.json" = zenThemeJson;
    "zen-policies.json" = builtins.toJSON zenPolicies;
  }
  // lib.optionalAttrs (altSnapApplication != null) {
    "altsnap-package.json" = altSnapPackageJson;
  }
  // lib.optionalAttrs (reneoApplication != null) {
    "reneo-settings.json" = builtins.toJSON reneoSettings;
    "start-reneo-elevated.ps1" = reneoElevationLauncher;
  };
  assets = {
    "zed-catppuccin-theme.json" = zedThemeSource;
    "zen-catppuccin-userChrome.css" = zenThemeSources."userChrome.css";
    "zen-catppuccin-userContent.css" = zenThemeSources."userContent.css";
    "zen-catppuccin-logo.svg" = zenThemeSources."zen-logo.svg";
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
    {
      type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
      inherit name dependsOn;
      properties = {
        testScript = ''
          ${powershell.testSubsetFunction}

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
          $desired = ${powershell.psJson desired} | ConvertFrom-Json
          return Test-Subset $actual $desired
        '';
        setScript = ''
          ${powershell.mergeObjectFunction}

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
          $desired = ${powershell.psJson desired} | ConvertFrom-Json
          Merge-Object $actual $desired
          $json = $actual | ConvertTo-Json -Depth 100
          [IO.File]::WriteAllText($path, $json, [Text.UTF8Encoding]::new($false))
          ${afterSet}
        '';
      };
      metadata = { inherit description; };
    };

  zedKeymapResource = {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "zed-keymap";
    dependsOn = [ "package-editor" ];
    properties = {
      testScript = ''
        $path = Join-Path $env:APPDATA 'Zed\keymap.json'
        if (-not (Test-Path -LiteralPath $path)) { return $false }
        $bytes = [IO.File]::ReadAllBytes($path)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xef -and $bytes[1] -eq 0xbb -and $bytes[2] -eq 0xbf) { return $false }
        return [IO.File]::ReadAllText($path) -ceq ${powershell.psJson zedKeymap}
      '';
      setScript = ''
        $path = Join-Path $env:APPDATA 'Zed\keymap.json'
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        [IO.File]::WriteAllText($path, ${powershell.psJson zedKeymap}, [Text.UTF8Encoding]::new($false))
      '';
    };
    metadata.description = "Enforce the Windows-first Zed keymap";
  };

  altSnapResource = {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "package-window-tool";
    properties = {
      testScript = ''
        $package = ${powershell.psJson altSnapPackage} | ConvertFrom-Json
        $desired = ${powershell.psJson altSnapSettings} | ConvertFrom-Json
        $root = Join-Path $env:APPDATA 'AltSnap'
        $path = Join-Path $root 'AltSnap.ini'
        $executable = Join-Path $root 'AltSnap.exe'
        $hooks = Join-Path $root 'hooks.dll'
        if (-not (Test-Path -LiteralPath $executable) -or ${powershell.sha256Of "$executable"} -ne $package.executableSha256) { return $false }
        if (-not (Test-Path -LiteralPath $hooks) -or ${powershell.sha256Of "$hooks"} -ne $package.hooksSha256) { return $false }
        if (-not (Test-Path -LiteralPath $path)) { return $false }
        $ini = Add-Type -Namespace WindowsConfiguration -Name AltSnapIniReadApi -MemberDefinition @'
          [System.Runtime.InteropServices.DllImport("kernel32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
          public static extern uint GetPrivateProfileString(string section, string key, string defaultValue, System.Text.StringBuilder value, uint size, string filePath);
        '@ -PassThru
        foreach ($section in $desired.PSObject.Properties) {
          foreach ($setting in $section.Value.PSObject.Properties) {
            $value = New-Object Text.StringBuilder 256
            [void]$ini::GetPrivateProfileString($section.Name, $setting.Name, [string]::Empty, $value, $value.Capacity, $path)
            if ($value.ToString() -ne [string]$setting.Value) { return $false }
          }
        }
        return $true
      '';
      setScript = ''
        $package = ${powershell.psJson altSnapPackage} | ConvertFrom-Json
        $desired = ${powershell.psJson altSnapSettings} | ConvertFrom-Json
        $root = Join-Path $env:APPDATA 'AltSnap'
        $path = Join-Path $root 'AltSnap.ini'
        $archive = Join-Path $env:TEMP "AltSnap-$($package.version).zip"
        $expanded = Join-Path $env:TEMP "AltSnap-$($package.version)"
        Get-Process -Name AltSnap -ErrorAction SilentlyContinue | Stop-Process
        try {
          ${powershell.expandArchive {
            variable = "$package";
            label = "AltSnap";
          }}
          if (${powershell.sha256Of "(Join-Path $expanded 'AltSnap.exe')"} -ne $package.executableSha256) { throw 'AltSnap executable checksum mismatch' }
          if (${powershell.sha256Of "(Join-Path $expanded 'hooks.dll')"} -ne $package.hooksSha256) { throw 'AltSnap hooks checksum mismatch' }
          New-Item -ItemType Directory -Path $root -Force | Out-Null
          Get-ChildItem -LiteralPath $expanded -Force | Where-Object Name -ne 'AltSnap.ini' | Copy-Item -Destination $root -Recurse -Force
          if (-not (Test-Path -LiteralPath $path)) { Copy-Item -LiteralPath (Join-Path $expanded 'AltSnap.ini') -Destination $path }
        } finally {
          Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
          Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
        }
        $ini = Add-Type -Namespace WindowsConfiguration -Name AltSnapIniWriteApi -MemberDefinition @'
          [System.Runtime.InteropServices.DllImport("kernel32.dll", CharSet = System.Runtime.InteropServices.CharSet.Unicode)]
          public static extern bool WritePrivateProfileString(string section, string key, string value, string filePath);
        '@ -PassThru
        foreach ($section in $desired.PSObject.Properties) {
          foreach ($setting in $section.Value.PSObject.Properties) {
            if (-not $ini::WritePrivateProfileString($section.Name, $setting.Name, [string]$setting.Value, $path)) { throw "Could not write AltSnap setting $($section.Name).$($setting.Name)" }
          }
        }
        Start-Process (Join-Path $root 'AltSnap.exe')
      '';
    };
    metadata = {
      description = "Install portable AltSnap with modifier dragging and 50/50 edge snapping";
      application = applicationMetadata altSnapApplication;
    };
  };

  forkWslGitResource = {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "fork-wslgit";
    dependsOn = [ "package-git-client" ];
    properties = {
      testScript = ''
        $specification = ${powershell.psJson wslGit} | ConvertFrom-Json
        $root = Join-Path $env:LOCALAPPDATA 'wslgit'
        $executablePaths = @(
          (Join-Path $root 'cmd\wslgit.exe'),
          (Join-Path $root 'cmd\git.exe'),
          (Join-Path $root 'bin\git.exe')
        )
        foreach ($path in $executablePaths) {
          if (-not (Test-Path -LiteralPath $path)) { return $false }
          if (${powershell.sha256Of "$path"} -ne $specification.executableSha256) { return $false }
        }
        $integration = Join-Path $root 'bin\Fork.RI'
        if (-not (Test-Path -LiteralPath $integration)) { return $false }
        if (${powershell.sha256Of "$integration"} -ne $specification.forkIntegrationSha256) { return $false }
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
        ${powershell.mergeObjectFunction}

        $specification = ${powershell.psJson wslGit} | ConvertFrom-Json
        $archive = Join-Path $env:TEMP "wslgit-$($specification.version).zip"
        $expanded = Join-Path $env:TEMP "wslgit-$($specification.version)"
        $root = Join-Path $env:LOCALAPPDATA 'wslgit'
        Get-Process -Name Fork -ErrorAction SilentlyContinue | Stop-Process
        try {
          ${powershell.expandArchive {
            variable = "$specification";
            label = "wslgit";
          }}
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
          Merge-Object $settings ([PSCustomObject]@{ GitInstancePath = (Join-Path $root 'bin\git.exe') })
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
        return ${powershell.sha256Of "$path"} -eq '${zedThemeSha256}'
      '';
      setScript = ''
        $path = Join-Path $env:APPDATA 'Zed\themes\catppuccin-mauve.json'
        $temporary = Join-Path $env:TEMP 'zed-catppuccin-mauve.json'
        try {
          Invoke-WebRequest -Uri '${zedThemeUrl}' -OutFile $temporary -UseBasicParsing
          if (${powershell.sha256Of "$temporary"} -ne '${zedThemeSha256}') { throw 'Zed Catppuccin theme checksum mismatch' }
          New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
          Move-Item -LiteralPath $temporary -Destination $path -Force
        } finally {
          Remove-Item -LiteralPath $temporary -Force -ErrorAction SilentlyContinue
        }
      '';
    };
    metadata.description = "Install the pinned Catppuccin theme for Zed";
  };

  zenThemeResource = {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "zen-catppuccin-theme";
    dependsOn = [ "package-browser" ];
    properties = {
      testScript = ''
        $specification = ${powershell.psJson zenTheme} | ConvertFrom-Json
        $profilesIni = Join-Path $env:APPDATA 'zen\profiles.ini'
        if (-not (Test-Path -LiteralPath $profilesIni)) { return $false }
        $profilePaths = @(Select-String -LiteralPath $profilesIni -Pattern '^Path=(.+)$' | ForEach-Object { $_.Matches[0].Groups[1].Value })
        if ($profilePaths.Count -eq 0) { return $false }
        $preferenceLine = "user_pref(`"$($specification.preference.name)`", $($specification.preference.value | ConvertTo-Json -Compress));"
        foreach ($profilePath in $profilePaths) {
          $profile = Join-Path (Split-Path -Parent $profilesIni) $profilePath.Replace('/', '\')
          $chrome = Join-Path $profile 'chrome'
          $userJs = Join-Path $profile 'user.js'
          if (-not (Test-Path -LiteralPath $userJs) -or (Get-Content -LiteralPath $userJs) -notcontains $preferenceLine) { return $false }
          foreach ($file in $specification.files.PSObject.Properties) {
            $path = Join-Path $chrome $file.Name
            if (-not (Test-Path -LiteralPath $path)) { return $false }
            if (${powershell.sha256Of "$path"} -ne $file.Value.sha256) { return $false }
          }
        }
        return $true
      '';
      setScript = ''
        $specification = ${powershell.psJson zenTheme} | ConvertFrom-Json
        $profilesIni = Join-Path $env:APPDATA 'zen\profiles.ini'
        if (-not (Test-Path -LiteralPath $profilesIni)) { throw 'Launch Zen once to create its user profile, then reapply the configuration' }
        $profilePaths = @(Select-String -LiteralPath $profilesIni -Pattern '^Path=(.+)$' | ForEach-Object { $_.Matches[0].Groups[1].Value })
        if ($profilePaths.Count -eq 0) { throw 'Zen profiles.ini contains no profile path' }
        $temporary = Join-Path $env:TEMP 'zen-catppuccin-mocha-mauve'
        Get-Process -Name zen -ErrorAction SilentlyContinue | Stop-Process
        try {
          Remove-Item -LiteralPath $temporary -Recurse -Force -ErrorAction SilentlyContinue
          New-Item -ItemType Directory -Path $temporary -Force | Out-Null
          foreach ($file in $specification.files.PSObject.Properties) {
            $download = Join-Path $temporary $file.Name
            Invoke-WebRequest -Uri $file.Value.url -OutFile $download -UseBasicParsing
            if (${powershell.sha256Of "$download"} -ne $file.Value.sha256) { throw "Zen Catppuccin checksum mismatch for $($file.Name)" }
          }
          $preferenceLine = "user_pref(`"$($specification.preference.name)`", $($specification.preference.value | ConvertTo-Json -Compress));"
          $preferencePattern = '^\s*user_pref\("' + [regex]::Escape($specification.preference.name) + '"\s*,'
          foreach ($profilePath in $profilePaths) {
            $profile = Join-Path (Split-Path -Parent $profilesIni) $profilePath.Replace('/', '\')
            $chrome = Join-Path $profile 'chrome'
            $userJs = Join-Path $profile 'user.js'
            New-Item -ItemType Directory -Path $chrome -Force | Out-Null
            foreach ($file in $specification.files.PSObject.Properties) {
              Copy-Item -LiteralPath (Join-Path $temporary $file.Name) -Destination (Join-Path $chrome $file.Name) -Force
            }
            $userPreferences = if (Test-Path -LiteralPath $userJs) { @(Get-Content -LiteralPath $userJs | Where-Object { $_ -notmatch $preferencePattern }) } else { @() }
            $userPreferences += $preferenceLine
            [IO.File]::WriteAllLines($userJs, [string[]]$userPreferences, [Text.UTF8Encoding]::new($false))
          }
        } finally {
          Remove-Item -LiteralPath $temporary -Recurse -Force -ErrorAction SilentlyContinue
        }
        Start-Process (Join-Path $env:ProgramFiles 'Zen Browser\zen.exe')
      '';
    };
    metadata.description = "Install the pinned Catppuccin Mocha Mauve theme in every Zen profile";
  };

  reneoElevationResource = {
    type = "Microsoft.DSC.Transitional/WindowsPowerShellScript";
    name = "reneo-elevation-launcher";
    dependsOn = [ "package-keyboard-layout" ];
    properties = {
      testScript = ''
        $path = Join-Path $env:LOCALAPPDATA 'WindowsConfiguration\start-reneo-elevated.ps1'
        $desired = ${powershell.psHereString reneoElevationLauncher}
        return (Test-Path -LiteralPath $path) -and [IO.File]::ReadAllText($path) -eq $desired
      '';
      setScript = ''
        $path = Join-Path $env:LOCALAPPDATA 'WindowsConfiguration\start-reneo-elevated.ps1'
        $desired = ${powershell.psHereString reneoElevationLauncher}
        New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
        [IO.File]::WriteAllText($path, $desired, [Text.UTF8Encoding]::new($false))
      '';
    };
    metadata.description = "Install the ReNeo launcher that requests Administrator credentials at logon";
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
        ${powershell.testSubsetFunction}

        $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
        if (-not (Test-Path -LiteralPath $path)) { return $false }
        $bytes = [IO.File]::ReadAllBytes($path)
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xef -and $bytes[1] -eq 0xbb -and $bytes[2] -eq 0xbf) { return $false }
        $actual = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $specification = ${powershell.psJson terminalSettings} | ConvertFrom-Json
        $profile = $actual.profiles.list | Where-Object name -eq $specification.defaultProfileName | Select-Object -First 1
        if ($null -eq $profile -or $actual.defaultProfile -ne $profile.guid) { return $false }
        $scheme = $actual.schemes | Where-Object name -eq $specification.scheme.name | Select-Object -First 1
        if ($null -eq $scheme -or -not (Test-Subset $scheme $specification.scheme)) { return $false }
        return Test-Subset $actual $specification.settings
      '';
      setScript = ''
        ${powershell.mergeObjectFunction}

        $path = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
        $actual = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        $specification = ${powershell.psJson terminalSettings} | ConvertFrom-Json
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
  inherit assets;

  resources = builtins.filter (resource: resource != null) [
    (if altSnapApplication == null then null else altSnapResource)
    forkWslGitResource
    zedThemeResource
    zenThemeResource
    (if reneoApplication == null then null else reneoElevationResource)
    terminalResource
    zedKeymapResource
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
    (
      if reneoApplication == null then
        null
      else
        mergeJsonScript {
          name = "reneo-settings";
          description = "Run ReNeo's Neo2 layout over QWERTZ while preserving ReNeo state";
          destination = "Join-Path $env:LOCALAPPDATA '${reneoPackageDirectory}\\config.json'";
          desired = reneoSettings;
          dependsOn = [
            "package-keyboard-layout"
            "german-input-methods"
          ];
        }
    )
    (mergeJsonScript {
      name = "power-toys-settings";
      description = "Enable only Command Palette in PowerToys";
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

  inherit zenPolicies;
}
