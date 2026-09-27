{
  config,
  lib,
  inputs,
  ...
}:

let
  inherit (config.host) name;
in
{
  networking.hostName = name;

  # Matches the pinned nixpkgs release; changing it changes option defaults.
  system.stateVersion = "26.05";

  # Expose the active commit in `nixos-version`, as `modules/darwin/system.nix`
  # does for `darwin-version`. This value enters the system derivation, so the
  # system path moves with every commit. A closure diff is therefore the way to
  # compare two generations; a store-path comparison reports every commit as a
  # change.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  time.timeZone = config.host.timeZone;

  # The host declares explicit 24-hour and metric locale categories.
  i18n.extraLocaleSettings =
    lib.optionalAttrs (config.host.locale.timeCategory != null) {
      LC_TIME = config.host.locale.timeCategory;
    }
    // lib.optionalAttrs (config.host.locale.measurementCategory != null) {
      LC_MEASUREMENT = config.host.locale.measurementCategory;
    };

}
