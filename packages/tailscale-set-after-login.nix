{
  jq,
  lib,
  tailscale,
  tailscaleCommand ? lib.getExe tailscale,
  writeShellApplication,
}:

writeShellApplication {
  name = "tailscale-set-after-login";

  runtimeInputs = [ jq ];

  text = ''
    if [ "$#" -eq 0 ]; then
      printf '%s\n' 'tailscale-set-after-login: at least one set flag is required' >&2
      exit 2
    fi

    until "${tailscaleCommand}" status --json --peers=false 2>/dev/null \
      | jq --exit-status '.BackendState == "Running"' >/dev/null
    do
      sleep 0.5
    done

    exec "${tailscaleCommand}" set "$@"
  '';
}
