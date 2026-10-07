{ config, lib, ... }:

let
  # Stencil serves the closed beta only to signed-in accounts, so neither
  # Homebrew nor Nix can fetch it. The bundle is installed by hand at its
  # declared path and updates itself there. Tern rewrites its own
  # settings.json in ~/Library/Application Support/Tern, so this module
  # declares no settings.
  tern = lib.findFirst (
    application: application.appPath != null && baseNameOf application.appPath == "Tern.app"
  ) (throw "host.darwin.applications must declare Tern.app") config.host.darwin.applications;
in
{
  # When the login shell cannot find `tern`, Tern links its CLI into the first
  # writable directory on PATH, which here is Homebrew's prefix. The bundle's
  # executable directory holds only `tern`, so putting it on PATH prevents
  # that link and keeps the CLI current across self-updates.
  home.sessionPath = [ "${tern.appPath}/Contents/MacOS" ];
}
