{
  pkgs,
  windowsConfiguration,
}:

let
  dscSchemas = pkgs.fetchFromGitHub {
    owner = "PowerShell";
    repo = "DSC";
    rev = "45b10078ba49d9f9ec13b72c1040368eac9838e9";
    hash = "sha256-7x7CbgNsGdJ1CB+kLG1skh42vCqd9nd/GmvbAjZl4NU=";
  };
  managedIdentifiers = pkgs.writeText "managed-windows-applications.json" (
    builtins.toJSON windowsConfiguration.managedApplications.identifiers
  );
  python = pkgs.python3.withPackages (packages: [
    packages.jsonschema
    packages.pyyaml
  ]);
in

pkgs.runCommand "check-windows-configuration" { } ''
  ${python}/bin/python ${./windows-configuration-check.py} \
    ${dscSchemas} \
    ${windowsConfiguration}/configuration.winget \
    ${managedIdentifiers} \
    ${windowsConfiguration}
  touch "$out"
''
