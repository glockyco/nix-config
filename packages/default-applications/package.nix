{
  coreutils,
  diffutils,
  duti,
  jq,
  lib,
  writeShellApplication,
}:

writeShellApplication {
  name = "default-applications";
  runtimeInputs = [
    coreutils
    diffutils
    jq
  ];

  text = ''
    if [[ $# -ne 2 || $1 != --declaration ]]; then
      printf '%s\n' 'default-applications: expected --declaration JSON' >&2
      exit 64
    fi
    declaration=$2
    if ! jq -e '
      (.bundle.source | type == "string" and length > 0) and
      (.bundle.destination | type == "string" and length > 0) and
      (.bindings | type == "array") and
      all(.bindings[];
        (.app | type == "string" and length > 0) and
        ((has("uti") and (.uti | type == "string" and length > 0) and (has("extension") | not) and (has("scheme") | not)) or
         (has("uti") and (.uti | type == "string" and length > 0) and (.extension | type == "string" and length > 0) and (has("scheme") | not)) or
         (has("scheme") and (.scheme | type == "string" and length > 0) and (has("uti") | not) and (has("extension") | not)))
      )
    ' "$declaration" >/dev/null; then
      printf 'default-applications: invalid declaration: %s\n' "$declaration" >&2
      exit 65
    fi

    duti_command="''${DEFAULT_APPLICATIONS_DUTI:-${lib.getExe duti}}"
    lsregister_command="''${DEFAULT_APPLICATIONS_LSREGISTER:-/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister}"
    source_bundle=$(jq -r '.bundle.source' "$declaration")
    destination_bundle=$(jq -r '.bundle.destination' "$declaration")

    bundle_current=false
    if [[ -d $destination_bundle ]]; then
      if diff -rq "$source_bundle" "$destination_bundle" >/dev/null; then
        bundle_current=true
      else
        status=$?
        if (( status != 1 )); then
          printf 'default-applications: could not compare bundle: %s\n' "$destination_bundle" >&2
          exit "$status"
        fi
      fi
    fi
    if [[ $bundle_current == true ]]; then
      printf 'default-applications: bundle current: %s\n' "$destination_bundle" >&2
    else
      parent=$(dirname "$destination_bundle")
      mkdir -p "$parent"
      staged=$(mktemp -d "$parent/.default-applications-new.XXXXXX")
      previous=$(mktemp -d "$parent/.default-applications-old.XXXXXX")
      new_installed=false
      restore_on_failure() {
        status=$?
        if [[ -e $previous/original ]]; then
          rm -rf "$destination_bundle"
          mv "$previous/original" "$destination_bundle"
        elif [[ $new_installed == true ]]; then
          rm -rf "$destination_bundle"
        fi
        rm -rf "$staged" "$previous"
        exit "$status"
      }
      trap restore_on_failure EXIT
      cp -R "$source_bundle" "$staged/FileTypes.app"
      chmod -R u+w "$staged/FileTypes.app"
      if [[ -e $destination_bundle ]]; then
        mv "$destination_bundle" "$previous/original"
      fi
      mv "$staged/FileTypes.app" "$destination_bundle"
      new_installed=true
      "$lsregister_command" -f "$destination_bundle"
      trap - EXIT
      rm -rf "$staged" "$previous"
      printf 'default-applications: bundle changed: %s\n' "$destination_bundle" >&2
    fi

    handler_of_uti() {
      "$duti_command" -d "$1" 2>/dev/null || true
    }

    bind() {
      local app=$1 identifier=$2 kind=$3 result status
      shift 3
      if result=$("$duti_command" -s "$app" "$identifier" "$@" 2>&1); then
        printf 'default-applications: binding changed: %s -> %s\n' "$identifier" "$app" >&2
      else
        status=$?
        if [[ $kind != scheme && $result == *'(error -50)'* ]]; then
          printf 'default-applications: skipped dynamic type (error -50): %s -> %s\n' "$identifier" "$app" >&2
        else
          printf 'default-applications: binding failed: %s -> %s (exit %s): %s\n' "$identifier" "$app" "$status" "$result" >&2
          return "$status"
        fi
      fi
    }

    mapfile -t bindings < <(jq -r '.bindings[] | [.app, (.uti // ""), (.extension // ""), (.scheme // "")] | join("\u001f")' "$declaration")
    for binding in "''${bindings[@]}"; do
      IFS=$'\x1f' read -r app uti extension scheme <<< "$binding"
      if [[ -n $scheme ]]; then
        current=$(handler_of_uti "$scheme")
        if [[ $current == "$app" ]]; then
          printf 'default-applications: binding current: %s -> %s\n' "$scheme" "$app" >&2
        else
          bind "$app" "$scheme" scheme
        fi
      elif [[ -n $extension ]]; then
        current=$("$duti_command" -x "$extension" 2>/dev/null | tail -n 1 || true)
        if [[ -z $current ]]; then
          current=$(handler_of_uti "$uti")
        fi
        if [[ $current == "$app" ]]; then
          printf 'default-applications: binding current: %s -> %s\n' "$extension" "$app" >&2
        else
          bind "$app" "$uti" uti all
          bind "$app" "$extension" extension all
        fi
      else
        current=$(handler_of_uti "$uti")
        if [[ $current == "$app" ]]; then
          printf 'default-applications: binding current: %s -> %s\n' "$uti" "$app" >&2
        else
          bind "$app" "$uti" uti all
        fi
      fi
    done
  '';

  meta = {
    description = "Apply changed LaunchServices bundle and handler declarations";
    mainProgram = "default-applications";
    platforms = lib.platforms.darwin;
  };
}
