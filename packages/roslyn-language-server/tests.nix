{ pkgs, ... }:

{
  roslynInitialization = pkgs.runCommand "check-roslyn-language-server-initialization" {
    ROSLYN_DRIVER = ./initialization.py;
    nativeBuildInputs = [
      pkgs.python3
      pkgs.roslyn-language-server
    ];
    meta.timeout = 60;
  } "${pkgs.runtimeShell} ${./initialization.sh}";
}
