{
  lib,
  pkgs,
  ...
}:

let
  # Terminal.app archives fonts by PostScript name, not family name.
  # `NLNFM` is the no-ligature Nerd Font cut required for terminal grids.
  fontPostScriptName = "JetBrainsMonoNLNFM-Regular";
in

{
  # Profile fonts are NSKeyedArchiver blobs, not strings; `system.defaults`
  # cannot set them.
  home.activation.appleTerminalFont = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.python3}/bin/python3 ${./apple-terminal.py} ${lib.escapeShellArg fontPostScriptName}
  '';
}
