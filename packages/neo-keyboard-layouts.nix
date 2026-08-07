{
  runCommandLocal,
  src,
}:

# Extract `mac_osx/neo-layouts.bundle`; installation is separate because macOS
# does not load keyboard layouts through Nix-store symlinks (see `modules/home/neo2.nix`).
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

    # `cp -R` preserves the store's read-only mode; make the copy writable.
    chmod -R u+w "$out/neo-layouts.bundle"

    resources="$out/neo-layouts.bundle/Contents/Resources"

    # Upstream ships `Deutsch (Noted)` and `Deutsch (Neo 2)` with `id="-15581"`;
    # duplicate ids leave Neo 2 listed but disabled, so remove the unadvertised `Noted` copy.
    rm "$resources/Deutsch (Noted).keylayout"

    # Fail the build if a future Neo revision introduces duplicate layout ids.
    ids=$(sed -n 's/.*<keyboard [^>]*id="\([-0-9]*\)".*/\1/p' "$resources"/*.keylayout | sort)
    if [ "$(printf '%s\n' "$ids" | uniq -d)" ]; then
      echo "duplicate keyboard layout ids: $(printf '%s\n' "$ids" | uniq -d | tr '\n' ' ')" >&2
      exit 1
    fi
  ''
