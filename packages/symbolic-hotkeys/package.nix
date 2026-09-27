{ lib, python3Packages }:

python3Packages.buildPythonApplication {
  pname = "symbolic-hotkeys";
  version = "0.1.0";
  pyproject = true;
  src = ./.;

  build-system = [ python3Packages.setuptools ];
  nativeCheckInputs = [ python3Packages.unittestCheckHook ];
  doCheck = true;

  meta = {
    description = "Disable declared macOS symbolic hotkeys without changing other bindings";
    mainProgram = "symbolic-hotkeys";
    platforms = lib.platforms.darwin;
  };
}
