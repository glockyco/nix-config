let
  githubNoReplyEmail = "11704293+glockyco@users.noreply.github.com";
in
{
  host = {
    system = "x86_64-linux";
    kind = "nixos";
    username = "user";
    displayName = null;
    timeZone = "Europe/Vienna";
    locale = {
      timeCategory = "de_AT.UTF-8";
      measurementCategory = "de_AT.UTF-8";
    };
    paths = {
      configurationCheckout = null;
      screenshots = null;
    };
    git = {
      authorName = "Johann Glock";
      defaultEmail = "johann.glock@scch.at";
      githubNoReplyEmail = githubNoReplyEmail;
    };
    tailnet = {
      tag = "tag:korolev";
      reachable = false;
    };
  };
}
