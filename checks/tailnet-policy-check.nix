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
  # Offboarding a temporary peer must leave a valid policy with no trace of it.
  # A synthetic peer proves that without depending on a real declaration, which
  # offboarding itself removes.
  fixturePeers = peers // {
    fixture-peer = {
      tag = "tag:fixture-peer";
      lifecycle = "temporary";
      purpose = "Offboarding fixture.";
    };
  };
  fixturePolicy = tailnetPolicyRenderer {
    inherit managedHosts;
    peers = fixturePeers;
  };
  hostTags = map (host: host.tailnet.tag) (builtins.attrValues managedHosts);
  reachableHostTags = map (host: host.tailnet.tag) (
    builtins.filter (host: host.tailnet.reachable) (builtins.attrValues managedHosts)
  );
  unreachableHostTags = map (host: host.tailnet.tag) (
    builtins.filter (host: !host.tailnet.reachable) (builtins.attrValues managedHosts)
  );
  expectedDeny = builtins.toJSON (map (tag: "${tag}:22") unreachableHostTags);
  expectedUnreachable = builtins.toJSON unreachableHostTags;
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
      jq -e --argjson tags "$2" --argjson reachable "$3" --argjson unreachable "$4" --argjson deny "$5" '
        (has("ssh") | not)
        and (has("sshTests") | not)
        and ((.tagOwners | keys | sort) == ($tags | sort))
        and all(.tagOwners[]; . == ["autogroup:admin"])
        and (.grants | length == 1)
        and (.grants[0].src == ["*"] and .grants[0].ip == ["*"])
        and ((.grants[0].dst | sort) == ($reachable | sort))
        and all(.grants[].dst[]; . as $tag | ($unreachable | index($tag)) == null)
        and (([.tests[].src] | sort) == ($reachable | sort))
        and all(.tests[]; .proto == "tcp" and .deny == $deny)
        and ([.. | strings] | all(contains("@") | not))
      ' "$1" >/dev/null
    }

    check_policy ${tailnetPolicy}/policy.hujson \
      ${lib.escapeShellArg (expectedTags peers)} \
      ${lib.escapeShellArg (expectedReachable peers)} \
      ${lib.escapeShellArg expectedUnreachable} \
      ${lib.escapeShellArg expectedDeny}
    check_policy ${fixturePolicy}/policy.hujson \
      ${lib.escapeShellArg (expectedTags fixturePeers)} \
      ${lib.escapeShellArg (expectedReachable fixturePeers)} \
      ${lib.escapeShellArg expectedUnreachable} \
      ${lib.escapeShellArg expectedDeny}

    if ! jq -e '.. | strings | select(contains("tag:fixture-peer"))' \
      ${fixturePolicy}/policy.hujson >/dev/null
    then
      echo 'Fixture policy omitted tag:fixture-peer' >&2
      exit 1
    fi
    if jq -e '.. | strings | select(contains("tag:fixture-peer"))' \
      ${tailnetPolicy}/policy.hujson >/dev/null
    then
      echo 'Policy without the fixture peer retained tag:fixture-peer' >&2
      exit 1
    fi

    touch "$out"
  ''
