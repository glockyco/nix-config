{
  lib,
  pkgs,
  ...
}:

let
  zed = "dev.zed.Zed";
  thunderbird = "org.mozilla.thunderbird";

  thunderbirdHandlers = [
    "mailto"
    "news"
    "feed"
    "net.thunderbird"
  ];

  # Extensions macOS has no UTI for. It synthesises a per-extension `dyn.*`
  # identifier for these, and LaunchServices refuses to record a handler against
  # one (`duti` fails with -50), so binding them is a silent no-op.
  #
  # This bundle declares a real UTI for each. It has no executable and is never
  # launched; registering it is enough for the types to exist. Measured with
  # `mdls -name kMDItemContentType` on a probe file per extension -- anything
  # already resolving to a real type is bound directly and is not listed here.
  declaredTypes = {
    nix = {
      uti = "org.nixos.nix-expression";
      description = "Nix expression";
    };
    toml.description = "TOML document";
    ini.description = "INI configuration";
    conf.description = "Configuration file";
    cfg.description = "Configuration file";
    env.description = "Environment file";
    lock.description = "Lock file";
    sql.description = "SQL source";
    rs.description = "Rust source";
    go.description = "Go source";
    lua.description = "Lua source";
    tsx.description = "TypeScript JSX source";
    jsx.description = "JavaScript JSX source";
    scss.description = "SCSS stylesheet";
    # No `gitignore`/`gitconfig`: macOS resolves those dotfiles to `public.data`
    # regardless of a declaration, and binding `public.data` would hand Zed
    # every unrecognised file on the system.
  };

  utiOf = ext: declaredTypes.${ext}.uti or "local.filetype.${ext}";

  typeDeclaration = ext: type: ''
    <dict>
      <key>UTTypeIdentifier</key><string>${utiOf ext}</string>
      <key>UTTypeDescription</key><string>${type.description}</string>
      <key>UTTypeConformsTo</key>
      <array><string>public.source-code</string></array>
      <key>UTTypeTagSpecification</key>
      <dict><key>public.filename-extension</key><array><string>${ext}</string></array></dict>
    </dict>'';

  fileTypesApp = pkgs.runCommand "file-types-app" { } ''
    mkdir -p "$out/FileTypes.app/Contents"
    cat > "$out/FileTypes.app/Contents/Info.plist" <<'PLIST'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key><string>local.filetypes</string>
      <key>CFBundleName</key><string>FileTypes</string>
      <key>CFBundlePackageType</key><string>APPL</string>
      <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
      <key>CFBundleShortVersionString</key><string>1.0</string>
      <key>UTExportedTypeDeclarations</key>
      <array>
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList typeDeclaration declaredTypes)}
      </array>
    </dict>
    </plist>
    PLIST
  '';

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

  # Extensions that already resolve to a real UTI. `dockerfile` is excluded: it
  # has no extension to declare and resolves to `public.data`, so binding it
  # would make Zed the handler for every unrecognised file.
  extensions = [
    "log"
    "csv"
    "tsv"
    "diff"
    "patch"
    "py"
    "rb"
    "ts" # also MPEG-2 transport stream; Zed wins for both
    "js"
    "css"
  ];

  duti = "${pkgs.duti}/bin/duti";

  lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister";

  setAll = builtins.concatStringsSep "\n" (
    map (t: "run ${duti} -s ${zed} ${lib.escapeShellArg t} all || true") (
      utis ++ map utiOf (builtins.attrNames declaredTypes) ++ extensions
    )
  );

  setThunderbird = builtins.concatStringsSep "\n" (
    map (t: "run ${duti} -s ${thunderbird} ${lib.escapeShellArg t} || true") thunderbirdHandlers
  );
in

{
  # `duti` binds many UTIs and extensions via LaunchServices; Finder's "Change
  # All" only rebinds one UTI.
  # Reapply on every activation because LaunchServices bindings can be rebuilt by
  # OS updates, app installs, or `lsregister -kill`.
  # First activation shows a confirmation dialog per type; later activations are silent.
  # Ignore unknown UTIs so one failure does not abort activation.
  #
  # The bundle is copied, not symlinked: LaunchServices ignores the type
  # declarations of a bundle reached through a symlink, so a store link
  # registers as an app that declares nothing. Measured, not documented.
  home.activation.defaultApplications = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/rm -rf $VERBOSE_ARG "$HOME/Applications/FileTypes.app"
    run ${pkgs.coreutils}/bin/cp -R $VERBOSE_ARG ${fileTypesApp}/FileTypes.app "$HOME/Applications/FileTypes.app"
    run ${pkgs.coreutils}/bin/chmod -R u+w "$HOME/Applications/FileTypes.app"
    run ${lsregister} -f "$HOME/Applications/FileTypes.app" || true
    ${setAll}
    ${setThunderbird}
  '';
}
