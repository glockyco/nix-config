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

  appStoreFixture = {
    masId = 123456;
    masName = "Fixture";
    rationale = "Fixture App Store application.";
  };
  appStore = forceApplications [ appStoreFixture ];
  appStoreLogin = forceApplications [
    (
      appStoreFixture
      // {
        appPath = "/Applications/Fixture.app";
        startAtLogin = true;
        dockPosition = 1;
      }
    )
  ];
  invalidApplications = map forceApplications [
    [ { rationale = "Missing application identity."; } ]
    [ (builtins.removeAttrs appStoreFixture [ "masName" ]) ]
    [ (builtins.removeAttrs appStoreFixture [ "masId" ]) ]
    [ (appStoreFixture // { masId = 0; }) ]
    [ (appStoreFixture // { masId = -1; }) ]
    [ (appStoreFixture // { masId = "123456"; }) ]
    [ (appStoreFixture // { masName = ""; }) ]
    [
      appStoreFixture
      (appStoreFixture // { masName = "Another fixture"; })
    ]
    [
      appStoreFixture
      (appStoreFixture // { masId = 654321; })
    ]
    [ (appStoreFixture // { startAtLogin = true; }) ]
    [ (appStoreFixture // { dockPosition = 1; }) ]
  ];
in
assert !missingUsername.success;
assert !missingTag.success;
assert !malformedTag.success;
assert loginStartWithPath.success;
assert !loginStartWithoutPath.success;
assert appStore.success;
assert appStoreLogin.success;
assert builtins.all (result: !result.success) invalidApplications;
runCommand "check-host-declaration" { } "touch $out"
