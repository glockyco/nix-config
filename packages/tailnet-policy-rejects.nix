{
  managedHosts,
  peers,
  runCommand,
  tailnetPolicyRenderer,
}:

let
  render =
    overrides:
    tailnetPolicyRenderer (
      {
        inherit managedHosts peers;
      }
      // overrides
    );
  force = value: builtins.tryEval (builtins.deepSeq value.policy true);
  fixturePeer = {
    tag = "tag:fixture-peer";
    lifecycle = "temporary";
    purpose = "Rejection fixture.";
  };

  # Proves the fixture renders, so each rejection below comes from the one
  # field it removes.
  completePeer = force (render {
    peers = peers // {
      fixture-peer = fixturePeer;
    };
  });

  unreachableGrant = force (render {
    grantDestinations = [
      "tag:macbook-pro"
      "tag:korolev"
    ];
  });

  emailAddress = force (render {
    managedHosts = managedHosts // {
      macbook-pro = managedHosts.macbook-pro // {
        username = "person@example.com";
      };
    };
  });

  missingLifecycle = force (render {
    peers = peers // {
      fixture-peer = removeAttrs fixturePeer [ "lifecycle" ];
    };
  });

  missingPurpose = force (render {
    peers = peers // {
      fixture-peer = removeAttrs fixturePeer [ "purpose" ];
    };
  });
in
assert completePeer.success;
assert !unreachableGrant.success;
assert !emailAddress.success;
assert !missingLifecycle.success;
assert !missingPurpose.success;
runCommand "check-tailnet-policy-rejections" { } "touch $out"
