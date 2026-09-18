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
    elif [[ "$target" =~ ^[A-Za-z][A-Za-z0-9+.-]*: ]]; then
      windows_target="$target"
    else
      printf 'open: target does not exist and is not an absolute URI: %s\n' "$target" >&2
      exit 66
    fi

    explorer_executable="$(command -v explorer.exe || true)"
    if [[ -z "$explorer_executable" || ! -x "$explorer_executable" ]]; then
      printf '%s\n' 'open: Windows executable interoperation is unavailable (explorer.exe not found)' >&2
      exit 69
    fi

    exec "$explorer_executable" "$windows_target"
  '';

  meta = {
    description = "Open a WSL path or URI with the Windows desktop";
    mainProgram = "open";
    platforms = lib.platforms.linux;
  };
}
