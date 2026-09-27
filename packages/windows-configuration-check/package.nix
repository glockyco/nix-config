{
  fetchFromGitHub,
  lib,
  makeWrapper,
  powershell,
  python3Packages,
}:

let
  dscSchemas = fetchFromGitHub {
    owner = "PowerShell";
    repo = "DSC";
    rev = "45b10078ba49d9f9ec13b72c1040368eac9838e9";
    hash = "sha256-7x7CbgNsGdJ1CB+kLG1skh42vCqd9nd/GmvbAjZl4NU=";
  };
in
python3Packages.buildPythonApplication {
  pname = "windows-configuration-check";
  version = "0.1.0";
  pyproject = true;
  src = ./.;

  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [
    jsonschema
    pyyaml
    referencing
  ];
  nativeBuildInputs = [ makeWrapper ];
  nativeCheckInputs = [
    powershell
    python3Packages.unittestCheckHook
  ];
  doCheck = true;
  preCheck = ''
    export WINDOWS_CHECK_TEST_SCHEMAS=${dscSchemas}
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
  '';
  makeWrapperArgs = [
    "--prefix"
    "PATH"
    ":"
    (lib.makeBinPath [ powershell ])
  ];

  passthru.dscSchemas = dscSchemas;
  meta = {
    description = "Validate the rendered Windows configuration declaration and scripts";
    mainProgram = "windows-configuration-check";
    platforms = [
      "aarch64-darwin"
      "x86_64-linux"
    ];
  };
}
