{
  jq,
  lib,
  tailscale,
  tailscaleCommand ? lib.getExe tailscale,
  writeShellApplication,
}:

writeShellApplication {
  name = "tailnet-known-hosts";

  runtimeInputs = [ jq ];

  text = ''
    if [ "$#" -ne 1 ] || [ -z "$1" ]; then
      printf '%s\n' 'usage: tailnet-known-hosts HOST' >&2
      exit 2
    fi

    host=$1

    "${tailscaleCommand}" status --json \
      | jq --exit-status --raw-output --arg host "$host" '
          def normalized: ascii_downcase | rtrimstr(".");

          [
            .Peer[]
            | select(
                ((.HostName // "" | normalized) == ($host | normalized))
                or ((.DNSName // "" | normalized) == ($host | normalized))
              )
          ] as $matches
          | if ($matches | length) != 1 then
              error("expected exactly one tailnet peer matching " + $host)
            elif (($matches[0].sshHostKeys // []) | length) == 0 then
              error("tailnet peer has no SSH host keys: " + $host)
            else
              $matches[0].sshHostKeys[] | $host + " " + .
            end
        '
  '';
}
