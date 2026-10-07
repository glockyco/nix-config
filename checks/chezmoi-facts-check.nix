{
  lib,
  runCommand,
  hosts,
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
  selectedRule = {
    description = "fixture";
    manipulators = [ ];
  };
  selectRule =
    rules:
    import ../lib/karabiner-rule.nix {
      inherit rules;
      source = "fixture";
    };
  rejectedRule =
    rules: description: builtins.tryEval (builtins.deepSeq ((selectRule rules) description) true);
  cases = lib.concatMap (
    host:
    [
      (force (host // { username = 42; }))
      (force (
        host
        // {
          git = host.git // {
            defaultEmail = 42;
          };
        }
      ))
      (force (
        host
        // {
          roles = host.roles // {
            desktop = "true";
          };
        }
      ))
    ]
    ++ lib.optionals (host.darwin.containerProfile != null) [
      (force (
        host
        // {
          darwin = host.darwin // {
            containerProfile = host.darwin.containerProfile // {
              cpu = 0;
            };
          };
        }
      ))
      (force (
        host
        // {
          darwin = host.darwin // {
            containerProfile = host.darwin.containerProfile // {
              mounts = [ ];
            };
          };
        }
      ))
    ]
  ) (builtins.attrValues hosts);
in
assert builtins.all (host: (force host).success) (builtins.attrValues hosts);
assert builtins.all (result: !result.success) cases;
assert (selectRule [ selectedRule ]) "fixture" == selectedRule;
assert !(rejectedRule [ selectedRule ] "renamed").success;
assert !(rejectedRule [ selectedRule selectedRule ] "fixture").success;
runCommand "check-chezmoi-fact-types" { } "touch $out"
