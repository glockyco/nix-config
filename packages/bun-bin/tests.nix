{ pkgs, ... }:

let
  declaration = builtins.fromJSON (builtins.readFile ../../windows/workstation.json);
  windowsBun = builtins.head (
    builtins.filter (app: app.id or "" == "Oven-sh.Bun") declaration.applications
  );
in
{
  # The Mac package and Korolev's declaration both serve omp-agent-setup's
  # `.bun-version`, so a bump must move them together.
  bunVersion = pkgs.runCommand "check-bun-version" {
    nativeBuildInputs = [ pkgs.bun-bin ];
    macVersion = pkgs.bun-bin.version;
    windowsVersion = windowsBun.version;
  } "${pkgs.runtimeShell} ${./version.sh}";
}
