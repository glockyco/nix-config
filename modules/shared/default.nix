{
  binaryCaches = import ./binary-caches.nix;
  tailnetDnsDomain = "tail8768af.ts.net";
  tailnetPeers = import ./tailnet-peers.nix;
  zedSettings = import ./zed-settings.nix;
  zenPolicies = import ./zen-policies.nix;
}
