{ pkgs, ... }:

let
  # Secretive's Secure Enclave agent socket. The single secret it serves was
  # created with protection level "Notify", so it signs without a Touch ID
  # prompt. Protection level is fixed when a secret is created, so a secret
  # that prompts can only be replaced, never relaxed -- keep that in mind
  # before adding another one here.
  secretiveAgent = "~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
  airBatchCheck = pkgs.callPackage ../../../packages/air-batch-check.nix { };
  airHost = {
    HostName = "MacBook-Air-von-ISYS.local";
    User = "joaichberger";
  };
in

{
  home.packages = [ airBatchCheck ];

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

      # The old MacBook Air, reachable over the LAN by mDNS (its DHCP lease
      # moves, the .local name does not). Its account name differs from this
      # machine's, so without this block ssh defaults to `glockyco` and the
      # Secure Enclave key -- which is in the Air's authorized_keys -- is
      # rejected as an unknown user.
      "air" = airHost;

      # Unattended commands must exit with their remote process instead of
      # inheriting the interactive one-hour control-master lifetime. Keep stdin
      # available because rsync carries its protocol over the SSH streams.
      "air-batch" = airHost // {
        BatchMode = "yes";
        RequestTTY = "no";
        ControlMaster = "no";
        ControlPath = "none";
        ControlPersist = "no";
        ConnectTimeout = 8;
      };

      # Opt-in path to GitHub through the YubiKey resident key, as
      # `git clone github-yubikey:owner/repo`. Deliberately not bound to
      # `github.com`: that would make every push wait on a hardware touch,
      # where the Secure Enclave key signs silently.
      #
      # This is the credential that survives losing this Mac. The Secure
      # Enclave key cannot leave it, so a second machine enrolls its own key
      # rather than copying one; the YubiKey is what gets you in meanwhile.
      # `IdentityAgent none` keeps Secretive out of the exchange.
      "github-yubikey" = {
        HostName = "github.com";
        User = "git";
        IdentityAgent = "none";
        IdentityFile = "~/.ssh/id_ed25519_sk";
        IdentitiesOnly = "yes";
      };
    };
  };
}
