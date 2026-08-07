{
  lib,
  pkgs,
  ...
}:

let
  zed = "dev.zed.Zed";

  # macOS has no UTI for `.nix`, so it synthesises a per-extension `dyn.*`
  # identifier, and LaunchServices refuses to record a handler for those
  # (`duti` reports -50). This bundle exists only to declare a real UTI; it has
  # no executable and is never launched. Registering it makes `.nix` resolve to
  # `org.nixos.nix-expression`, which can then be bound like any other type.
  nixUti = "org.nixos.nix-expression";

  nixTypeApp = pkgs.runCommand "nix-type-app" { } ''
    mkdir -p "$out/NixType.app/Contents"
    cat > "$out/NixType.app/Contents/Info.plist" <<'PLIST'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key><string>org.nixos.nixtype</string>
      <key>CFBundleName</key><string>NixType</string>
      <key>CFBundlePackageType</key><string>APPL</string>
      <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
      <key>CFBundleShortVersionString</key><string>1.0</string>
      <key>UTExportedTypeDeclarations</key>
      <array>
        <dict>
          <key>UTTypeIdentifier</key><string>${nixUti}</string>
          <key>UTTypeDescription</key><string>Nix expression</string>
          <key>UTTypeConformsTo</key>
          <array><string>public.source-code</string></array>
          <key>UTTypeTagSpecification</key>
          <dict><key>public.filename-extension</key><array><string>nix</string></array></dict>
        </dict>
      </array>
    </dict>
    </plist>
    PLIST
  '';

  # LaunchServices matches handlers by UTI, not extension; apps must declare the
  # UTI in their Info.plist.
  utis = [
    nixUti
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
    # `nix` is bound through nixUti above; as a bare extension it resolves to a
    # dyn.* type and LaunchServices rejects it.
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

  lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister";

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
  # The type-declaring bundle must be registered before anything can be bound to
  # the UTI it exports.
  home.file."Applications/NixType.app".source = "${nixTypeApp}/NixType.app";

  home.activation.defaultApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${lsregister} -f "$HOME/Applications/NixType.app" || true
    ${setAll}
  '';
}
