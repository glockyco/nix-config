{
  lib,
  pkgs,
  ...
}:

let
  zed = "dev.zed.Zed";
  pdfExpert = "com.readdle.PDFExpert-Mac";
  thunderbird = "org.mozilla.thunderbird";

  thunderbirdHandlers = [
    "mailto"
    "news"
    "feed"
    "net.thunderbird"
  ];

  # Every file type Zed should own, keyed by extension. One flat list suffices;
  # three measured facts remove the per-extension case analysis this module used
  # to need.
  #
  # 1. macOS has no UTI for most source extensions. It synthesises a per-file
  #    `dyn.*` identifier, and LaunchServices refuses to record a handler
  #    against one (`duti` fails with -50). `fileTypesApp` below exports a real
  #    `local.filetype.<ext>` UTI for every entry, which removes that failure.
  # 2. Where macOS already has a type, the system declaration wins and ours is
  #    inert: a probe bundle exporting types for `py`, `csv` and `java` left
  #    `mdls -name kMDItemContentType` at `public.python-script`,
  #    `public.comma-separated-values-text` and `com.sun.java-source`. So
  #    declaring an extension that already has a type is harmless.
  # 3. `duti -s <app> <ext>` resolves the extension to whichever UTI macOS
  #    reports, which covers case 2. The app need not declare the type: Zed
  #    claims `public.plain-text`, every type here conforms to
  #    `public.source-code`, and LaunchServices matches by conformance. Binding
  #    `public.swift-source` through the bare `swift` extension works even
  #    though Zed's `Info.plist` never mentions Swift.
  #
  # Each entry therefore gets one declaration and two bindings -- the declared
  # UTI and the bare extension -- and exactly one of them lands. Adding a type
  # is one line, with no measurement.
  #
  # Names without an extension (`Dockerfile`, `Makefile`, `.gitignore`,
  # `.editorconfig`) cannot be handled at all: macOS resolves them to
  # `public.data`, and binding that would hand Zed every unrecognised file on
  # the system. `plist` is out for a related reason: macOS resolves even a
  # well-formed XML property list to the abstract `com.apple.property-list`,
  # which reports "no default handler" and keeps none after `duti -s`.
  #
  # Types left with other apps on purpose, because the other app is the better
  # tool: `html` (browser), crash and panic reports (Console),
  # playlists (Music), `rtf` (TextEdit), `.rss` feeds (Thunderbird),
  # `mobileconfig` and friends (Profile Helper), AppleScript (Script Editor).
  #
  # To list types that still escape Zed, including ones no entry here covers:
  #
  #   lsregister -dump | grep -oE 'uti: +[a-zA-Z0-9._+-]+' | sed 's/uti: *//' |
  #     sort -u | while read -r u; do echo "$(duti -d "$u" 2>/dev/null)  $u"; done |
  #     grep -v dev.zed.Zed
  #
  # Two behaviours to expect when this list grows. macOS asks the user to
  # confirm each handler change, so the activation that first binds a type
  # raises one dialog for it -- adding fifty types means fifty dialogs, once.
  # And LaunchServices records the binding asynchronously: `duti -d` right after
  # `duti -s` still reports the old handler, so wait a few seconds before
  # reading a binding back.
  fileTypes = {
    # C and friends
    c = "C source";
    h = "C header";
    cc = "C++ source";
    cpp = "C++ source";
    cxx = "C++ source";
    hh = "C++ header";
    hpp = "C++ header";
    hxx = "C++ header";
    inl = "C++ inline header";
    cu = "CUDA source";
    cuh = "CUDA header";
    ino = "Arduino sketch";
    m = "Objective-C source";
    mm = "Objective-C++ source";
    s = "Assembly source";

    # .NET
    cs = "C# source";
    csproj = "C# project";
    sln = "Visual Studio solution";
    razor = "Razor component";
    cshtml = "Razor page";
    vb = "Visual Basic source";
    fs = "F# source";
    fsproj = "F# project";

    # JVM
    java = "Java source";
    kt = "Kotlin source";
    kts = "Kotlin script";
    groovy = "Groovy source";
    gradle = "Gradle build script";
    scala = "Scala source";
    sbt = "Scala build script";
    clj = "Clojure source";
    cljs = "ClojureScript source";

    # Web
    js = "JavaScript source";
    mjs = "JavaScript module";
    cjs = "CommonJS module";
    jsx = "JavaScript JSX source";
    ts = "TypeScript source"; # also MPEG-2 transport stream; Zed wins for both
    mts = "TypeScript module"; # also AVCHD video; Zed wins for both
    cts = "TypeScript CommonJS module";
    tsx = "TypeScript JSX source";
    vue = "Vue component";
    svelte = "Svelte component";
    astro = "Astro component";
    css = "CSS stylesheet";
    scss = "SCSS stylesheet";
    sass = "Sass stylesheet";
    less = "Less stylesheet";
    postcss = "PostCSS stylesheet";

    # Markup and structured data. `html` and `xhtml` stay out on purpose: a
    # browser is the better handler. `svg` needs no entry -- it conforms to
    # `public.xml`, so the root binding below already sends it to Zed.
    xsd = "XML schema";
    xsl = "XSLT stylesheet";
    xslt = "XSLT stylesheet";
    jsp = "JSP page";
    json5 = "JSON5 document";
    jsonc = "JSON document with comments";
    jsonl = "JSON Lines document";
    ndjson = "Newline-delimited JSON document";
    geojson = "GeoJSON document";
    toml = "TOML document";
    ini = "INI configuration";
    conf = "Configuration file";
    cfg = "Configuration file";
    properties = "Java properties";
    env = "Environment file";
    lock = "Lock file";

    # Prose and typesetting
    mdx = "MDX document";
    rst = "reStructuredText document";
    adoc = "AsciiDoc document";
    org = "Org document";
    typ = "Typst source";
    tex = "TeX source";
    latex = "LaTeX source";
    sty = "TeX style";
    cls = "TeX class";
    bib = "BibTeX bibliography";
    bibtex = "BibTeX bibliography";
    biblatex = "BibLaTeX bibliography";

    # Scripting
    sh = "Shell script";
    bash = "Bash script";
    zsh = "Zsh script";
    ksh = "Ksh script";
    csh = "Csh script";
    tcsh = "Tcsh script";
    fish = "Fish script";
    nu = "Nushell script";
    ps1 = "PowerShell script";
    bat = "Batch script";
    cmd = "Batch script";
    pl = "Perl source";
    pm = "Perl module";
    php = "PHP source";
    py = "Python source";
    pyi = "Python stub";
    pyx = "Cython source";
    rb = "Ruby source";
    erb = "ERB template";
    lua = "Lua source";
    vim = "Vim script";
    el = "Emacs Lisp source";
    scm = "Scheme source";
    rkt = "Racket source";

    # Compiled languages
    rs = "Rust source";
    go = "Go source";
    mod = "Go module file";
    work = "Go workspace file";
    swift = "Swift source";
    zig = "Zig source";
    nim = "Nim source";
    d = "D source";
    hs = "Haskell source";
    ml = "OCaml source";
    erl = "Erlang source";
    ex = "Elixir source";
    exs = "Elixir script";
    jl = "Julia source";
    dart = "Dart source";

    # Languages macOS types but leaves with TextEdit
    ada = "Ada source";
    f = "Fortran source";
    f77 = "Fortran 77 source";
    f90 = "Fortran 90 source";
    f95 = "Fortran 95 source";
    pas = "Pascal source";
    l = "Lex source";
    y = "Yacc source";
    defs = "MIG definitions";
    iig = "IOKit interface definitions";
    r = "Rez source"; # also R source; Zed suits both
    swiftinterface = "Swift module interface";

    # Queries and schemas
    sql = "SQL source";
    graphql = "GraphQL document";
    gql = "GraphQL document";
    sparql = "SPARQL query";
    prisma = "Prisma schema";
    proto = "Protocol Buffers schema";

    # Infrastructure
    nix = "Nix expression";
    dhall = "Dhall expression";
    hcl = "HCL document";
    tf = "Terraform configuration";
    tfvars = "Terraform variables";
    just = "Justfile";
    mk = "Makefile fragment";
    cmake = "CMake script";

    # Templates
    vm = "Velocity template";
    ftl = "FreeMarker template";
    mustache = "Mustache template";
    hbs = "Handlebars template";
    jinja = "Jinja template";
    j2 = "Jinja template";
    twig = "Twig template";

    # Plain data
    log = "Log file";
    csv = "Comma-separated values";
    tsv = "Tab-separated values";
    diff = "Diff";
    patch = "Patch";
  };

  utiOf = ext: "local.filetype.${ext}";

  typeDeclaration = ext: description: ''
    <dict>
      <key>UTTypeIdentifier</key><string>${utiOf ext}</string>
      <key>UTTypeDescription</key><string>${description}</string>
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
    ${lib.concatStringsSep "\n" (lib.mapAttrsToList typeDeclaration fileTypes)}
      </array>
    </dict>
    </plist>
    PLIST
  '';

  # Type roots, for files whose extension is not in the list above. A root
  # binding loses to any per-type default, so it is a fallback, not a
  # replacement for an entry in `fileTypes`.
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

  duti = "${pkgs.duti}/bin/duti";

  lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister";

  # Bind only what Zed does not already own. Rebinding a type that is already
  # Zed's costs a `duti` call per type on every activation and risks raising the
  # confirmation dialog again, so each binding is gated on a read first.
  bindings = ''
    handlerOfUti() {
      ${duti} -d "$1" 2>/dev/null || true
    }

    bindUti() {
      if test "$(handlerOfUti "$2")" != "$1"; then
        run ${duti} -s "$1" "$2" all || true
      fi
    }

    bindScheme() {
      if test "$(handlerOfUti "$2")" != "$1"; then
        run ${duti} -s "$1" "$2" || true
      fi
    }

    # `$1` is the extension and `$2` the UTI this module declares for it. One of
    # the two bindings lands: the declared UTI when macOS has no type of its own
    # for the extension, the extension's system UTI when it has.
    #
    # `duti -x` reports the handler macOS would use for the extension, which is
    # the authoritative answer, but it fails for some types whose UTI does have a
    # handler (`fs`). Fall back to the declared UTI so those are not rebound on
    # every activation.
    #
    # Home Manager activation runs under `set -e` and `set -o pipefail`, so the
    # read has to end in `|| true`: `duti -x` exits nonzero for an extension with
    # no handler, and that would abort activation.
    bindExtension() {
      local handler
      handler="$(${duti} -x "$1" 2>/dev/null | tail -1 || true)"
      if test -z "$handler"; then
        handler="$(handlerOfUti "$2")"
      fi

      if test "$handler" != ${zed}; then
        run ${duti} -s ${zed} "$2" all || true
        run ${duti} -s ${zed} "$1" all || true
      fi
    }
  '';

  setAll = builtins.concatStringsSep "\n" (
    map (u: "bindUti ${zed} ${lib.escapeShellArg u}") utis
    ++ map (ext: "bindExtension ${lib.escapeShellArg ext} ${lib.escapeShellArg (utiOf ext)}") (
      builtins.attrNames fileTypes
    )
  );

  setThunderbird = builtins.concatStringsSep "\n" (
    map (t: "bindScheme ${thunderbird} ${lib.escapeShellArg t}") thunderbirdHandlers
  );

  setPdfExpert = "bindUti ${pdfExpert} com.adobe.pdf";
in

{
  # `duti` binds many UTIs and extensions via LaunchServices; Finder's "Change
  # All" only rebinds one UTI.
  # Reapply on every activation because LaunchServices bindings can be rebuilt by
  # OS updates, app installs, or `lsregister -kill`. A binding that already
  # points at the right app is read and skipped, so a steady-state activation
  # writes nothing and raises no dialog.
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
    ${bindings}
    ${setAll}
    ${setPdfExpert}
    ${setThunderbird}
  '';
}
