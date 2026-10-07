{ rules, source }:
description:
let
  matches = builtins.filter (rule: (rule.description or null) == description) rules;
in
if builtins.length matches != 1 then
  throw "karabiner: expected one rule described as '${description}' in ${source} -- upstream renamed, removed or duplicated it"
else
  builtins.head matches
