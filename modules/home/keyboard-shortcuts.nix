{ lib, ... }:

let
  # Shortcuts switched off in System Settings. The ids are Apple's undocumented
  # symbolic hotkey table, so each records what it was bound to. "unassigned"
  # means it had no key, and is kept so macOS does not hand it one later.
  # Regenerate by listing the ids whose `enabled` is false in
  # `~/Library/Preferences/com.apple.symbolichotkeys.plist`.
  disabled = {
    "15" = "Opt+Cmd+8";
    "17" = "Opt+Cmd+=";
    "19" = "Opt+Cmd+-";
    "21" = "Ctrl+Opt+Cmd+8";
    "23" = "unassigned";
    "25" = "Ctrl+Opt+Cmd+.";
    "26" = "Ctrl+Opt+Cmd+,";
    "52" = "Opt+Cmd+D";
    "59" = "Cmd+F5";
    "64" = "Spotlight search window, freed for LaunchBar";
    "160" = "unassigned";
    "175" = "unassigned";
    "179" = "unassigned";
    "190" = "Q";
    "215" = "unassigned";
    "216" = "unassigned";
    "217" = "unassigned";
    "218" = "unassigned";
    "219" = "unassigned";
    "223" = "unassigned";
    "224" = "unassigned";
    "225" = "unassigned";
    "226" = "unassigned";
    "227" = "unassigned";
    "228" = "unassigned";
    "229" = "unassigned";
    "230" = "unassigned";
    "231" = "unassigned";
    "232" = "unassigned";
    "233" = "Cmd+M";
    "235" = "unassigned";
    "237" = "Ctrl+F";
    "238" = "Ctrl+C";
    "239" = "Ctrl+R";
    "240" = "Ctrl+Left";
    "241" = "Ctrl+Right";
    "242" = "Ctrl+Up";
    "243" = "Ctrl+Down";
    "244" = "unassigned";
    "245" = "unassigned";
    "246" = "unassigned";
    "247" = "unassigned";
    "248" = "Shift+Ctrl+Left";
    "249" = "Shift+Ctrl+Right";
    "250" = "Shift+Ctrl+Up";
    "251" = "Shift+Ctrl+Down";
    "256" = "unassigned";
    "257" = "unassigned";
    "258" = "unassigned";
    "260" = "Cmd+Esc";
  };
in

{
  # macOS keeps these in one nested dictionary. Round-trip the domain so the
  # entries merge, because writing the key whole, as `CustomUserPreferences`
  # does, drops every shortcut it does not mention. Only `enabled` is set, so
  # each shortcut keeps the key it was bound to. Takes effect at next login.
  home.activation.keyboardShortcuts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    hotkeys=$(/usr/bin/mktemp)
    /usr/bin/defaults export com.apple.symbolichotkeys - > "$hotkeys"
    /usr/bin/plutil -insert AppleSymbolicHotKeys -json '{}' "$hotkeys" 2>/dev/null || true
    for id in ${lib.concatStringsSep " " (builtins.attrNames disabled)}; do
      /usr/bin/plutil -insert "AppleSymbolicHotKeys.$id" -json '{}' "$hotkeys" 2>/dev/null || true
      /usr/bin/plutil -replace "AppleSymbolicHotKeys.$id.enabled" -json false "$hotkeys"
    done
    run /usr/bin/defaults import com.apple.symbolichotkeys "$hotkeys"
    /bin/rm -f "$hotkeys"
  '';
}
