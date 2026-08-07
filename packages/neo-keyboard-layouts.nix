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
  ''
