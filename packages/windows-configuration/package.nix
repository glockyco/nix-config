{ lib, pkgs }:

let
  applications = import ./applications.nix;
  managedApplications = import ./managed-applications.nix;
  shared = import ../../modules/shared;
  powershell = import ./powershell.nix { inherit lib; };
  byRole = role: lib.findFirst (application: application.role == role) null applications;
  applicationMetadata =
    application:
    {
      inherit (application) id scope source;
      roles = [ application.role ];
      versionPolicy = application.versionPolicy or null;
    }
    // lib.optionalAttrs (application ? version) {
      inherit (application) version;
    };
  applicationFiles = import ./files.nix {
    inherit
      lib
      pkgs
      shared
      byRole
      applicationMetadata
      powershell
      ;
  };
  kbdNeo = {
    version = "2022-10-04";
    url = "https://dl.neo-layout.org/kbdneo64.zip";
    archiveSha256 = "66f8e7f18c95a9a4416acc3d3eb52afcdbc2a3278a7286136c574b3271add84c";
    system32Sha256 = "c5248c7b4024a2fdac956311a73a17428eab5fd54d59908a4a020501a49b775d";
    sysWow64Sha256 = "c10dfdb1ffd19f1a21b76f7288d3dde200ee19907bacd3acad8a70b19d887480";
    layoutId = "b0000407";
    layoutFile = "kbdneo2.dll";
    layoutText = "Deutsch (Neo)";
  };
  kbdNeoJson = builtins.toJSON kbdNeo;
  font =
    if byRole "terminal-font" == null then
      null
    else
      import ./font.nix { inherit byRole applicationMetadata powershell; };
  # Office derives character shortcuts such as Ctrl+] from the first loaded
  # layout, and Windows loads the default input method first. Native Neo types
  # those characters on letter keys, so it must not be the default.
  inputMethods = rec {
    default = "0407:00000407";
    nativeNeo = "0407:${kbdNeo.layoutId}";
    german = [
      default
      nativeNeo
    ];
  };
  settingsResources = import ./settings.nix { inherit inputMethods; };

  expectedRoles = [
    "browser"
    "browser-relay"
    "communication-client"
    "editor"
    "git-client"
    "keyboard-layout"
    "launcher"
    "terminal"
    "terminal-font"
    "window-tool"
  ];

  packageResources = map (application: {
    type = "Microsoft.WinGet/Package";
    name = "package-${application.role}";
    properties = {
      inherit (application) id source;
      acceptAgreements = true;
      installMode = "silent";
      useLatest = (application.versionPolicy or null) == "self-updating";
    }
    // lib.optionalAttrs ((application.versionPolicy or null) == "exact" && application ? version) {
      inherit (application) version;
    };
    metadata = {
      description = "Install ${application.name} for ${application.scope} scope";
      application = applicationMetadata application;
    }
    // lib.optionalAttrs (application.scope == "machine") {
      winget.securityContext = "elevated";
    };
  }) (builtins.filter (application: application.source == "winget") applications);

  rawResources =
    packageResources
    ++ lib.optional (font != null) font.resource
    ++ settingsResources
    ++ applicationFiles.resources;
  normalizeName = lib.replaceStrings [ "-" ] [ " " ];
  normalizeResource =
    resource:
    resource
    // {
      name = normalizeName resource.name;
    }
    // lib.optionalAttrs (resource ? dependsOn) {
      dependsOn = map normalizeName resource.dependsOn;
    };

  normalizedResources = map normalizeResource rawResources;
  document = {
    "$schema" =
      "https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/2023/08/config/document.json";
    metadata.winget.processor.identifier = "dscv3";
    resources = normalizedResources;
  };

  declaration = {
    roles = expectedRoles;
    applications = map (application: builtins.removeAttrs application [ "release" ]) applications;
    managedApplications = managedApplications.identifiers;
    reviewFiles = builtins.attrNames renderedFiles;
    inherit inputMethods;
  };

  zenPolicyScript = pkgs.writeText "apply-zen-policies.ps1" ''
    [CmdletBinding()]
    param([switch]$Test)

    $ErrorActionPreference = 'Stop'
    $browser = Join-Path $env:ProgramFiles 'Zen Browser\zen.exe'
    $path = Join-Path $env:ProgramFiles 'Zen Browser\distribution\policies.json'
    $desired = ${powershell.psHereString (builtins.toJSON applicationFiles.zenPolicies)}
    $current = if (Test-Path -LiteralPath $path) { [IO.File]::ReadAllText($path) } else { $null }
    if ($current -eq $desired) {
      Write-Output 'Zen policies: desired'
      exit 0
    }
    if ($Test) {
      Write-Output 'Zen policies: drift'
      exit 1
    }

    ${powershell.requireAdministrator "Zen policy"}
    if (-not (Test-Path -LiteralPath $browser)) {
      throw "Zen is not installed at $browser"
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [IO.File]::WriteAllText($path, $desired, [Text.UTF8Encoding]::new($false))
    Write-Output 'Zen policies: changed'
  '';

  kbdNeoScript = pkgs.writeText "apply-kbdneo.ps1" ''
    [CmdletBinding()]
    param([switch]$Test)

    $ErrorActionPreference = 'Stop'
    $specification = ${powershell.psJson kbdNeo} | ConvertFrom-Json
    $system32 = Join-Path $env:SystemRoot "System32\$($specification.layoutFile)"
    $sysWow64 = Join-Path $env:SystemRoot "SysWOW64\$($specification.layoutFile)"
    $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Keyboard Layouts\$($specification.layoutId)"
    $registry = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
    $desired = (Test-Path -LiteralPath $system32) `
      -and ${powershell.sha256Of "$system32"} -eq $specification.system32Sha256 `
      -and (Test-Path -LiteralPath $sysWow64) `
      -and ${powershell.sha256Of "$sysWow64"} -eq $specification.sysWow64Sha256 `
      -and $registry.'Layout Text' -eq $specification.layoutText `
      -and $registry.'Layout File' -eq $specification.layoutFile `
      -and $registry.'Layout Id' -eq '00c0' `
      -and $registry.'Layout Display Name' -eq '@%SystemRoot%\system32\kbdneo2.dll,-1000' `
      -and $registry.'Custom Language Name' -eq 'German (Germany)' `
      -and $registry.'Custom Language Display Name' -eq '@%SystemRoot%\system32\kbdneo2.dll,-1100'
    if ($desired) {
      Write-Output 'kbdneo: desired'
      exit 0
    }
    if ($Test) {
      Write-Output 'kbdneo: drift'
      exit 1
    }

    ${powershell.requireAdministrator "kbdneo"}
    if (-not [Environment]::Is64BitProcess) {
      throw 'Run the kbdneo apply from 64-bit PowerShell'
    }

    $archive = Join-Path $env:TEMP 'kbdneo64.zip'
    $expanded = Join-Path $env:TEMP 'kbdneo64'
    try {
      ${powershell.expandArchive {
        variable = "$specification";
        label = "kbdneo";
      }}
      $payload = Join-Path $expanded 'kbdneo64'
      $system32Source = Join-Path $payload "System32\$($specification.layoutFile)"
      $sysWow64Source = Join-Path $payload "SysWOW64\$($specification.layoutFile)"
      if (${powershell.sha256Of "$system32Source"} -ne $specification.system32Sha256) { throw 'kbdneo System32 DLL checksum mismatch' }
      if (${powershell.sha256Of "$sysWow64Source"} -ne $specification.sysWow64Sha256) { throw 'kbdneo SysWOW64 DLL checksum mismatch' }
      Copy-Item -LiteralPath $system32Source -Destination $system32 -Force
      Copy-Item -LiteralPath $sysWow64Source -Destination $sysWow64 -Force
      New-Item -Path $registryPath -Force | Out-Null
      New-ItemProperty -Path $registryPath -Name 'Layout Text' -Value $specification.layoutText -PropertyType String -Force | Out-Null
      New-ItemProperty -Path $registryPath -Name 'Layout File' -Value $specification.layoutFile -PropertyType String -Force | Out-Null
      New-ItemProperty -Path $registryPath -Name 'Layout Id' -Value '00c0' -PropertyType String -Force | Out-Null
      New-ItemProperty -Path $registryPath -Name 'Layout Display Name' -Value '@%SystemRoot%\system32\kbdneo2.dll,-1000' -PropertyType String -Force | Out-Null
      New-ItemProperty -Path $registryPath -Name 'Custom Language Name' -Value 'German (Germany)' -PropertyType String -Force | Out-Null
      New-ItemProperty -Path $registryPath -Name 'Custom Language Display Name' -Value '@%SystemRoot%\system32\kbdneo2.dll,-1100' -PropertyType String -Force | Out-Null
    } finally {
      Remove-Item -LiteralPath $archive -Force -ErrorAction SilentlyContinue
      Remove-Item -LiteralPath $expanded -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Output 'kbdneo: changed; restart Windows before selecting the layout'
  '';

  yaml = pkgs.formats.yaml { };
  renderedDocument = yaml.generate "configuration.winget" document;
  renderedFiles =
    lib.mapAttrs pkgs.writeText (applicationFiles.files // { "kbdneo.json" = kbdNeoJson; })
    // applicationFiles.assets;
  fileCopies = lib.concatMapAttrsStringSep "\n" (name: path: ''
    mkdir -p "$out/${builtins.dirOf name}"
    cp ${path} "$out/${name}"
  '') renderedFiles;
in

pkgs.runCommand "windows-workstation-configuration"
  {
    meta = {
      description = "Render the managed Windows workstation configuration";
      platforms = [
        "aarch64-darwin"
        "x86_64-linux"
      ];
    };
    passthru = { inherit declaration; };
  }
  ''
    mkdir -p "$out"
    cp ${renderedDocument} "$out/configuration.winget"
    cp ${kbdNeoScript} "$out/apply-kbdneo.ps1"
    cp ${zenPolicyScript} "$out/apply-zen-policies.ps1"
    ${fileCopies}
  ''
