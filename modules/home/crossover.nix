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
  # Guarded on the directory so an existing bottle is never touched -- this
  # only ever runs on a machine that does not have one yet.
  home.activation.crossoverSteamBottle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x ${lib.escapeShellArg "${crossover}/bin/cxbottle"} ] \
       && [ ! -d ${lib.escapeShellArg "${bottles}/${bottle}"} ]; then
      run ${lib.escapeShellArg "${crossover}/bin/cxbottle"} \
        --bottle ${lib.escapeShellArg bottle} \
        --create \
        --template ${lib.escapeShellArg template} \
        --description "Managed by nix-darwin. Install Steam from CrossOver's app list."
    fi
  '';
}
