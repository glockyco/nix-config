{
  config,
  lib,
  pkgs,
  ...
}:

let
  airHost = "macbook-air";
  airShare = "Macintosh%20HD";
  airHome = "/Volumes/Macintosh HD-1/Users/joaichberger";

  mountAir = pkgs.writeShellScript "mount-air-share" ''
    if [ -d ${lib.escapeShellArg airHome} ]; then
      exit 0
    fi

    # Avoid asking Finder to connect while the temporary peer is offline.
    if ! ${lib.getExe pkgs.tailscale} status --json 2>/dev/null \
      | ${lib.getExe pkgs.jq} --exit-status --arg host ${lib.escapeShellArg airHost} '
          any(.Peer[]; .HostName == $host and .Online == true)
        ' >/dev/null
    then
      exit 0
    fi

    /usr/bin/osascript -e ${lib.escapeShellArg ''mount volume "smb://joaichberger@${airHost}/${airShare}"''}
  '';
in
{
  # The target may be absent while the Air is offline; keeping the local path stable lets tools
  # use ~/Air without teaching each one about Finder's SMB mount layout.
  home.file.Air.source = config.lib.file.mkOutOfStoreSymlink airHome;

  launchd.agents.mount-air-share = {
    enable = true;
    config = {
      ProgramArguments = [ "${mountAir}" ];
      RunAtLoad = true;
      StartInterval = 60;
      ProcessType = "Background";
      LimitLoadToSessionType = "Aqua";
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mount-air-share.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mount-air-share.log";
    };
  };
}
