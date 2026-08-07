{ pkgs, ... }:

let
  # Secretive's Secure Enclave agent socket.
  secretiveAgent = "~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh";
in

{
  # Key strategy: private keys are never stored in this repository, never
  # copied, and never migrated between machines.
  #
  #   - Day to day: keys generated inside this Mac's Secure Enclave and served
  #     by Secretive. They cannot be exported, by construction.
  #   - Recovery and portability: a resident FIDO2 key on a YubiKey. The private
  #     key lives on the token, so it travels with you rather than with a
  #     machine, and it is the only way back in if this Mac dies -- Secure
  #     Enclave keys have no backup path.
  #
  # Register the public half of both with every service, so losing either one is
  # an inconvenience rather than a lockout.
  programs.ssh = {
    enable = true;

    # nixpkgs OpenSSH rather than Apple's. Apple builds theirs without libfido2,
    # so `ssh-keygen -t ed25519-sk` fails with "No FIDO SecurityKeyProvider
    # specified" and YubiKey keys are unusable. nixpkgs builds with
    # `--with-security-key-builtin=yes`.
    #
    # Consequence: Apple's non-upstream `UseKeychain` directive is not
    # understood by this client and must not appear below, or every ssh
    # invocation errors out. That costs nothing here -- neither the Secure
    # Enclave nor a token uses a passphrase-protected key file for Keychain to
    # hold.
    package = pkgs.openssh;

    # Home Manager's implicit global block is deprecated on 26.05; opt out and
    # declare the defaults we actually want.
    enableDefaultConfig = false;

    settings = {
      # Rendered last, so any per-host block added above wins: ssh keeps the
      # first value it obtains for a given directive.
      "*" = {
        # Every interactive key is served by the Secure Enclave agent.
        IdentityAgent = secretiveAgent;

        # Enclave and token keys are never loaded into an agent, so there is
        # nothing to add.
        AddKeysToAgent = "no";

        HashKnownHosts = "yes";
        ServerAliveInterval = 60;
        ServerAliveCountMax = 3;
      };

      # A YubiKey key is used through its handle file rather than the agent, so
      # it coexists with IdentityAgent above. Uncomment once enrolled:
      #
      # "github.com" = {
      #   HostName = "github.com";
      #   User = "git";
      #   IdentityFile = "~/.ssh/id_ed25519_sk";
      #   IdentitiesOnly = "yes";
      # };
    };
  };
}
