{
  # The root flake advertises this cache through `nixConfig`, which reaches Nix
  # as a client-specified setting. A daemon setting states it once for the host,
  # so a repository command does not have to carry it.
  #
  # These supplement the default NixOS substituter rather than replacing it.
  nix.settings = {
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];

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
