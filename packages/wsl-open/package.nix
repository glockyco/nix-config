{
  lib,
  writeShellApplication,
}:

writeShellApplication {
  name = "open";

  text = ''
    if (( $# > 1 )); then
      printf '%s\n' 'open: expected zero or one target' >&2
      exit 64
    fi

    target="''${1:-.}"

    if [[ -e "$target" ]]; then
      wslpath_executable="$(command -v wslpath || true)"
      if [[ -z "$wslpath_executable" || ! -x "$wslpath_executable" ]]; then
        printf '%s\n' 'open: WSL path translation is unavailable (wslpath not found)' >&2
        exit 69
      fi

      if ! windows_target="$("$wslpath_executable" -aw -- "$target")"; then
        printf 'open: could not translate WSL path: %s\n' "$target" >&2
        exit 69
      fi
      dispatcher=explorer.exe
      dispatch_arguments=("$windows_target")
    elif [[ "$target" =~ ^[A-Za-z][A-Za-z0-9+.-]*: ]]; then
      # Explorer opens Documents instead of the handler for any URI with a
      # query string, so URIs go to the shell's URL protocol handler.
      dispatcher=rundll32.exe
      dispatch_arguments=('url.dll,FileProtocolHandler' "$target")
    else
      printf 'open: target does not exist and is not an absolute URI: %s\n' "$target" >&2
      exit 66
    fi

    dispatcher_executable="$(command -v "$dispatcher" || true)"
    if [[ -z "$dispatcher_executable" || ! -x "$dispatcher_executable" ]]; then
      printf 'open: Windows executable interoperation is unavailable (%s not found)\n' "$dispatcher" >&2
      exit 69
    fi

    # Neither dispatcher has a documented success exit code; both hand the
    # request to the Windows shell. Preserve only shell-level execution failures.
    set +o errexit
    "$dispatcher_executable" "''${dispatch_arguments[@]}"
    status=$?
    set -o errexit
    if (( status == 126 || status == 127 )); then
      exit "$status"
    fi
  '';

  meta = {
    description = "Open a WSL path or URI with the Windows desktop";
    mainProgram = "open";
    platforms = lib.platforms.linux;
  };
}
