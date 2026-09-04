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

  unreachableGrant = force (render {
    grantDestinations = [
      "tag:macbook-pro"
      "tag:korolev"
    ];
  });

  unreachableSsh = force (render {
    sshRules = [
      {
        action = "accept";
        src = [ "tag:macbook-pro" ];
        dst = [ "tag:korolev" ];
        users = [ "glockyco" ];
      }
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
      air = removeAttrs peers.air [ "lifecycle" ];
    };
  });

  missingPurpose = force (render {
    peers = peers // {
      air = removeAttrs peers.air [ "purpose" ];
    };
  });
in
assert !unreachableGrant.success;
assert !unreachableSsh.success;
assert !emailAddress.success;
assert !missingLifecycle.success;
assert !missingPurpose.success;
runCommand "check-tailnet-policy-rejections" { } "touch $out"
