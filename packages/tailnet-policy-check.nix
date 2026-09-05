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
  expectedSources = lib.naturalSort tailnetPolicy.reachableTags;
  testSources = lib.naturalSort (map (test: test.src) tailnetPolicy.policy.tests);
  airlessPolicy = tailnetPolicyRenderer {
    inherit managedHosts;
    peers = removeAttrs peers [ "macbook-air" ];
  };
  expectedSourcesJson = builtins.toJSON expectedSources;
in
assert testSources == expectedSources;
assert lib.all (
  test: test.proto == "tcp" && test.deny == [ "tag:korolev:22" ]
) tailnetPolicy.policy.tests;
assert !(lib.hasInfix "tag:macbook-air" airlessPolicy.rendered);
runCommand "check-tailnet-policy"
  {
    nativeBuildInputs = [ jq ];
  }
  ''
    policy=${tailnetPolicy}/policy.hujson
    airless_policy=${airlessPolicy}/policy.hujson

    jq -e . "$policy" >/dev/null
    jq -e '
      ([.grants[].dst[], .ssh[].dst[]] | all(. != "tag:korolev"))
      and all(.tests[]; .proto == "tcp" and .deny == ["tag:korolev:22"])
    ' "$policy" >/dev/null
    jq -e --argjson expected ${lib.escapeShellArg expectedSourcesJson} '
      ([.tests[].src] | sort) == ($expected | sort)
    ' "$policy" >/dev/null

    jq -e . "$airless_policy" >/dev/null
    if jq -e '.. | strings | select(contains("tag:macbook-air"))' "$airless_policy" >/dev/null; then
      echo 'Airless policy retained tag:macbook-air' >&2
      exit 1
    fi

    touch "$out"
  ''
