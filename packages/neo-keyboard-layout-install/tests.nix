{
  coreutils,
  diffutils,
  gnugrep,
  neo-keyboard-layout-install,
  runCommand,
}:

runCommand "check-neo-keyboard-layout-install"
  {
    nativeBuildInputs = [
      coreutils
      diffutils
      gnugrep
    ];
  }
  ''
    set -eu
    command=${neo-keyboard-layout-install}/bin/neo-keyboard-layout-install
    source=$PWD/source.bundle
    destination=$PWD/Library/Keyboard\ Layouts/neo-layouts.bundle
    layout_dir=$(dirname "$destination")
    mkdir -p "$source/Contents/Resources"
    printf '%s\n' 'declared layout' > "$source/Contents/Resources/Neo.keylayout"
    chmod -R a-w "$source"

    "$command" "$source" "$destination" >absent.out 2>absent.err
    test ! -s absent.out
    grep -qFx "neo-keyboard-layout-install: changed: $destination" absent.err
    cmp "$source/Contents/Resources/Neo.keylayout" "$destination/Contents/Resources/Neo.keylayout"
    test -w "$destination/Contents/Resources/Neo.keylayout"

    touch -t 200001010101 "$destination/Contents/Resources/Neo.keylayout" "$destination" "$layout_dir"
    file_mtime=$(stat -c %Y "$destination/Contents/Resources/Neo.keylayout")
    bundle_mtime=$(stat -c %Y "$destination")
    directory_mtime=$(stat -c %Y "$layout_dir")
    "$command" "$source" "$destination" >current.out 2>current.err
    test ! -s current.out
    grep -qFx "neo-keyboard-layout-install: current: $destination" current.err
    test "$(stat -c %Y "$destination/Contents/Resources/Neo.keylayout")" = "$file_mtime"
    test "$(stat -c %Y "$destination")" = "$bundle_mtime"
    test "$(stat -c %Y "$layout_dir")" = "$directory_mtime"

    printf '%s\n' 'old layout' > "$destination/Contents/Resources/Neo.keylayout"
    touch -t 200001010101 "$destination/Contents/Resources/Neo.keylayout" "$destination" "$layout_dir"
    "$command" "$source" "$destination" >changed.out 2>changed.err
    test ! -s changed.out
    grep -qFx "neo-keyboard-layout-install: changed: $destination" changed.err
    cmp "$source/Contents/Resources/Neo.keylayout" "$destination/Contents/Resources/Neo.keylayout"
    test "$(stat -c %Y "$layout_dir")" != "$directory_mtime"
    test -w "$destination/Contents/Resources/Neo.keylayout"

    touch -t 200001010101 "$destination" "$layout_dir"
    bundle_mtime=$(stat -c %Y "$destination")
    directory_mtime=$(stat -c %Y "$layout_dir")
    if "$command" "$PWD/missing.bundle" "$destination" >failed.out 2>failed.err; then
      printf '%s\n' 'a failed bundle comparison unexpectedly passed' >&2
      exit 1
    else
      test "$?" -ne 0
    fi
    test ! -s failed.out
    grep -qFx "neo-keyboard-layout-install: could not compare $destination" failed.err
    cmp "$source/Contents/Resources/Neo.keylayout" "$destination/Contents/Resources/Neo.keylayout"
    test "$(stat -c %Y "$destination")" = "$bundle_mtime"
    test "$(stat -c %Y "$layout_dir")" = "$directory_mtime"

    touch "$out"
  ''
