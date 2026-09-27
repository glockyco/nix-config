{ lib, pkgs, ... }:
{
  # nix-darwin's `power.sleep.*` uses `systemsetup`, which applies one value
  # to both sources. The packaged command compares AC and battery separately.
  # Never sleeping on AC matters because Nix builds hold no power assertion.
  # The display still sleeps on AC.
  system.activationScripts.extraActivation.text = ''
    ${lib.getExe pkgs.power-settings} -c sleep 0 displaysleep 10 -b sleep 1 displaysleep 15
  '';
}
