{
  runCommandLocal,
  src,
}:

# The macOS keyboard layout bundle shipped by the Neo project
# (`mac_osx/neo-layouts.bundle`): an Apple "Localized XML Keyboard Bundle"
# carrying the Neo 2, NeoQwertz and Bone layouts.
#
# This only lifts the bundle out of the Neo source tree. Installing it is a
# separate step, because macOS will not load a keyboard layout through a symlink
# into the Nix store -- see modules/home/neo2.nix.
runCommandLocal "neo-keyboard-layouts"
  {
    inherit src;
    meta = {
      description = "Neo family keyboard layout bundle for macOS (Neo 2, NeoQwertz, Bone)";
      homepage = "https://neo-layout.org/";
    };
  }
  ''
    mkdir -p "$out"
    cp -R "$src/mac_osx/neo-layouts.bundle" "$out/"

    # `cp -R` carries the store's read-only mode across, so nothing below could
    # modify the copy.
    chmod -R u+w "$out/neo-layouts.bundle"

    resources="$out/neo-layouts.bundle/Contents/Resources"

    # Upstream ships "Deutsch (Noted)" with id="-15581", the same id as
    # "Deutsch (Neo 2)". Keyboard layout ids must be unique: with both present
    # macOS lists Neo 2 in Input Sources but refuses to enable it. Noted has no
    # KLInfo_ entry in Info.plist and no icon either, so it is not an advertised
    # layout at all -- it is an unfinished copy of Neo 2. Drop it.
    rm "$resources/Deutsch (Noted).keylayout"

    # Guard: fail the build rather than silently shipping a bundle macOS cannot
    # enable, should a future Neo revision collide again.
    ids=$(sed -n 's/.*<keyboard [^>]*id="\([-0-9]*\)".*/\1/p' "$resources"/*.keylayout | sort)
    if [ "$(printf '%s\n' "$ids" | uniq -d)" ]; then
      echo "duplicate keyboard layout ids: $(printf '%s\n' "$ids" | uniq -d | tr '\n' ' ')" >&2
      exit 1
    fi
  ''
