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

  forceApplications =
    applications:
    builtins.tryEval (
      builtins.deepSeq
        (lib.evalModules {
          modules = [
            ../modules/fleet/host.nix
            { config.host.darwin.applications = applications; }
          ];
        }).config.host.darwin.applications
        true
    );

  loginStartWithPath = forceApplications [
    {
      cask = "fixture";
      appPath = "/Applications/Fixture.app";
      startAtLogin = true;
      rationale = "Fixture application.";
    }
  ];

  loginStartWithoutPath = forceApplications [
    {
      cask = "fixture";
      startAtLogin = true;
      rationale = "Fixture application.";
    }
  ];
in
assert !missingUsername.success;
assert !missingTag.success;
assert !malformedTag.success;
assert loginStartWithPath.success;
assert !loginStartWithoutPath.success;
runCommand "check-host-declaration" { } "touch $out"
