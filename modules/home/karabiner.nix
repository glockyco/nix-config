{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  # The upstream Neo2 rule collection that https://neo-layout.org/Einrichtung/macOS/
  # tells you to import by hand from ke-complex-modifications.pqrs.org.
  neo2Source = "${inputs.karabiner-complex-modifications}/public/json/neo2.json";
  neo2 = builtins.fromJSON (builtins.readFile neo2Source);

  # Rules to enable, by their upstream `description`, in evaluation order. Any
  # other rule from neo2Source can be added by pasting its description here.
  #
  # The Neo documentation still lists four rules, but upstream has since merged
  # "Neo2 mod 3 and 4 keys" and "Neo2 layer 4" into the single combined rule
  # below, so these three are the current equivalent of that list.
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
  # Karabiner-Elements itself is installed as a Homebrew cask; see
  # modules/darwin/homebrew.nix.
  #
  # karabiner.json has to be a real, writable file. Karabiner rewrites it in
  # place (temporary file plus rename()) whenever it saves, and chmods the whole
  # directory to 0700 -- which destroys a store symlink and fails outright
  # against a read-only store path. So it is copied out of the store, not linked.
  #
  # The trade-off is explicit: this file is generated, so changes made in the
  # Karabiner UI are reverted on the next `darwin-rebuild switch`. Edit
  # `enabledRules` above instead. Karabiner watches the directory and reloads on
  # its own, so no restart is needed after a switch.
  home.activation.karabinerConfiguration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.coreutils}/bin/install -d -m 0700 $VERBOSE_ARG ${lib.escapeShellArg karabinerDir}
    run ${pkgs.coreutils}/bin/install -m 0600 $VERBOSE_ARG ${karabinerJson} ${lib.escapeShellArg "${karabinerDir}/karabiner.json"}
  '';
}
