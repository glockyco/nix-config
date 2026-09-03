_:

let
  shared = import ../shared;
in

{
  # Zen is a Firefox fork, so it honours Mozilla enterprise policies. On macOS
  # those are read from the app's own preference domain, but only once
  # EnterprisePoliciesEnabled is set. Writing them here instead of
  # `Contents/Resources/distribution/policies.json` keeps the Homebrew-managed
  # bundle untouched -- editing it breaks the signature and is lost on upgrade.
  system.defaults.CustomUserPreferences."app.zen-browser.zen" = shared.zenPolicies;
}
