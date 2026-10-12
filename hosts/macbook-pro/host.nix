let
  facts =
    (builtins.fromTOML (builtins.readFile ../../home/.chezmoidata/hosts.toml)).hosts.macbook-pro;
  platform = facts.platforms.darwin;
in
{
  host = {
    system = "aarch64-darwin";
    username = platform.username;
    homeDirectory = platform.home;
    displayName = "MacBook Pro";
    locale = {
      use24HourClock = true;
      useMetric = true;
    };
    paths = {
      configurationCheckout = platform.checkout;
      repositoryRoot = platform.ghqRoot;
      screenshots = facts.paths.screenshots;
    };
    git = facts.git;
    roles = facts.roles;
    darwin = {
      applications = facts.applications;
      containerProfile = facts.container;
    };
    tailnet.tag = "tag:macbook-pro";
  };
}
