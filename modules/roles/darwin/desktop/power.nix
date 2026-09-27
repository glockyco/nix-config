{
  # nix-darwin's `power.sleep.*` shells out to `systemsetup`, which applies a
  # single value to both power sources. These have to differ, so drive `pmset`
  # directly: `-c` is the AC profile, `-b` the battery one.
  #
  # Never sleeping on AC is the point of the exercise: Nix builds hold no power
  # assertion, so an unattended `darwin-switch` would otherwise be suspended
  # partway through. The display still sleeps on AC.
  system.activationScripts.extraActivation.text = ''
    /usr/bin/pmset -c sleep 0 displaysleep 10
    /usr/bin/pmset -b sleep 1 displaysleep 15
  '';
}
