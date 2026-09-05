{
  jq,
  lib,
  managedHosts,
  peers,
  runCommand,
  tailnetPolicy,
  tailnetPolicyRenderer,
}:

let
  airlessPeers = removeAttrs peers [ "macbook-air" ];
  airlessPolicy = tailnetPolicyRenderer {
    inherit managedHosts;
    peers = airlessPeers;
  };
  hostTags = map (host: host.tailnet.tag) (builtins.attrValues managedHosts);
  reachableHostTags = map (host: host.tailnet.tag) (
    builtins.filter (host: host.tailnet.reachable) (builtins.attrValues managedHosts)
  );
  peerTags = declaredPeers: map (peer: peer.tag) (builtins.attrValues declaredPeers);
  expectedTags = declaredPeers: builtins.toJSON (hostTags ++ peerTags declaredPeers);
  expectedReachable = declaredPeers: builtins.toJSON (reachableHostTags ++ peerTags declaredPeers);
in
runCommand "check-tailnet-policy"
  {
    nativeBuildInputs = [ jq ];
  }
  ''
    check_policy() {
      jq -e --argjson tags "$2" --argjson reachable "$3" '
        (has("ssh") | not)
        and (has("sshTests") | not)
        and ((.tagOwners | keys | sort) == ($tags | sort))
        and all(.tagOwners[]; . == ["autogroup:admin"])
        and (.grants | length == 1)
        and (.grants[0].src == ["*"] and .grants[0].ip == ["*"])
        and ((.grants[0].dst | sort) == ($reachable | sort))
        and all(.grants[].dst[]; . != "tag:korolev")
        and (([.tests[].src] | sort) == ($reachable | sort))
        and all(.tests[]; .proto == "tcp" and .deny == ["tag:korolev:22"])
        and ([.. | strings] | all(contains("@") | not))
      ' "$1" >/dev/null
    }

    check_policy ${tailnetPolicy}/policy.hujson \
      ${lib.escapeShellArg (expectedTags peers)} \
      ${lib.escapeShellArg (expectedReachable peers)}
    check_policy ${airlessPolicy}/policy.hujson \
      ${lib.escapeShellArg (expectedTags airlessPeers)} \
      ${lib.escapeShellArg (expectedReachable airlessPeers)}

    if jq -e '.. | strings | select(contains("tag:macbook-air"))' \
      ${airlessPolicy}/policy.hujson >/dev/null
    then
      echo 'Airless policy retained tag:macbook-air' >&2
      exit 1
    fi

    touch "$out"
  ''
