{
  pkgs,
  windowsConfiguration,
}:

let
  checker = pkgs.windows-configuration-check;
  declaration = pkgs.writeText "windows-configuration-declaration.json" (
    builtins.toJSON windowsConfiguration.declaration
  );
in
pkgs.runCommand "check-windows-configuration" { } ''
  export HOME="$TMPDIR/home"
  mkdir -p "$HOME"
  ${checker}/bin/windows-configuration-check \
    --schemas ${checker.dscSchemas} \
    --declaration ${declaration} \
    ${windowsConfiguration}
  touch "$out"
''
