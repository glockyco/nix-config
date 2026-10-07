{ lib, python3Packages }:

python3Packages.buildPythonApplication {
  pname = "karabiner-configuration";
  version = "0.1.0";
  pyproject = true;
  src = ./.;
  build-system = [ python3Packages.setuptools ];
  nativeCheckInputs = [ python3Packages.unittestCheckHook ];
  doCheck = true;
  meta = {
    description = "Merge declared Karabiner settings while preserving app state";
    mainProgram = "karabiner-configuration";
    platforms = lib.platforms.all;
  };
}
