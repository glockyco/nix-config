let
  inherit (import ../shared) binaryCaches;
in
{
  # A daemon setting is the only source of this cache on this host. The root
  # flake declares no `nixConfig`, because Nix ignores a flake-provided key for
  # a user who is not in `trusted-users`, and it warns on every command.
  #
  # These supplement the default NixOS substituter rather than replacing it.
  nix.settings = {
    extra-substituters = binaryCaches.substituters;
    extra-trusted-public-keys = binaryCaches.trustedPublicKeys;

    # `nix build`, `nix flake check`, and `nixos-rebuild --flake` all require
    # both features.
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # `trusted-users` stays at its default of `root` alone. Adding the interactive
  # user would let any flake it evaluates add a substituter and a signing key,
  # which is the privilege this module exists to avoid needing.
}
