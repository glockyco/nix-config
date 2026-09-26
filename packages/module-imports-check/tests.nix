{
  pkgs,
  modules ? ../../modules,
  flakeModules ? ../../flake-modules,
  ...
}:

{
  moduleImports = pkgs.runCommand "check-module-imports" {
    check = "${pkgs.module-imports-check}/bin/module-imports-check";
    inherit modules flakeModules;
  } "${pkgs.runtimeShell} ${./imports.sh}";

  moduleImportsCommand = pkgs.runCommand "check-module-imports-command" {
    nativeBuildInputs = [ pkgs.coreutils ];
    check = "${pkgs.module-imports-check}/bin/module-imports-check";
  } "${pkgs.runtimeShell} ${./command.sh}";
}
