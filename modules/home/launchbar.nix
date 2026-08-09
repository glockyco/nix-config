{ lib, ... }:

{
  # LaunchBar is installed as a Homebrew cask (modules/darwin/homebrew.nix).
  # Free Cmd+Space for it by disabling hotkey 64, Spotlight's search window.
  # The domain is round-tripped so the entry merges: writing the key whole,
  # as `CustomUserPreferences` does, drops every other shortcut in it.
  # Takes effect at the next login.
  home.activation.spotlightHotkey = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    hotkeys=$(/usr/bin/mktemp)
    /usr/bin/defaults export com.apple.symbolichotkeys - > "$hotkeys"
    /usr/bin/plutil -insert AppleSymbolicHotKeys -json '{}' "$hotkeys" 2>/dev/null || true
    /usr/bin/plutil -replace AppleSymbolicHotKeys.64 -json '{"enabled":false}' "$hotkeys"
    run /usr/bin/defaults import com.apple.symbolichotkeys "$hotkeys"
    /bin/rm -f "$hotkeys"
  '';
}
