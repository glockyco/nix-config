{
  python3,
  runCommand,
}:

let
  python = python3.withPackages (packages: [ packages.pyyaml ]);
in
runCommand "check-secret-encryption" { nativeBuildInputs = [ python ]; } ''
  python ${./secret-encryption-check.py} ${../secrets} ${./secret-encryption-fixtures}
  touch "$out"
''
