{ lib, pkgs }:

let
  applications = import ./applications.nix;
  managedApplications = import ./managed-applications.nix;
  shared = import ../shared;
  applicationFiles = import ./files.nix { inherit pkgs shared; };
  font = import ./font.nix;
  settingsResources = import ./settings.nix;

  expectedRoles = [
    "browser"
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
      inherit (application) id source version;
      acceptAgreements = true;
      installMode = "silent";
      useLatest = false;
    };
    metadata = {
      description = "Install ${application.name} for ${application.scope} scope";
      application = {
        inherit (application)
          id
          scope
          source
          version
          ;
        roles = [ application.role ] ++ (application.provides or [ ]);
      };
    }
    // lib.optionalAttrs (application.scope == "machine") {
      winget.securityContext = "elevated";
    };
  }) (builtins.filter (application: application.source == "winget") applications);

  rawResources =
    packageResources ++ [ font.resource ] ++ settingsResources ++ applicationFiles.resources;
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

  collisions = lib.intersectLists managedApplications.identifiers (
    map (application: application.id) applications
  );
  unpinned = builtins.filter (application: application.version == "") applications;
  roleCounts = map (
    role:
    lib.count (
      application: application.role == role || builtins.elem role (application.provides or [ ])
    ) applications
  ) expectedRoles;
  machineResources = builtins.filter (
    resource:
    lib.hasPrefix "HKLM\\" (resource.properties.keyPath or "")
    || builtins.elem resource.type [
      "Microsoft.Windows/OptionalFeatureList"
      "PSDesiredStateConfiguration/WindowsFeature"
      "PSDesiredStateConfiguration/WindowsFeatureSet"
    ]
    || (resource.metadata.winget.securityContext or null) == "elevated"
  ) normalizedResources;
  machineResourceKinds = map (resource: "${resource.name}:${resource.type}") machineResources;

  zenPolicyScript = pkgs.writeText "apply-zen-policies.ps1" ''
    [CmdletBinding()]
    param([switch]$Test)

    $ErrorActionPreference = 'Stop'
    $browser = Join-Path $env:ProgramFiles 'Zen Browser\zen.exe'
    $path = Join-Path $env:ProgramFiles 'Zen Browser\distribution\policies.json'
    $desired = @'
    ${builtins.toJSON applicationFiles.zenPolicies}
    '@
    $current = if (Test-Path -LiteralPath $path) { [IO.File]::ReadAllText($path) } else { $null }
    if ($current -eq $desired) {
      Write-Output 'Zen policies: desired'
      exit 0
    }
    if ($Test) {
      Write-Output 'Zen policies: drift'
      exit 1
    }

    $principal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
      throw 'The Zen policy apply requires an Administrator PowerShell session'
    }
    if (-not (Test-Path -LiteralPath $browser)) {
      throw "Zen is not installed at $browser"
    }

    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    [IO.File]::WriteAllText($path, $desired, [Text.UTF8Encoding]::new($false))
    Write-Output 'Zen policies: changed'
  '';

  yaml = pkgs.formats.yaml { };
  renderedDocument = yaml.generate "configuration.winget" document;
  renderedFiles = lib.mapAttrs pkgs.writeText applicationFiles.files // font.files;
  fileCopies = lib.concatMapAttrsStringSep "\n" (name: path: ''
    mkdir -p "$out/${builtins.dirOf name}"
    cp ${path} "$out/${name}"
  '') renderedFiles;
in

assert lib.assertMsg (unpinned == [ ]) "every Windows application must have an explicit version";
assert lib.assertMsg (collisions == [ ]) "a declared Windows application is centrally managed";
assert lib.assertMsg (builtins.all (
  count: count == 1
) roleCounts) "each Windows application role must have exactly one package";
assert lib.assertMsg (
  machineResourceKinds == [ "package browser:Microsoft.WinGet/Package" ]
) "only the Zen package may require elevation in the WinGet document";
pkgs.runCommand "windows-workstation-configuration"
  {
    passthru = {
      inherit
        applications
        document
        managedApplications
        renderedFiles
        ;
    };
  }
  ''
    mkdir -p "$out"
    cp ${renderedDocument} "$out/configuration.winget"
    cp ${zenPolicyScript} "$out/apply-zen-policies.ps1"
    ${fileCopies}
  ''
