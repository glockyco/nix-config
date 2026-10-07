_:

let
  shared = import ../../shared;
in

{
  programs.zed-editor = {
    enable = true;

    # Homebrew supplies Zed; `package = null` prevents a second nixpkgs copy.
    package = null;

    # Keep `mutableUserSettings = true`: Zed merges these settings into writable
    # settings.json, preserving UI state while reapplying declared values on each switch.
    extensions = [ "latex" ];

    # The theme comes from `modules/home/darwin/catppuccin.nix`.
    userSettings = shared.zedSettings { };
  };
}
