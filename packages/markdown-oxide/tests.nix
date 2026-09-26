{ pkgs, ... }:

{
  markdownOxideVersion = pkgs.runCommand "check-markdown-oxide-version" {
    nativeBuildInputs = [ pkgs.markdown-oxide ];
    expectedVersion = "markdown-oxide ${pkgs.markdown-oxide.version}";
  } "${pkgs.runtimeShell} ${./version.sh}";
}
