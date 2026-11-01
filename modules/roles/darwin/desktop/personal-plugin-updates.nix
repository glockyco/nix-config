{ config, pkgs, ... }:
let
  home = config.users.users.${config.host.username}.home;
  log = "${home}/Library/Logs/personal-plugin-upgrade.log";
  runner = pkgs.writeShellScript "personal-plugin-upgrade" ''
    set -eu
    export HOME=${pkgs.lib.escapeShellArg home}
    export PATH="$HOME/.local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') personal plugin update starting"
    finish() {
      result=$?
      echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') personal plugin update finished: $result"
    }
    trap finish EXIT
    "$HOME/.local/bin/omp" plugin marketplace update glockyco
    "$HOME/.local/bin/omp" plugin upgrade --scope user personal@glockyco
  '';
in
{
  launchd.user.agents.personal-plugin-upgrade.serviceConfig = {
    ProgramArguments = [ "${runner}" ];
    RunAtLoad = true;
    StartInterval = 3600;
    ProcessType = "Background";
    LimitLoadToSessionType = "Aqua";
    StandardOutPath = log;
    StandardErrorPath = log;
  };
}
