{
  coreutils,
  diffutils,
  lib,
  writeShellApplication,
}:

writeShellApplication {
  name = "karabiner-configuration";
  meta = {
    description = "Install changed Karabiner configuration as a writable private file";
    mainProgram = "karabiner-configuration";
    platforms = lib.platforms.darwin;
  };
  runtimeInputs = [
    coreutils
    diffutils
  ];
  text = ''
    if [ "$#" -ne 2 ]; then
      printf '%s\n' 'usage: karabiner-configuration SOURCE_JSON DESTINATION_JSON' >&2
      exit 2
    fi

    source=$1
    destination=$2
    directory=$(dirname -- "$destination")

    if [ -f "$destination" ] && [ ! -L "$destination" ]; then
      if cmp -s -- "$source" "$destination"; then
        changed=0
        if [ "$(stat -c %a "$directory")" != 700 ]; then
          chmod 0700 -- "$directory"
          changed=1
        fi
        if [ "$(stat -c %a "$destination")" != 600 ]; then
          chmod 0600 -- "$destination"
          changed=1
        fi
        if [ "$changed" -eq 0 ]; then
          printf '%s\n' "karabiner-configuration: current: $destination" >&2
        else
          printf '%s\n' "karabiner-configuration: changed: $destination" >&2
        fi
        exit 0
      else
        status=$?
        if [ "$status" -ne 1 ]; then
          printf '%s\n' "karabiner-configuration: could not compare $destination" >&2
          exit "$status"
        fi
      fi
    fi

    install -d -m 0700 -- "$directory"
    if [ -L "$destination" ]; then
      rm -f -- "$destination"
    fi
    install -m 0600 -- "$source" "$destination"
    printf '%s\n' "karabiner-configuration: changed: $destination" >&2
  '';
}
