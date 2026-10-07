{ lib, python3Packages }:

python3Packages.buildPythonApplication {
  pname = "zed-configuration";
  version = "0.1.0";
  pyproject = true;
  src = ./.;
  build-system = [ python3Packages.setuptools ];
  nativeCheckInputs = [ python3Packages.unittestCheckHook ];
  doCheck = true;
  meta = {
    description = "Merge declared Zed JSONC settings while preserving app state";
    mainProgram = "zed-configuration";
    platforms = lib.platforms.all;
  };
}
