{
  coreutils,
  diffutils,
  gnugrep,
  karabiner-configuration,
  runCommand,
}:

runCommand "check-karabiner-configuration"
  {
    nativeBuildInputs = [
      coreutils
      diffutils
      gnugrep
    ];
  }
  ''
    set -eu
    command=${karabiner-configuration}/bin/karabiner-configuration
    source=$PWD/generated.json
    destination=$PWD/.config/karabiner/karabiner.json
    directory=$(dirname "$destination")
    printf '%s\n' '{"profiles":["Neo2"]}' > "$source"

    "$command" "$source" "$destination" >absent.out 2>absent.err
    test ! -s absent.out
    grep -qFx "karabiner-configuration: changed: $destination" absent.err
    cmp "$source" "$destination"
    test "$(stat -c %a "$directory")" = 700
    test "$(stat -c %a "$destination")" = 600

    touch -t 200001010101 "$destination" "$directory"
    file_mtime=$(stat -c %Y "$destination")
    directory_mtime=$(stat -c %Y "$directory")
    "$command" "$source" "$destination" >current.out 2>current.err
    test ! -s current.out
    grep -qFx "karabiner-configuration: current: $destination" current.err
    test "$(stat -c %Y "$destination")" = "$file_mtime"
    test "$(stat -c %Y "$directory")" = "$directory_mtime"
    test "$(stat -c %a "$destination")" = 600

    chmod 0755 "$directory"
    chmod 0644 "$destination"
    "$command" "$source" "$destination" >mode.out 2>mode.err
    test ! -s mode.out
    grep -qFx "karabiner-configuration: changed: $destination" mode.err
    test "$(stat -c %a "$directory")" = 700
    test "$(stat -c %a "$destination")" = 600
    test "$(stat -c %Y "$destination")" = "$file_mtime"
    test "$(stat -c %Y "$directory")" = "$directory_mtime"

    printf '%s\n' '{"profiles":["old"]}' > "$destination"
    touch -t 200001010101 "$destination"
    "$command" "$source" "$destination" >changed.out 2>changed.err
    test ! -s changed.out
    grep -qFx "karabiner-configuration: changed: $destination" changed.err
    cmp "$source" "$destination"
    test "$(stat -c %Y "$destination")" != "$file_mtime"
    test "$(stat -c %a "$directory")" = 700
    test "$(stat -c %a "$destination")" = 600

    rm "$destination"
    ln -s "$source" "$destination"
    "$command" "$source" "$destination" >linked.out 2>linked.err
    test ! -s linked.out
    grep -qFx "karabiner-configuration: changed: $destination" linked.err
    test ! -L "$destination"
    test "$(stat -c %a "$destination")" = 600
    cmp "$source" "$destination"

    touch -t 200001010101 "$destination" "$directory"
    file_mtime=$(stat -c %Y "$destination")
    directory_mtime=$(stat -c %Y "$directory")
    if "$command" "$PWD/missing.json" "$destination" >failed.out 2>failed.err; then
      printf '%s\n' 'a failed configuration comparison unexpectedly passed' >&2
      exit 1
    else
      test "$?" -ne 0
    fi
    test ! -s failed.out
    grep -qFx "karabiner-configuration: could not compare $destination" failed.err
    cmp "$source" "$destination"
    test "$(stat -c %Y "$destination")" = "$file_mtime"
    test "$(stat -c %Y "$directory")" = "$directory_mtime"

    touch "$out"
  ''
