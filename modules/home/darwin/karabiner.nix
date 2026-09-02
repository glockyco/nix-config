{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # Upstream Neo2 rules from https://neo-layout.org/Einrichtung/macOS/.
  neo2Source = "${inputs.karabiner-complex-modifications}/public/json/neo2.json";
  neo2 = builtins.fromJSON (builtins.readFile neo2Source);

  # Select rules by upstream `description`, in evaluation order. Upstream merged
  # "Neo2 mod 3 and 4 keys" and "Neo2 layer 4" into one rule.
  enabledRules = [
    "Neo2 mod 3 and layer 4. Rule applied to all keyboards."
    "Neo2 layer 6"
    "Toggle caps_lock by pressing left_shift + right_shift at the same time"
  ];

  ruleByDescription =
    description:
    let
      matches = builtins.filter (rule: (rule.description or null) == description) neo2.rules;
    in
    if matches == [ ] then
      throw "karabiner: no rule described as '${description}' in ${neo2Source} -- upstream renamed or removed it"
    else
      builtins.head matches;

  karabinerJson = (pkgs.formats.json { }).generate "karabiner.json" {
    global.show_in_menu_bar = true;
    profiles = [
      {
        name = "Neo2";
        selected = true;
        virtual_hid_keyboard = {
          # The internal keyboard reports KeyboardLanguage "German", i.e. ISO.
          keyboard_type_v2 = "iso";
        };
        complex_modifications.rules = map ruleByDescription enabledRules;
      }
    ];
  };

  karabinerDir = "${config.home.homeDirectory}/.config/karabiner";
in

{
  # Karabiner-Elements is installed as a Homebrew cask (modules/darwin/homebrew.nix).
  # Karabiner rewrites `karabiner.json` in place and chmods the directory to 0700.
  # Copy the file instead of symlinking it; store symlinks are read-only and break on save.
  # The generated file overwrites UI changes on the next switch; edit `enabledRules`.
  home.activation.karabinerConfiguration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/install -d -m 0700 $VERBOSE_ARG ${lib.escapeShellArg karabinerDir}
    run ${pkgs.coreutils}/bin/install -m 0600 $VERBOSE_ARG ${karabinerJson} ${lib.escapeShellArg "${karabinerDir}/karabiner.json"}
  '';
}
