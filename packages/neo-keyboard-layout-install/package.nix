{
  coreutils,
  diffutils,
  lib,
  writeShellApplication,
}:

writeShellApplication {
  name = "neo-keyboard-layout-install";
  meta = {
    description = "Install a writable Neo keyboard layout when its contents change";
    mainProgram = "neo-keyboard-layout-install";
    platforms = lib.platforms.darwin;
  };
  runtimeInputs = [
    coreutils
    diffutils
  ];
  text = ''
    if [ "$#" -ne 2 ]; then
      printf '%s\n' 'usage: neo-keyboard-layout-install SOURCE_BUNDLE DESTINATION_BUNDLE' >&2
      exit 2
    fi

    source=$1
    destination=$2
    layout_dir=$(dirname -- "$destination")

    if [ -d "$destination" ] && [ ! -L "$destination" ]; then
      if diff -rq -- "$source" "$destination" >/dev/null; then
        printf '%s\n' "neo-keyboard-layout-install: current: $destination" >&2
        exit 0
      else
        status=$?
        if [ "$status" -ne 1 ]; then
          printf '%s\n' "neo-keyboard-layout-install: could not compare $destination" >&2
          exit "$status"
        fi
      fi
    fi

    mkdir -p -- "$layout_dir"
    rm -rf -- "$destination"
    cp -R -- "$source" "$destination"
    chmod -R u+w -- "$destination"
    touch -- "$layout_dir"
    printf '%s\n' "neo-keyboard-layout-install: changed: $destination" >&2
  '';
}
