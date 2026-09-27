{ lib, python3Packages }:

python3Packages.buildPythonApplication {
  pname = "fastmail";
  version = "0.1.0";
  pyproject = true;
  src = ./.;

  build-system = [ python3Packages.setuptools ];
  nativeCheckInputs = [ python3Packages.unittestCheckHook ];
  doCheck = true;

  meta = {
    description = "Query Fastmail mail and DMARC reports over JMAP";
    mainProgram = "fastmail";
    platforms = lib.platforms.all;
  };
}
