{
  lib,
  writeShellApplication,
  tailscale,
  jq,
}:
writeShellApplication {
  name = "air-share-mount";
  runtimeInputs = [
    tailscale
    jq
  ];
  meta = {
    description = "Mount the temporary Air SMB share only while its peer is online";
    mainProgram = "air-share-mount";
    platforms = lib.platforms.darwin;
  };
  text = ''
    if [ "$#" -ne 3 ]; then
      printf '%s\n' 'usage: air-share-mount MOUNTED_HOME SMB_URL HOST_NAME' >&2
      exit 64
    fi
    if [ -d "$1" ]; then
      exit 0
    fi
    tailscale_command="''${AIR_SHARE_TAILSCALE:-tailscale}"
    osascript_command="''${AIR_SHARE_OSASCRIPT:-/usr/bin/osascript}"
    if ! "$tailscale_command" status --json 2>/dev/null \
      | jq --exit-status --arg host "$3" 'any(.Peer[]; .HostName == $host and .Online == true)' >/dev/null
    then
      exit 0
    fi
    "$osascript_command" -e "mount volume \"$2\""
  '';
}
