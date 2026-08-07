{
  lib,
  pkgs,
  ...
}:

let
  zed = "dev.zed.Zed";

  # LaunchServices matches handlers by UTI, not extension; apps must declare the
  # UTI in their Info.plist.
  utis = [
    "public.text"
    "public.plain-text"
    "public.utf8-plain-text"
    "public.source-code"
    "public.shell-script"
    "public.script"
    "public.xml"
    "public.json"
    "public.yaml"
    "net.daringfireball.markdown"
  ];

  # UTI conformance does not inherit default handlers; bind concrete types too.
  extensions = [
    "nix"
    "toml"
    "ini"
    "conf"
    "cfg"
    "env"
    "lock"
    "log"
    "csv"
    "tsv"
    "diff"
    "patch"
    "gitignore"
    "gitconfig"
    "dockerfile"
    "sql"
    "rs"
    "go"
    "py"
    "rb"
    "lua"
    "ts"
    "tsx"
    "js"
    "jsx"
    "css"
    "scss"
  ];

  duti = "${pkgs.duti}/bin/duti";

  setAll = builtins.concatStringsSep "\n" (
    map (t: "run ${duti} -s ${zed} ${lib.escapeShellArg t} all || true") (utis ++ extensions)
  );
in

{
  # `duti` binds many UTIs and extensions via LaunchServices; Finder's "Change
  # All" only rebinds one UTI.
  # Reapply on every activation because LaunchServices bindings can be rebuilt by
  # OS updates, app installs, or `lsregister -kill`.
  # First activation shows a confirmation dialog per type; later activations are silent.
  # Ignore unknown UTIs so one failure does not abort activation.
  home.activation.defaultApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] setAll;
}
