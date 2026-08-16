{
  fetchurl,
  lib,
  runCommandLocal,
  writeText,
}:

let
  neoKeylayout = fetchurl {
    url = "https://dl.neo-layout.org/neo.keylayout";
    hash = "sha256-ahv2ui7lSzBr+F17td+q8NHskpEIKRiD043bhknFbcA=";
  };
  neoIcon = fetchurl {
    url = "https://dl.neo-layout.org/neo.icns";
    hash = "sha256-drxmYN3S/tGxl4yJi24ua8IjZxUWkeKDp6or5F9EpEo=";
  };
  neoQwertzKeylayout = fetchurl {
    url = "https://dl.neo-layout.org/neoqwertz.keylayout";
    hash = "sha256-ZE6OyVHg/9+0DIHYCqsLM093laO7/+YgyRi0KYaIXA8=";
  };
  neoQwertzIcon = fetchurl {
    url = "https://dl.neo-layout.org/neoqwertz.icns";
    hash = "sha256-BRBT4rjetL1Me4UOJrG2LEMygWFIfZS7jTfpaNxku5Q=";
  };
  boneKeylayout = fetchurl {
    url = "https://dl.neo-layout.org/bone.keylayout";
    hash = "sha256-t6euyT1THejXNAmY0yMAMtXC5RR4S0PfCnqWZUQGS9Q=";
  };
  boneIcon = fetchurl {
    url = "https://dl.neo-layout.org/bone.icns";
    hash = "sha256-WwLE49niXBzFHzk9z9jGUoSJtv2COAnyraQ8aa9sCX0=";
  };
  infoPlist = writeText "Info.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>CFBundleIdentifier</key>
      <string>org.sil.ukelele.keyboardlayout.neo</string>
      <key>CFBundleName</key>
      <string>neo-layouts</string>
      <key>CFBundleVersion</key>
      <string>2.0</string>
      <key>KLInfo_Deutsch (Bone)</key>
      <dict>
        <key>TICapsLockLanguageSwitchCapable</key>
        <false/>
        <key>TISIconIsTemplate</key>
        <true/>
        <key>TISInputSourceID</key>
        <string>org.sil.ukelele.keyboardlayout.neo.deutsch(bone)</string>
        <key>TISIntendedLanguage</key>
        <string>de</string>
      </dict>
      <key>KLInfo_Deutsch (Neo 2)</key>
      <dict>
        <key>TICapsLockLanguageSwitchCapable</key>
        <false/>
        <key>TISIconIsTemplate</key>
        <true/>
        <key>TISInputSourceID</key>
        <string>org.sil.ukelele.keyboardlayout.neo.deutsch(neo2)</string>
        <key>TISIntendedLanguage</key>
        <string>de</string>
      </dict>
      <key>KLInfo_Deutsch (NeoQwertz)</key>
      <dict>
        <key>TICapsLockLanguageSwitchCapable</key>
        <false/>
        <key>TISIconIsTemplate</key>
        <true/>
        <key>TISInputSourceID</key>
        <string>org.sil.ukelele.keyboardlayout.neo.deutsch(neoqwertz)</string>
        <key>TISIntendedLanguage</key>
        <string>de</string>
      </dict>
    </dict>
    </plist>
  '';
in
runCommandLocal "neo-keyboard-layouts"
  {
    meta = {
      description = "Neo family keyboard layout bundle for macOS (Neo 2, NeoQwertz, Bone)";
      homepage = "https://neo-layout.org/Einrichtung/macOS/";
      license = lib.licenses.gpl3Plus;
      platforms = lib.platforms.darwin;
    };
  }
  ''
    bundle="$out/neo-layouts.bundle/Contents"
    resources="$bundle/Resources"
    mkdir -p "$resources"

    cp ${infoPlist} "$bundle/Info.plist"
    cp ${neoKeylayout} "$resources/Deutsch (Neo 2).keylayout"
    cp ${neoIcon} "$resources/Deutsch (Neo 2).icns"
    cp ${neoQwertzKeylayout} "$resources/Deutsch (NeoQwertz).keylayout"
    cp ${neoQwertzIcon} "$resources/Deutsch (NeoQwertz).icns"
    cp ${boneKeylayout} "$resources/Deutsch (Bone).keylayout"
    cp ${boneIcon} "$resources/Deutsch (Bone).icns"

    # Fail if an upstream update introduces duplicate layout identifiers.
    ids=$(sed -n 's/.*<keyboard [^>]*id="\([-0-9]*\)".*/\1/p' "$resources"/*.keylayout | sort)
    if [ "$(printf '%s\n' "$ids" | uniq -d)" ]; then
      echo "duplicate keyboard layout ids: $(printf '%s\n' "$ids" | uniq -d | tr '\n' ' ')" >&2
      exit 1
    fi
  ''
