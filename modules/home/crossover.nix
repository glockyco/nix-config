{ config, lib, ... }:

let
  crossover = "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver";
  bottles = "${config.home.homeDirectory}/Library/Application Support/CrossOver/Bottles";

  bottle = "Steam";
  template = "win11_64";
in

{
  home.activation.crossoverSteamBottle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x ${lib.escapeShellArg "${crossover}/bin/cxbottle"} ]; then
      verboseEcho "CrossOver not installed; skipping ${bottle} bottle"
    elif [ -d ${lib.escapeShellArg "${bottles}/${bottle}/drive_c"} ]; then
      verboseEcho "CrossOver bottle ${bottle} already exists; leaving it alone"
    elif ! /usr/bin/pgrep -q oahd; then
      # CrossOver 26's wineloader is x86_64; bottle creation fails with "Bad CPU
      # type in executable" without Rosetta 2.
      warnEcho "Rosetta 2 is not installed, so the ${bottle} bottle cannot be created."
      warnEcho "Run: softwareupdate --install-rosetta --agree-to-license"
    else
      # cxbottle leaves a partial directory after failure; remove it so a retry can run.
      run ${lib.escapeShellArg "${crossover}/bin/cxbottle"} \
        --bottle ${lib.escapeShellArg bottle} \
        --create \
        --template ${lib.escapeShellArg template} \
        --description "Managed by nix-darwin. Install Steam from CrossOver's app list." \
        || {
          warnEcho "Creating the ${bottle} bottle failed; create it from CrossOver's UI."
          rm -rf ${lib.escapeShellArg "${bottles}/${bottle}"}
        }
    fi
  '';
}
