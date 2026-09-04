{
  binaryCaches,
  hostName,
  runCommand,
  settings,
}:

let
  expected = {
    substituters = [ "https://cache.numtide.com" ];
    trustedPublicKeys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };
in
# The host modules consume `binaryCaches` directly. This independent oracle
# ensures that a typo in the shared declaration does not become a false green.
assert binaryCaches == expected;
assert settings == expected;
runCommand "check-${hostName}-nix-settings" { } "touch $out"
