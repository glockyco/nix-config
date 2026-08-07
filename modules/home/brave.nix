{ config, ... }:

let
  externalExtensions = "${config.home.homeDirectory}/Library/Application Support/BraveSoftware/Brave-Browser/External Extensions";

  # Chromium's external-extensions mechanism: a JSON file named after the
  # extension id, pointing at an update URL. Used instead of the
  # `ExtensionInstallForcelist` policy because that needs a managed preference
  # domain, which in turn expects MDM enrolment.
  fromWebStore = id: {
    "${externalExtensions}/${id}.json".text = builtins.toJSON {
      external_update_url = "https://clients2.google.com/service/update2/crx";
    };
  };
in

{
  # Brave exists only to host the OMP browser relay, which is a Chrome MV3
  # extension and cannot load in Gecko. Ad blocking is Brave Shields, not uBlock
  # Origin -- Brave force-enables MV2 for a handful of blockers on a best-effort
  # basis, and Chrome removes the last MV2 listings from the store on 2026-08-31.
  #
  # The relay extension is unpacked and not on the Web Store, so it cannot be
  # installed this way. Run `omp browser-relay install` and load it by hand.
  home.file = fromWebStore "nngceckbapebfimnlniiiahkandclblb"; # Bitwarden
}
