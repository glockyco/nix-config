{
  binaryCaches = import ./binary-caches.nix;
  nixPolicy = import ./nix-policy.nix;
  tailnetDnsDomain =
    (builtins.fromTOML (builtins.readFile ../../home/.chezmoidata/ssh.toml)).ssh.tailnetDnsDomain;
  tailnetPeers = import ./tailnet-peers.nix;
  zedSettings = import ./zed-settings.nix;
  zenPolicies = import ./zen-policies.nix;
  userPackages = import ./user-packages.nix;
  userEnvironment = ./user-environment.nix;
}
