{ pkgs, ... }:

let
  # Secretive's Secure Enclave agent socket. The single secret it serves was
  # created with protection level "Notify", so it signs without a Touch ID
  # prompt. Protection level is fixed when a secret is created, so a secret
  # that prompts can only be replaced, never relaxed -- keep that in mind
  # before adding another one here.
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

        # Every git command otherwise opens its own connection, and Fork
        # fetches in the background, so multiplexing keeps that to one
        # connection per host. `%C` hashes the connection tuple, keeping the
        # socket path under the 104-byte limit on macOS.
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%C";
        ControlPersist = "1h";

        HashKnownHosts = "yes";

        # Also tears down a master left behind by a dropped link, after ~3
        # minutes, instead of letting clients hang on it.
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
