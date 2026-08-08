{ config, inputs, ... }:

{
  # Secrets are committed encrypted and decrypted on this machine at login.
  #
  # The Home Manager port is the right one here: these secrets belong to the
  # user and are read by user processes, so they are installed by a launchd
  # *agent* rather than a root daemon, and land in the user's runtime
  # directory instead of /run/secrets.
  #
  # The private half of the age key lives at ~/.config/sops/age/keys.txt and is
  # never committed. It is this machine's trust anchor: another machine gets
  # its own key, and its public half is added to .sops.yaml.
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFile = ../../secrets/fastmail.yaml;

    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Read-only JMAP token, scoped to Email. It cannot send mail or create
    # Masked Email addresses; see modules/home/fastmail.nix.
    secrets."token" = { };
  };
}
