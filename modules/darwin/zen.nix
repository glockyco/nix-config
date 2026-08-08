_:

let
  # AMO's "latest" endpoint, which serves the newest build for the platform.
  amo = slug: "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";

  forceInstalled = slug: {
    installation_mode = "force_installed";
    install_url = amo slug;
  };
in

{
  # Zen is a Firefox fork, so it honours Mozilla enterprise policies. On macOS
  # those are read from the app's own preference domain, but only once
  # EnterprisePoliciesEnabled is set. Writing them here instead of
  # `Contents/Resources/distribution/policies.json` keeps the Homebrew-managed
  # bundle untouched -- editing it breaks the signature and is lost on upgrade.
  #
  # Add-on ids are the AMO `guid`; the slug in the URL is separate. Both come
  # from https://addons.mozilla.org/api/v5/addons/addon/<slug>/.
  system.defaults.CustomUserPreferences."app.zen-browser.zen" = {
    EnterprisePoliciesEnabled = true;

    ExtensionSettings = {
      "uBlock0@raymondhill.net" = forceInstalled "ublock-origin" // {
        private_browsing = true;
      };
      "{446900e4-71c2-419f-a6a7-df9c091e268b}" = forceInstalled "bitwarden-password-manager" // {
        private_browsing = true;
      };
      "sponsorBlocker@ajay.app" = forceInstalled "sponsorblock";
      "enhancerforyoutube@maximerf.addons.mozilla.org" = forceInstalled "enhancer-for-youtube";
      "{1be309c5-3e4f-4b99-927d-bb500eb4fa88}" = forceInstalled "augmented-steam";
      "{aecec67f-0d10-4fa7-b7c7-609a2db280cf}" = forceInstalled "violentmonkey";
    };
  };
}
