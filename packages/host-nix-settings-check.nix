{
  binaryCaches,
  hostName,
  runCommand,
  settings,
}:

let
  validPublicKey = key: builtins.match "[A-Za-z0-9._-]+:[A-Za-z0-9+/]{43}=" key != null;
in
# Equality catches a host that stops consuming the shared declaration. Syntax
# validation rejects a malformed shared key without pinning its value here, so
# a valid key rotation still needs one declaration edit.
assert settings == binaryCaches;
assert binaryCaches.trustedPublicKeys != [ ];
assert builtins.all validPublicKey binaryCaches.trustedPublicKeys;
runCommand "check-${hostName}-nix-settings" { } "touch $out"
