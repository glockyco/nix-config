{
  lib,
  runCommand,
}:
{
  managedHosts,
  peers,
  grantDestinations ? null,
  sshRules ? null,
}:

let
  validTag = tag: builtins.isString tag && builtins.match "^tag:[a-z0-9-]+$" tag != null;

  normalizeHost =
    name: host:
    if !(host ? tailnet) || !(host.tailnet ? tag) then
      throw "managed host `${name}` omits host.tailnet.tag"
    else if !validTag host.tailnet.tag then
      throw "managed host `${name}` has an invalid tailnet tag"
    else if !(host ? username) then
      throw "managed host `${name}` omits its username"
    else
      {
        inherit name;
        inherit (host) username;
        inherit (host.tailnet) tag;
        reachable = host.tailnet.reachable or true;
      };

  normalizePeer =
    name: peer:
    if !(peer ? tag) then
      throw "tailnet peer `${name}` omits its tag"
    else if !validTag peer.tag then
      throw "tailnet peer `${name}` has an invalid tag"
    else if !(peer ? lifecycle) then
      throw "tailnet peer `${name}` omits its lifecycle"
    else if
      !(builtins.elem peer.lifecycle [
        "durable"
        "temporary"
      ])
    then
      throw "tailnet peer `${name}` has an invalid lifecycle"
    else if !(peer ? purpose) || !builtins.isString peer.purpose || peer.purpose == "" then
      throw "tailnet peer `${name}` omits its purpose"
    else
      {
        inherit name;
        inherit (peer) tag lifecycle purpose;
        reachable = true;
      };

  hostEntries = lib.mapAttrsToList normalizeHost managedHosts;
  peerEntries = lib.mapAttrsToList normalizePeer peers;
  entries = hostEntries ++ peerEntries;
  tags = map (entry: entry.tag) entries;

  findHost =
    name:
    let
      matches = builtins.filter (entry: entry.name == name) hostEntries;
    in
    if builtins.length matches == 1 then
      builtins.head matches
    else
      throw "tailnet policy requires managed host `${name}`";

  macbookPro = findHost "macbook-pro";
  korolev = findHost "korolev";
  unreachableTags = map (entry: entry.tag) (builtins.filter (entry: !entry.reachable) hostEntries);
  reachableTags = map (entry: entry.tag) (builtins.filter (entry: entry.reachable) entries);

  selectedGrantDestinations = if grantDestinations == null then reachableTags else grantDestinations;
  selectedSshRules =
    if sshRules == null then
      [
        {
          action = "accept";
          src = [ korolev.tag ];
          dst = [ macbookPro.tag ];
          users = [ macbookPro.username ];
        }
        {
          action = "check";
          src = [ "autogroup:member" ];
          dst = [ macbookPro.tag ];
          users = [ macbookPro.username ];
        }
      ]
    else
      sshRules;

  policy = {
    tagOwners = builtins.listToAttrs (
      map (tag: {
        name = tag;
        value = [ "autogroup:admin" ];
      }) tags
    );

    grants = [
      {
        src = [ "*" ];
        dst = selectedGrantDestinations;
        ip = [ "*" ];
      }
    ];

    ssh = selectedSshRules;

    tests = map (tag: {
      src = tag;
      proto = "tcp";
      deny = [ "${korolev.tag}:22" ];
    }) reachableTags;

    sshTests = [
      {
        src = korolev.tag;
        dst = [ macbookPro.tag ];
        accept = [ macbookPro.username ];
      }
      {
        src = macbookPro.tag;
        dst = [ korolev.tag ];
        deny = [ macbookPro.username ];
      }
    ];
  };

  ruleDestinations = lib.concatMap (rule: rule.dst or [ ]) (policy.grants ++ policy.ssh);
  unreachableDestinations = builtins.filter (tag: builtins.elem tag unreachableTags) ruleDestinations;
  unknownDestinations = builtins.filter (tag: !(builtins.elem tag tags)) ruleDestinations;
  rendered = builtins.toJSON policy;
in
assert builtins.deepSeq hostEntries true;
assert builtins.deepSeq peerEntries true;
assert !korolev.reachable;
assert tags != [ ];
assert builtins.length tags == builtins.length (lib.unique tags);
assert unreachableDestinations == [ ];
assert unknownDestinations == [ ];
assert !(lib.hasInfix "@" rendered);
runCommand "tailnet-policy"
  {
    passthru = {
      inherit
        policy
        reachableTags
        rendered
        unreachableTags
        ;
    };
  }
  ''
    mkdir -p "$out"
    printf '%s\n' ${lib.escapeShellArg rendered} > "$out/policy.hujson"
  ''
