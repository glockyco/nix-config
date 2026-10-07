let
  facts = (builtins.fromTOML (builtins.readFile ../../home/.chezmoidata/hosts.toml)).hosts.korolev;
  platform = facts.platforms.linux;
in
{
  host = {
    system = "x86_64-linux";
    kind = "nixos";
    username = platform.username;
    homeDirectory = platform.home;
    displayName = null;
    timeZone = "Europe/Vienna";
    locale = {
      timeCategory = "de_AT.UTF-8";
      measurementCategory = "de_AT.UTF-8";
    };
    paths = {
      configurationCheckout = platform.checkout;
      repositoryRoot = platform.ghqRoot;
      screenshots = null;
    };
    git = facts.git;
    roles = facts.roles;
    tailnet = {
      tag = "tag:korolev";
      # The reachable machine identity belongs to native Windows, not WSL.
      reachable = true;
    };
  };
}
