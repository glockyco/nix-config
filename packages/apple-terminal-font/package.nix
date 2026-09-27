{ lib, python3Packages }:

python3Packages.buildPythonApplication {
  pname = "apple-terminal-font";
  version = "0.1.0";
  pyproject = true;
  src = ./.;

  build-system = [ python3Packages.setuptools ];
  nativeCheckInputs = [ python3Packages.unittestCheckHook ];
  doCheck = true;

  meta = {
    description = "Set the font of Terminal startup and default profiles";
    mainProgram = "apple-terminal-font";
    platforms = lib.platforms.darwin;
  };
}
