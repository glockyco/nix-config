{
  callPackage,
  coreutils,
  diffutils,
  jq,
  runCommand,
  runtimeShell,
}:

let
  command = callPackage ./package.nix { };
in
runCommand "check-default-applications"
  {
    nativeBuildInputs = [
      coreutils
      diffutils
      jq
    ];
  }
  ''
    mkdir -p fixture state source/FileTypes.app/Contents destination
    cat > fixture/duti <<'EOF'
    #!${runtimeShell}
    set -eu
    case "$1" in
      -d|-x)
        if [ -f "$DUTI_STATE/$1-$2" ]; then
          cat "$DUTI_STATE/$1-$2"
        else
          exit 1
        fi
        ;;
      -s)
        printf '%s\n' "$*" >> "$DUTI_CALLS"
        case "''${DUTI_FAILURE:-}" in
          -50) printf '%s\n' 'Unable to set handler (error -50)' >&2; exit 19 ;;
          fatal) printf '%s\n' 'LaunchServices is unavailable' >&2; exit 23 ;;
        esac
        ;;
      *) exit 3 ;;
    esac
    EOF
    cat > fixture/lsregister <<'EOF'
    #!${runtimeShell}
    set -eu
    printf '%s\n' "$*" >> "$REGISTER_CALLS"
    if [ "''${REGISTER_FAIL:-0}" -eq 1 ]; then
      printf '%s\n' 'registration failed' >&2
      exit 31
    fi
    EOF
    chmod +x fixture/duti fixture/lsregister

    export DEFAULT_APPLICATIONS_DUTI=$PWD/fixture/duti
    export DEFAULT_APPLICATIONS_LSREGISTER=$PWD/fixture/lsregister
    export DUTI_STATE=$PWD/state DUTI_CALLS=$PWD/duti.calls REGISTER_CALLS=$PWD/register.calls
    printf '%s\n' 'bundle content' > source/FileTypes.app/Contents/Info.plist
    cp -R source/FileTypes.app destination/FileTypes.app
    touch -t 202001010000 destination/FileTypes.app/Contents/Info.plist
    jq -n --arg src "$PWD/source/FileTypes.app" --arg dst "$PWD/destination/FileTypes.app" '
      { bundle: { source: $src, destination: $dst }, bindings: [
        { app: "dev.zed.Zed", uti: "public.text" },
        { app: "dev.zed.Zed", extension: "src", uti: "local.filetype.src" },
        { app: "org.mail", scheme: "mailto" }
      ] }
    ' > declaration.json
    printf '%s\n' 'dev.zed.Zed' > state/-d-public.text
    printf '%s\n' 'path to app' 'dev.zed.Zed' > state/-x-src
    printf '%s\n' 'org.mail' > state/-d-mailto

    run_case() {
      ${command}/bin/default-applications --declaration "$1" > command.stdout 2> command.stderr
    }
    : > duti.calls
    : > register.calls
    before=$(stat -c %Y destination/FileTypes.app/Contents/Info.plist)
    run_case declaration.json
    test ! -s command.stdout
    test ! -s duti.calls
    test ! -s register.calls
    test "$(stat -c %Y destination/FileTypes.app/Contents/Info.plist)" = "$before"
    grep -qF 'bundle current' command.stderr
    grep -qF 'binding current: public.text' command.stderr
    grep -qF 'binding current: src' command.stderr
    grep -qF 'binding current: mailto' command.stderr

    printf '%s\n' 'outdated' > destination/FileTypes.app/Contents/Info.plist
    run_case declaration.json
    cmp source/FileTypes.app/Contents/Info.plist destination/FileTypes.app/Contents/Info.plist
    test "$(cat register.calls)" = "-f $PWD/destination/FileTypes.app"
    test "$(wc -l < register.calls)" -eq 1
    test ! -s duti.calls
    grep -qF 'bundle changed' command.stderr

    printf '%s\n' 'another.app' > state/-d-public.text
    : > duti.calls
    : > register.calls
    run_case declaration.json
    test "$(cat duti.calls)" = '-s dev.zed.Zed public.text all'
    test ! -s register.calls
    grep -qF 'binding changed: public.text' command.stderr

    printf '%s\n' 'dev.zed.Zed' > state/-d-public.text
    printf '%s\n' 'another.app' > state/-x-src
    : > duti.calls
    run_case declaration.json
    test "$(cat duti.calls)" = "$(printf '%s\n' '-s dev.zed.Zed local.filetype.src all' '-s dev.zed.Zed src all')"
    printf '%s\n' 'dev.zed.Zed' > state/-d-local.filetype.src
    rm state/-x-src
    : > duti.calls
    run_case declaration.json
    test ! -s duti.calls
    grep -qF 'binding current: src' command.stderr

    printf '%s\n' 'another.app' > state/-d-public.text
    : > duti.calls
    DUTI_FAILURE=-50 run_case declaration.json
    test "$(cat duti.calls)" = '-s dev.zed.Zed public.text all'
    grep -qF 'skipped dynamic type (error -50): public.text' command.stderr
    test ! -s register.calls

    if DUTI_FAILURE=fatal run_case declaration.json; then
      printf '%s\n' 'unexpected duti success' >&2
      exit 1
    else
      test "$?" -eq 23
    fi
    grep -qF 'binding failed: public.text -> dev.zed.Zed (exit 23)' command.stderr
    grep -qF 'LaunchServices is unavailable' command.stderr
    test ! -s register.calls

    printf '%s\n' 'outdated' > destination/FileTypes.app/Contents/Info.plist
    : > register.calls
    : > duti.calls
    if REGISTER_FAIL=1 run_case declaration.json; then
      printf '%s\n' 'unexpected registration success' >&2
      exit 1
    else
      test "$?" -eq 31
    fi
    test "$(wc -l < register.calls)" -eq 1
    test ! -s duti.calls
    grep -qF 'registration failed' command.stderr
    test "$(cat destination/FileTypes.app/Contents/Info.plist)" = outdated
    : > register.calls
    run_case declaration.json
    cmp source/FileTypes.app/Contents/Info.plist destination/FileTypes.app/Contents/Info.plist
    test "$(wc -l < register.calls)" -eq 1

    rm -rf destination/FileTypes.app
    : > register.calls
    if REGISTER_FAIL=1 run_case declaration.json; then
      printf '%s\n' 'a failed first registration unexpectedly passed' >&2
      exit 1
    else
      test "$?" -eq 31
    fi
    test ! -e destination/FileTypes.app
    test "$(wc -l < register.calls)" -eq 1
    : > register.calls
    run_case declaration.json
    cmp source/FileTypes.app/Contents/Info.plist destination/FileTypes.app/Contents/Info.plist
    test "$(wc -l < register.calls)" -eq 1

    touch "$out"
  ''
