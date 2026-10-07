{
  config,
  lib,
  pkgs,
  ...
}:
let
  air = (builtins.fromTOML (builtins.readFile ../../../../home/.chezmoidata/air.toml)).air;
  mountedHome = air.home;
  log = "${config.users.users.${config.host.username}.home}/Library/Logs/mount-air-share.log";
in
{
  users.users.${config.host.username}.packages = [ pkgs.air-share-mount ];
  launchd.user.agents.mount-air-share.serviceConfig = {
    ProgramArguments = [
      (lib.getExe pkgs.air-share-mount)
      mountedHome
      "smb://${air.user}@${air.hostName}/${air.shareName}"
      air.hostName
    ];
    RunAtLoad = true;
    StartInterval = 60;
    ProcessType = "Background";
    LimitLoadToSessionType = "Aqua";
    StandardOutPath = log;
    StandardErrorPath = log;
  };
}
