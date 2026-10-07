{ pkgs, lib, ... }:

let
  policy = builtins.fromJSON (builtins.readFile ./formatting.json);
  formatter = item: {
    name = item.name;
    value = {
      command =
        let
          package = pkgs.${item.package};
          withPlugins =
            if item.plugins == [ ] then
              package
            else
              package.withPlugins (ps: map (name: ps.${name}) item.plugins);
        in
        lib.getExe withPlugins;
      inherit (item) includes priority;
      options = map (
        option:
        if option == "@configuration@" then
          toString (pkgs.writeText "${item.name}.json" (builtins.toJSON item.configuration))
        else
          option
      ) item.options;
    };
  };
in
{
  inherit (policy) projectRootFile;
  settings = {
    excludes = lib.mkForce policy.excludes;
    formatter = builtins.listToAttrs (map formatter policy.formatters);
  };
}
