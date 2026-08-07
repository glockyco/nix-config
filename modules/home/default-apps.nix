{
  lib,
  pkgs,
  ...
}:

let
  zed = "dev.zed.Zed";

  # macOS resolves "open with" through LaunchServices, keyed by Uniform Type
  # Identifier rather than by file extension.
  #
  # An app can generally only become the default for a type it declares in its
  # Info.plist. Zed declares public.text, public.plain-text,
  # public.utf8-plain-text and public.folder -- `plutil -p
  # /Applications/Zed.app/Contents/Info.plist` if you need to check after an
  # update.
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

  # Conformance is not inheritance for the purposes of a default handler: a
  # concrete type with its own UTI keeps its own binding, and anything macOS
  # has not seen a declaration for falls back to extension matching. So the
  # common ones are bound explicitly as well.
  #
  # Deliberately absent: html and svg. Both are text, but double-clicking one
  # almost always means "render this", so they are left to the browser.
  #
  # `.nix` is listed but will not take: no installed application declares a
  # type for it, so LaunchServices has nothing to bind and Finder falls back to
  # asking. Harmless, and it starts working if anything ever claims the type.
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
  # Make Zed the default application for text and source files.
  #
  # Doing this in Finder with "Get Info -> Change All" only rebinds the single
  # UTI of the file you happened to right-click, which is why it never seems to
  # stick across file types. `duti` talks to the LaunchServices API directly and
  # can bind many types in one go.
  #
  # Re-running on every activation is the point: the LaunchServices database is
  # cache-like and gets rebuilt by OS updates, by installing an app that claims
  # these types, or by `lsregister -kill`. A one-off command silently degrades;
  # this re-imposes the bindings each switch.
  #
  # macOS 26 prompts for confirmation the first time a default handler changes,
  # so the initial activation pops a dialog per type and needs a human. Once
  # confirmed the binding sticks and later activations are silent -- this is
  # therefore declarative in effect but not fully unattended on first run.
  #
  # `|| true` per entry on purpose -- an unknown UTI on some macOS version
  # should not abort the whole Home Manager activation.
  home.activation.defaultApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] setAll;
}
