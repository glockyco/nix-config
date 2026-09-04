{
  binaryCaches = import ./binary-caches.nix;
  tailnetPeers = import ./tailnet-peers.nix;
  zedSettings = import ./zed-settings.nix;
  zenPolicies = import ./zen-policies.nix;
}
