{ config, lib, ... }:

let
  crossover = "/Applications/CrossOver.app/Contents/SharedSupport/CrossOver";
  bottles = "${config.home.homeDirectory}/Library/Application Support/CrossOver/Bottles";

  bottle = "Steam";
  template = "win11_64";
in

{
  # Create the Steam bottle if it does not already exist.
  #
  # Scope is deliberately narrow. `cxbottle --create` is deterministic and
  # cheap, so the bottle's *existence* and Windows template are worth
  # declaring. Everything inside it is not: Steam's own install needs an
  # interactive login, CodeWeavers documents no headless CrossTie invocation,
  # and the result is a mutable Wine prefix holding a registry, drive_c and
  # potentially hundreds of gigabytes of games. That is database-like state to
  # be archived and restored (CrossOver has Bottle > Archive for exactly this),
  # not something to regenerate from a flake.
  #
  # Never fails the activation. CrossOver is a GUI app with its own runtime
  # requirements, and a problem here must not leave the rest of the system
  # half-applied -- an earlier version of this module did exactly that.
  home.activation.crossoverSteamBottle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ ! -x ${lib.escapeShellArg "${crossover}/bin/cxbottle"} ]; then
      verboseEcho "CrossOver not installed; skipping ${bottle} bottle"
    elif [ -d ${lib.escapeShellArg "${bottles}/${bottle}"} ]; then
      verboseEcho "CrossOver bottle ${bottle} already exists; leaving it alone"
    elif ! /usr/bin/pgrep -q oahd; then
      # CrossOver 26's wineloader is still an x86_64 binary, so bottle creation
      # dies with "Bad CPU type in executable" without Rosetta 2.
      warnEcho "Rosetta 2 is not installed, so the ${bottle} bottle cannot be created."
      warnEcho "Run: softwareupdate --install-rosetta --agree-to-license"
    else
      run ${lib.escapeShellArg "${crossover}/bin/cxbottle"} \
        --bottle ${lib.escapeShellArg bottle} \
        --create \
        --template ${lib.escapeShellArg template} \
        --description "Managed by nix-darwin. Install Steam from CrossOver's app list." \
        || warnEcho "Creating the ${bottle} bottle failed; create it from CrossOver's UI."
    fi
  '';
}
