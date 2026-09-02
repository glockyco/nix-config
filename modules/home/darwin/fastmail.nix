{
  config,
  pkgs,
  ...
}:

let
  # sops-nix decrypts to the user's runtime directory at login; nothing
  # readable ever lands in the repository or the home directory.
  tokenFile = config.sops.secrets."token".path;

  fastmail = pkgs.writeShellApplication {
    name = "fastmail";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${./fastmail.py} --token-file ${tokenFile} "$@"
    '';
  };
in

{
  # A JMAP client rather than a mail app: Fastmail speaks JMAP natively, so
  # this needs no IMAP app password, no local mail store and no sync daemon.
  # Output is JSON, which is what makes it useful to a coding agent.
  home.packages = [ fastmail ];
}
