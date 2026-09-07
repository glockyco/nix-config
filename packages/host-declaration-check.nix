{
  lib,
  runCommand,
}:

let
  force =
    host:
    builtins.tryEval (
      builtins.deepSeq
        (lib.evalModules {
          modules = [
            ../modules/fleet/host.nix
            { config.host = host; }
          ];
        }).config.host
        true
    );

  missingUsername = force {
    name = "missing-user";
    tailnet.tag = "tag:missing-user";
  };

  missingTag = force {
    name = "missing-tag";
    username = "user";
  };

  malformedTag = force {
    name = "malformed-tag";
    username = "user";
    tailnet.tag = "malformed-tag";
  };
in
assert !missingUsername.success;
assert !missingTag.success;
assert !malformedTag.success;
runCommand "check-host-declaration" { } "touch $out"
