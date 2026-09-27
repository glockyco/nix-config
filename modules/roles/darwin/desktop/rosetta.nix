{ lib, pkgs, ... }:
{
  # CrossOver requires Rosetta 2 for its x86_64 wineloader.
  # Probe x86_64 execution; install only if the probe fails. An install error
  # stops activation instead of leaving CrossOver unable to run.
  system.activationScripts.extraActivation.text = ''
    ${lib.getExe pkgs.rosetta}
  '';
}
