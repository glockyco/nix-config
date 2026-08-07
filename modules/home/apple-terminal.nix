{
  lib,
  pkgs,
  ...
}:

let
  # PostScript name, not the family name Ghostty uses -- Terminal.app archives an
  # NSFont, which is keyed by PostScript name. `NL` is the no-ligature cut and
  # `NFM` the fixed-advance Nerd Font cut, so this is the same face as
  # modules/home/ghostty.nix asks for, in the variant a terminal grid needs.
  fontPostScriptName = "JetBrainsMonoNLNFM-Regular";
in

{
  # Terminal.app is not the daily driver -- Ghostty is -- but it is what a
  # recovery boot, a `ttys00N` login and the pre-Ghostty bootstrap give you, and
  # with SF Mono the starship prompt renders its Nerd Font glyphs as tofu.
  #
  # This cannot be `system.defaults`: Terminal.app stores each profile's font as
  # an NSKeyedArchiver blob rather than a string, so it has to be built. See the
  # script for the details and for why only the active profiles are touched.
  home.activation.appleTerminalFont = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.python3}/bin/python3 ${./apple-terminal.py} ${lib.escapeShellArg fontPostScriptName}
  '';
}
