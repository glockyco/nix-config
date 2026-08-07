{ pkgs, ... }:

let
  # Secretive's Secure Enclave agent socket.
  secretiveAgent = "~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
in

{
  # Enclave keys are served by Secretive; the YubiKey holds a resident FIDO2 key.
  # Neither private key is exportable.
  programs.ssh = {
    enable = true;

    # Apple's ssh-keygen lacks libfido2: `-t ed25519-sk` fails with "No FIDO
    # SecurityKeyProvider specified". nixpkgs builds it in. Apple's
    # `UseKeychain` directive is unknown to this client and must not appear below.
    package = pkgs.openssh;

    # Matches the pinned Home Manager release; changing it changes option defaults.
    enableDefaultConfig = false;

    settings = {
      "*" = {
        IdentityAgent = secretiveAgent;

        AddKeysToAgent = "no";

        HashKnownHosts = "yes";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
      };

      # Use the YubiKey resident key through its handle file.
      # Uncomment this host block after enrollment.
      # "github.com" = {
      #   HostName = "github.com";
      #   User = "git";
      #   IdentityFile = "~/.ssh/id_ed25519_sk";
      #   IdentitiesOnly = "yes";
      # };
    };
  };
}
